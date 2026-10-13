# Django → SAP CAP: how hard is the switch?

This repository maps the data model of
[coderdojo-event-registration](https://github.com/DoublG/coderdojo-event-registration) (Django 6.1,
MySQL, Celery, Channels, htmx) to the SAP Cloud Application Programming Model (CAP 9, Node.js),
and ports one piece of real business logic to see how the rest would go.

## The short answer

**The data model moves easily. The platform around it doesn't.**

- **The data model took about a day.** Every concrete Django model has a CDS entity here (`db/`, one
  file per Django app). The model compiles for SQLite and SAP HANA and deploys to 75 tables, the extra
  ones being link tables and CAP's translation tables.
- **Porting business logic works.** I ported `events/registrations.py` (sign-up, waiting list,
  cancellation and promotion, with the row lock) to `srv/family-service.js`, and it passes the same
  rules as the Django tests (`test/registration.test.js`, 13 tests). The code is about the same size as
  the Python.
- **Access control turns out shorter.** "Only your own children" and "only an active champion or mentor
  of this dojo" become one `@restrict … where: 'exists …'` line each in `srv/*.cds`. In Django they are
  helper functions (`dojos.access`, `_get_own_ninja`) called from every view.
- **The expensive part is everything that isn't data:**
  - the 220 server-rendered templates with htmx;
  - logins with two-step login, passkeys and login links;
  - GIS search;
  - the Celery mail engine;
  - live notifications over WebSockets;
  - the privacy registry and its erasure;
  - the Django admin used as the emergency tool;
  - Level27 hosting.

  CAP either has no equivalent for these, or the equivalent is a separate SAP BTP service with its own
  setup and cost.

Rough size of what would have to move: about 44,000 lines of Python outside migrations and tests,
1,294 tests, 218 URL routes, 220 templates, 65 mail templates per language, and about 2,000 translated
strings per language.

## Concept by concept

| Django (this site) | CAP | Effort |
|---|---|---|
| `models.Model`, fields, `max_length` | `entity`, `String(n)`, `Integer`, `Timestamp`, … | **Easy**, mechanical |
| Integer auto primary keys | `cuid` (UUID). Integers are possible, but UUIDs are the CAP default and suit HANA/OData | Easy; a **data migration** must remap every foreign key |
| `ForeignKey` | `Association to` (`<name>_ID` column) | Easy |
| `on_delete=CASCADE` | `Composition of many` for parent/child pairs. Elsewhere CAP creates **no database foreign keys** by default, so cascade and `SET_NULL` must be written as handlers, or turned on with `cds.features.assert_integrity` | **Medium**: every `on_delete` needs a decision |
| `on_delete=PROTECT` | `@assert.target` plus a delete handler | Medium |
| `ManyToManyField` | An explicit link entity (`DojoPathways`, `EventTeam`, `BadgeDojos`, …) | Easy, a bit more verbose |
| `choices` / `TextChoices` | `enum` on a `String` type (`db/common.cds`) | Easy. The labels, which are translated texts, move to `i18n.properties` |
| `UniqueConstraint` / `unique_together` | `@assert.unique` (also a database unique constraint) | Easy |
| `JSONField` (lists) | `array of String` | Easy |
| `JSONField` (free-form: segment rules, report config) | `LargeString`, with JSON parsed in code | Easy, but no JSON querying |
| `auto_now_add` / `auto_now` | `@cds.on.insert: $now` / `@cds.on.update: $now`, or the `managed` aspect | Easy |
| Abstract base classes | `aspect` | Easy |
| Proxy model (`BackgroundCheck`) | A projection or view (`OrganisationService.Volunteers`) | Easy |
| Custom managers and querysets (`public()`, `visible()`, `of_guardian`) | Views and projections with `where`, plus `@restrict` | Easy, often **shorter** |
| Computed per query (`with_confirmed_count`, `places_left`) | `virtual` elements filled in an `after READ` handler, or a calculated element | Medium |
| **Translations**: main language in the columns, other languages in a JSON column, languages chosen per dojo | `localized` elements produce a `<Entity>_texts` table per locale, with automatic fallback to the default text | **Medium**: a different design (below) |
| **Users** (`AbstractUser`, passwords, groups, permissions) | No user table. The identity provider (SAP Cloud Identity Services / XSUAA) owns logins; `req.user` carries roles and attributes | **Hard**: a redesign (below) |
| Two-step login, passkeys, backup codes, login links, the sign-in policy | All in the IdP (IAS supports TOTP, WebAuthn and passwordless). The app no longer implements any of it | **Hard to migrate, simpler to run**: 9 models and most of `accounts/` go away, but the flows and mails must be rebuilt in the IdP |
| Permission groups per organisation role, areas | Role collections in the IdP, `@requires` / `@restrict` per service | Medium |
| **GIS**: `PointField`, `MultiPolygonField`, `DistanceSphere` | No geometry type. Points are two decimals here; distance search needs native HANA SQL (`ST_Point`, `ST_Distance`) or a bounding box plus haversine; polygons as GeoJSON | **Hard** on SQLite, medium on HANA |
| Server-rendered templates with htmx (220 templates, 218 routes) | Nothing: CAP serves OData/REST. Public site: a separate front end (any framework). Dashboards: Fiori elements apps from annotations, or SAPUI5 | **Very hard**: the biggest cost by far |
| Django forms and their validation | `@mandatory`, `@assert.range`, `@assert.format` and `before` handlers; the form layouts become Fiori annotations or front-end code | Medium to hard |
| The Django admin (the "emergency tool" rule) | No equivalent. A Fiori elements app on an admin service gets close, but has to be built and annotated per entity | Hard |
| Celery workers and beat (mail queue, nightly engagement rebuild, retention) | The CAP outbox (`cds.queued`) or `@cap-js/event-queue`, plus the SAP BTP Job Scheduling service for schedules | Medium to hard |
| The mail engine (templates per language, consent, bounces, IMAP) | The entities map 1:1 (`db/mailing.cds`). Sending goes through a BTP destination or a mail API; there is no IMAP bounce reader, so that's custom code | Hard |
| Live notifications (Channels, Redis, htmx WebSocket swaps) | `@cap-js-community/websocket` or SAP Event Mesh, plus a front end that listens | Medium to hard |
| Redis cache (`core/caching.py`) | No built-in cache; HANA is usually fast enough, or Redis on BTP | Medium |
| **Privacy registry** (every field classified; drives export, erasure, retention, audit masking) | `@PersonalData` annotations (`db/personal-data.cds`, core entities done). The **SAP Personal Data Manager** gives data-subject export; erasure and retention logic stays custom | **Hard**: about 60 models' declarations to translate, and the erasure engine to rewrite |
| Audit log (django-auditlog, reads of sensitive data) | `@cap-js/audit-logging` reads `@PersonalData` and logs changes and sensitive reads automatically, to the SAP Audit Log service | **Easier than Django**: it fits CAP very well |
| Uploads (resize, strip EXIF), private documents | `@cap-js/attachments` (object store, malware scan); resizing and EXIF stripping stay custom | Medium |
| gettext catalogs (about 2,000 strings), `{% translate %}` | `i18n/i18n_<lang>.properties` for labels and messages; the UI texts move with the front end | Medium (mechanical, but large) |
| The organisation's reports (Perspective over Python datasets) | Aggregating CDS views with `@Analytics`, read by SAP Analytics Cloud or an analytical list page | Medium |
| The API (OAuth client credentials via django-oauth-toolkit) | Native: XSUAA/IAS issues the client credentials, and every CAP service is already an API | **Easier** |
| Tests (`TestCase`, 1,294 tests) | `cds.test` with SQLite in memory (as in `test/`) | Medium: every test is rewritten in JavaScript |
| Level27 (gunicorn, MySQL, Redis) | SAP BTP Cloud Foundry or Kyma, SAP HANA Cloud, XSUAA/IAS, Audit Log, Job Scheduling | **Hard**: a different platform with a different cost model (HANA Cloud has a significant minimum cost) |

## The three real design changes

### 1. Logins leave the app

In Django, `accounts.User` holds everything: the password, the login method, two-step devices, the
sign-in policy and the person's profile. CAP assumes an external identity provider. Here,
`Accounts` keeps only the profile and the background check, and is linked to the IdP user through
`loginName`. The services then read `$user.account` (a user attribute the IdP sends, mocked in
`package.json`).

What that costs:
- the login flows, security mails and guardian-controlled child logins (`accounts/child_accounts.py`)
  have to be rebuilt as IdP configuration plus the IdP's APIs;
- a ninja's own login becomes an IdP user created by the app on the guardian's behalf.

What it gains:
- about 9 models and a large, security-critical part of the code (two-step login, passkeys, login
  links, re-authentication) stop being this app's responsibility.

### 2. Translations: per locale, not per dojo

Django keeps a dojo's main-language text in the normal column and the other languages in a JSON
column, and *each dojo chooses its languages* (`Dojo.languages`).

CAP's `localized` gives every translatable element a `_texts` table keyed by locale, and serves the
user's locale with a fallback to the default. `test/registration.test.js` shows a Dutch tagline served
on `Accept-Language: nl`.

Two consequences:
- **The "this dojo only writes French" rule has no place in CAP's model.** It stays as
  `Dojos.languages`, checked in code.
- **The fallback works differently.** CAP falls back to the *default* column, whereas Django falls back
  to the dojo's *main language*. So the default column has to hold the main language, which Django
  already does.

Migrating the data means unpacking each JSON `translations` value into `_texts` rows.

### 3. No pages: the UI is a separate project

Django renders every page itself, and most of the repository's behaviour lives in views and templates
(htmx partials, forms, the management shell, accessibility work, the help-centre links). CAP stops at
the service layer. Two options:

- **Fiori elements**, generated from annotations. A good fit for the organisation dashboard and the
  dojo admin area: lists, object pages and actions. It doesn't fit the public site or the family pages,
  which need their own look.
- **A separate front end** (React, Vue, SvelteKit or plain HTML) on the OData/REST services. This
  covers everything, but it means rewriting all 220 templates and their CSS and JavaScript, and
  re-checking WCAG 2.2 AA.

## Rough effort

These are estimates for one developer who knows both stacks, assuming feature parity with today's
site. The UI rows dominate whichever way they go.

| Area | Estimate |
|---|---|
| Data model (this repository: done, minus the remaining `@PersonalData` declarations) | 1–2 weeks to finish |
| Services and access rules (`dojos.access`, organisation areas) | 2–3 weeks |
| Business logic (team rules, applications and background checks, awards, guardians, campaigns and segments, engagement) | 8–12 weeks |
| Logins on the IdP (child logins, two-step, passkeys, sign-in policy) | 3–5 weeks |
| Mail engine, outbox, schedules, bounces | 3–4 weeks |
| Privacy: export, erasure, retention, audit logging | 3–4 weeks |
| GIS search on HANA | 1 week |
| Dashboards as Fiori elements apps | 6–10 weeks |
| Public site and family pages as a new front end, accessible, in 3 languages | 10–16 weeks |
| Tests (1,294 to rewrite or replace) | spread over the above, roughly +30% |
| Data migration (integer ids to UUIDs, translations JSON to `_texts`, files) | 1–2 weeks |
| BTP setup (HANA Cloud, IAS/XSUAA, Audit Log, Job Scheduling, CI/CD) | 2–3 weeks |
| **Total** | **roughly 9–14 months** |

## What isn't done here

- `@PersonalData` is declared for the core entities only, not the full registry.
- Only `signUp` and `cancel` are ported. No other business rules are.
- There is no UI and no Fiori annotations.
- `on_delete` behaviour isn't enforced beyond compositions; the mapping above says what each case needs.
- GIS stays as plain decimals: there is no distance search yet.
