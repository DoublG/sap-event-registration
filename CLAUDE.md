# CLAUDE.md

Guidance for Claude Code (and other agents) working in this repository. Keep it current: when you
change something it describes, update it in the same change.

## What this is

A feasibility study: the data model of the Django site
[coderdojo-event-registration](https://github.com/DoublG/coderdojo-event-registration) mapped to the
SAP Cloud Application Programming Model (CAP 9, Node.js), **in TypeScript throughout**. `MAPPING.md` holds the findings: concept
by concept, the effort, and what isn't done. Where this repo copies a rule from the Django site, it
names the Django file (`events/registrations.py`, `dojos.access`, …), so the two can be compared.

## Layout

| Path | What |
|---|---|
| `db/*.cds` | The domain model, one file per Django app. `common.cds` holds the shared types, enums and aspects; `personal-data.cds` the `@PersonalData` (GDPR) annotations |
| `db/data/*.csv` | Seed data, deployed to SQLite on every start (`;`-separated) |
| `srv/*.cds` | Four services: `/public` (anyone, read-only), `/family` (role `family`), `/dojo-admin` (role `dojo-team`, scoped to the account's active champion/mentor memberships), `/manage` (roles `organisation-admin`, `reviewer`) |
| `srv/family-service.ts` | `signUp` / `cancel`: the port of Django's `events/registrations.py` |
| `@cds-models/` | **Generated, gitignored**: TypeScript types for every entity, action and event (`cds-typer`, `npm run typer`; `npm test` and `npm run typecheck` regenerate them first). Imported as `#cds-models/<namespace or service>` |
| `xs-security.json` | XSUAA roles and the `account` attribute, generated from the model's `@requires`/`@restrict` (`cds add xsuaa`); what production's login service needs |
| `app/<name>/` | **Management UIs: SAP Fiori elements** (List Report / Object Page). `annotations.cds` holds the UI annotations; `webapp/` the app descriptor (`manifest.json`) and `Component.ts`; `ui5.yaml` the UI5 tooling config (TypeScript transpile, mount path); its own `package.json` and `tsconfig.json` (`@sapui5/types`) |
| `app/services.cds` | Pulls in every Fiori app's `annotations.cds` |
| `app/site/` | **The families' site: Vue 3 + SAP UI5 Web Components** (Vite, `<script setup lang="ts">`) |
| `_i18n/` | Labels for the annotations (`{i18n>Key}`), in en / nl / fr. CAP resolves them per request from `Accept-Language` |
| `test/` | `cds.test` tests in TypeScript (Node's test runner via `tsx`, SQLite in memory) |

Every folder under `app/` is an **npm workspace** (root `package.json`), so one `npm install` installs
the CAP project and all four UIs.

## Commands

```sh
npm install            # the CAP project and every app/ workspace
npm test               # generates the types, then the CAP tests
npm run typecheck      # tsc on srv/ and test/, then each app (tsc / vue-tsc)
npm run watch          # cds-tsx watch: http://localhost:4004 (app/index.html links every UI)
npm run dev:site       # Vue dev server, http://localhost:5173 (proxies /public and /family to :4004)
npm run build:site     # vue-tsc + vite build into app/site/dist, served by CAP at /site/dist/index.html
npm run build          # production build: types, then cds build (compiles srv/*.ts into gen/srv)
```

CAP only loads `.ts` handlers when it knows it runs TypeScript: `cds-tsx` (the `watch` script) sets
that, and a plain `node` run needs `CDS_TYPESCRIPT=true` plus `--import tsx` (as the `test` script
does). `cds-plugin-ui5` (a dev dependency) mounts each Fiori app at `/<folder>/` inside `cds watch`
(`customConfiguration.cds-plugin-ui5.mountPath` in its `ui5.yaml`) and compiles its TypeScript on
the fly with `ui5-tooling-transpile`.

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
  that reads under `SELECT … forUpdate()`, as `srv/family-service.ts` does.
- **Texts are in three languages** (en / nl / fr; Dutch informal "je", French "vous"):
  - annotation labels go in `_i18n/`;
  - Fiori app titles go in `app/<name>/webapp/i18n/`;
  - the Vue site's texts go in `app/site/src/i18n.ts`;
  - a translatable data field is `localized`.
- **No third-party CDN for families.** UI5 Web Components load SAP's 72 font from jsdelivr by
  default; `app/site` switches that off (`data-ui5-config` in `index.html`) and serves the fonts
  itself (`src/fonts.css`). A new web component import must not bring a CDN back.
  The Fiori elements apps load UI5 from `ui5.sap.com`, which is SAP's standard for the management
  side; in production the SAP Build Work Zone launchpad loads it.
- **Vue + web components:** `<ui5-*>` tags are custom elements (`isCustomElement` in
  `vite.config.ts`). Each component is imported once in `src/main.ts`. Events are DOM events:
  `@change`, `@input`, `@selection-change`, with `e.detail` / `e.target`, typed as `CustomEvent<…>`
  in the component (`App.vue` has examples).
- **TypeScript everywhere, strict.** Service handlers use the generated types:
  - entities come from `#cds-models/coderdojo/<app>`;
  - service entities and actions come from `#cds-models/<Service>`;
  - register handlers on the typed action (`this.on(signUp, req => …)`), so `req.data` is typed.

  A CDS `Date` is typed as a `YYYY-MM-DD` template string, so cast a computed date to it.
  The Vue site imports the same generated types (`app/site/src/api.ts`), so renaming a field in `db/`
  or `srv/` is a type error in the front end too. The site's texts are typed: every language must
  have exactly the English keys (`MessageKey` in `i18n.ts`). A Fiori `Component.ts` is a class with a
  `@namespace` JSDoc tag, which the transpiler turns into `AppComponent.extend(...)`.
- New entities, services and rules come with a test in `test/`; run `npm run typecheck` before
  committing.

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
generator's layout for that reason. To generate a new app with the `fiori` server, pass
`enableTypeScript: true`.
