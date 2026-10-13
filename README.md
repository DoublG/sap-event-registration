# sap-event-registration

A feasibility study: the data model of
[coderdojo-event-registration](https://github.com/DoublG/coderdojo-event-registration) (Django)
mapped to the **SAP Cloud Application Programming Model** (CAP 9, Node.js, TypeScript), to see how hard it
would be to switch frameworks. **The findings are in [MAPPING.md](MAPPING.md).**

## What's here

| Path | What |
|---|---|
| `db/*.cds` | The domain model, one file per Django app (`accounts.cds`, `dojos.cds`, `events.cds`, …); `common.cds` holds the shared types, enums and aspects; `personal-data.cds` the GDPR annotations |
| `db/data/*.csv` | A little seed data (one dojo, two families, three sessions) |
| `srv/public-service.cds` | Public, read-only: dojos, sessions, pathways, content |
| `srv/family-service.cds/.ts` | A family's children and places, plus `signUp` / `cancel` (the port of `events/registrations.py`) |
| `srv/dojo-admin-service.cds` | A dojo's team: only an active champion or mentor of that dojo |
| `srv/organisation-service.cds` | The organisation dashboard: admin and reviewer roles |
| `app/dojo-events/`, `app/manage-dojos/`, `app/volunteer-applications/` | **Management UIs in SAP Fiori elements**: a dojo team's sessions and sign-ups, the organisation's dojos, the reviewers' applications |
| `app/site/` | **The families' site in Vue 3 with SAP UI5 Web Components**: sessions and sign-up, the dojo finder, my family |
| `_i18n/` | The Fiori labels in English, Dutch and French |
| `.mcp.json` | SAP's MCP servers for AI assistants: CAP (`@cap-js/mcp-server`), Fiori tools, UI5 |
| `test/` | `cds.test` tests for the services and the waiting-list rules |

## Running it

Needs Node.js 20 or later.

```sh
npm install        # the CAP project and the four apps (npm workspaces)
npm test           # 13 tests, SQLite in memory
npm run typecheck  # TypeScript: services, tests, Fiori components, Vue site
npm run build:site # build the Vue site once, so CAP serves it
npm run watch      # http://localhost:4004: links to every UI
npm run dev:site   # or: the Vue site with hot reload on http://localhost:5173
```

Mocked logins have no password:
- `parent` and `other-parent` (the family site);
- `champion` (*My dojo's sessions*);
- `orgadmin` (*Dojos*);
- `reviewer` (*Volunteer applications*).

The Fiori apps load SAPUI5 from `ui5.sap.com`.

Production settings (`[production]` in `package.json`) point at SAP HANA Cloud and XSUAA; nothing
is deployed.
