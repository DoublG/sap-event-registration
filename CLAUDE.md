# CLAUDE.md

Guidance for Claude Code (and other agents) working in this repository. Keep it current: when you
change something it describes, update it in the same change.

## What this is

A feasibility study: the data model of the Django site
[coderdojo-event-registration](https://github.com/DoublG/coderdojo-event-registration) mapped to the
SAP Cloud Application Programming Model (CAP 9, Node.js). `MAPPING.md` holds the findings: concept
by concept, the effort, and what isn't done. Where this repo copies a rule from the Django site, it
names the Django file (`events/registrations.py`, `dojos.access`, …), so the two can be compared.

## Layout

| Path | What |
|---|---|
| `db/*.cds` | The domain model, one file per Django app. `common.cds` holds the shared types, enums and aspects; `personal-data.cds` the `@PersonalData` (GDPR) annotations |
| `db/data/*.csv` | Seed data, deployed to SQLite on every start (`;`-separated) |
| `srv/*.cds` | Four services: `/public` (anyone, read-only), `/family` (role `family`), `/dojo-admin` (role `dojo-team`, scoped to the account's active champion/mentor memberships), `/manage` (roles `organisation-admin`, `reviewer`) |
| `srv/family-service.js` | `signUp` / `cancel`: the port of Django's `events/registrations.py` |
| `app/<name>/` | **Management UIs: SAP Fiori elements** (List Report / Object Page). `annotations.cds` holds the UI annotations, `webapp/` the app descriptor (`manifest.json`, `Component.js`), `ui5.yaml` the UI5 tooling config |
| `app/services.cds` | Pulls in every Fiori app's `annotations.cds` |
| `app/site/` | **The families' site: Vue 3 + SAP UI5 Web Components** (Vite). It has its own `package.json`, installed by the root `postinstall` |
| `_i18n/` | Labels for the annotations (`{i18n>Key}`), in en / nl / fr. CAP resolves them per request from `Accept-Language` |
| `test/` | `cds.test` tests (Node's test runner, SQLite in memory) |

## Commands

```sh
npm install            # also installs app/site
npm test               # the CAP tests
npm run watch          # cds watch: http://localhost:4004 (app/index.html links every UI)
npm run dev:site       # Vue dev server, http://localhost:5173 (proxies /public and /family to :4004)
npm run build:site     # builds app/site/dist, which CAP then serves at /site/dist/index.html
```

Development logins are CAP's mocked users (`package.json`, `cds.requires.auth`), with no password:
- `parent` and `other-parent` (role `family`);
- `champion` (role `dojo-team`);
- `orgadmin` (role `organisation-admin`);
- `reviewer`.

Each user's `attr.account` is the `Accounts` ID the restrictions use (`$user.account`). Production
(`[production]`) points at SAP HANA Cloud and XSUAA; nothing is deployed.

## Conventions

- **Management UI = Fiori elements, the user side = Vue with UI5 Web Components.** Don't write
  freestyle UI5 for the management side, and don't put Fiori elements in front of families.
- **A new management screen** is an app folder under `app/` (copy one of the three), an
  `annotations.cds` added to `app/services.cds`, its labels in `_i18n/*.properties`, and a link in
  `app/index.html`. Fiori elements edits through drafts: add `@odata.draft.enabled` on the service
  entity it edits.
- **Access** is declared in the service (`@requires`, `@restrict … where: 'exists …'`), the way
  Django's `dojos.access` / `_get_own_ninja` decide it. A 404 rather than a 403 for someone else's
  child (`assertOwnChildren`).
- **Business rules that change several rows** (places, the waiting list) live in a service handler
  that reads under `SELECT … forUpdate()`, as `srv/family-service.js` does.
- **Texts are in three languages** (en / nl / fr; Dutch informal "je", French "vous"):
  - annotation labels go in `_i18n/`;
  - Fiori app titles go in `app/<name>/webapp/i18n/`;
  - the Vue site's texts go in `app/site/src/i18n.js`;
  - a translatable data field is `localized`.
- **No third-party CDN for families.** UI5 Web Components load SAP's 72 font from jsdelivr by
  default; `app/site` switches that off (`data-ui5-config` in `index.html`) and serves the fonts
  itself (`src/fonts.css`). A new web component import must not bring a CDN back.
  The Fiori elements apps load UI5 from `ui5.sap.com`, which is SAP's standard for the management
  side; in production the SAP Build Work Zone launchpad loads it.
- **Vue + web components:** `<ui5-*>` tags are custom elements (`isCustomElement` in
  `vite.config.js`). Each component is imported once in `src/main.js`. Events are DOM events:
  `@change`, `@input`, `@selection-change`, with `e.detail` / `e.target`.
- New entities, services and rules come with a test in `test/`.

## MCP servers (`.mcp.json`)

SAP's own MCP servers, pinned:

| Server | Package | What for |
|---|---|---|
| `cap` | `@cap-js/mcp-server` | Searches this project's CDS model (entities, services, annotations) and the CAP documentation. Use it before guessing at CDS syntax or CAP APIs |
| `fiori` | `@sap-ux/fiori-mcp-server` | Generates and changes Fiori elements apps (`generate_fiori_app_cap`, `list_functionality` → `get_functionality_details` → `execute_functionality`) and searches the Fiori docs. Generating needs `@sap/generator-fiori` installed globally |
| `ui5` | `@ui5/mcp-server` | UI5 API reference, guidelines, the UI5 linter and manifest validation, for the Fiori apps |

`@sap/mdk-mcp-server` (SAP's mobile development kit) is left out on purpose: there is no mobile app here.

Two known gaps in sandboxed environments, such as Claude Code on the web with a restricted network:
- **The `cap` server's install can fail.** It downloads `onnxruntime-node` binaries (for local search
  embeddings) during install, and a network policy can block that download.
- **`fiori`'s generator can fail.** It shells out to `yo`, which needs a writable `~/.yo-rc-global.json`.

On a developer machine all three work. The three Fiori apps here were written by hand in the
generator's layout for that reason.
