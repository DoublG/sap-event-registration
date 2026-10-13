# sap-event-registration

A feasibility study: the data model of
[coderdojo-event-registration](https://github.com/DoublG/coderdojo-event-registration) (Django)
mapped to the **SAP Cloud Application Programming Model** (CAP 9, Node.js), to see how hard it
would be to switch frameworks. **The findings are in [MAPPING.md](MAPPING.md).**

## What's here

| Path | What |
|---|---|
| `db/*.cds` | The domain model, one file per Django app (`accounts.cds`, `dojos.cds`, `events.cds`, …); `common.cds` holds the shared types, enums and aspects; `personal-data.cds` the GDPR annotations |
| `db/data/*.csv` | A little seed data (one dojo, two families, three sessions) |
| `srv/public-service.cds` | Public, read-only: dojos, sessions, pathways, content |
| `srv/family-service.cds/.js` | A family's children and places, plus `signUp` / `cancel` (the port of `events/registrations.py`) |
| `srv/dojo-admin-service.cds` | A dojo's team: only an active champion or mentor of that dojo |
| `srv/organisation-service.cds` | The organisation dashboard: admin and reviewer roles |
| `test/` | `cds.test` tests for the services and the waiting-list rules |

## Running it

Needs Node.js 20 or later.

```sh
npm install
npm test          # 13 tests, SQLite in memory
npm run watch     # http://localhost:4004, mocked logins: parent, champion, orgadmin, reviewer (no password)
```

Production settings (`[production]` in `package.json`) point at SAP HANA Cloud and XSUAA; nothing
is deployed.
