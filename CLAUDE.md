# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project State

This is a freshly scaffolded **SAP CAP (Cloud Application Programming Model)** project (Node.js runtime). The three tier directories (`app/`, `db/`, `srv/`) exist but are **empty** — no CDS models, services, or UI artifacts have been defined yet. Most work here starts by populating these tiers.

## Commands

```bash
cds watch          # primary dev loop: serves with auto-reload + in-memory SQLite, re-deploys on change
npm start          # cds-serve (production-style serve, no watch)
cds deploy         # deploy CDS model to the database
cds compile srv    # compile/validate service definitions to CSN
```

There is no test setup yet. When adding tests, the CAP convention is `cds.test` from `@sap/cds`; a single test runs via the test runner you introduce (e.g. `npx jest path/to/file.test.js` or `npx mocha`).

## Architecture

CAP enforces a layered structure by directory convention — keep code in the tier that matches its role:

- **`db/`** — domain data model. Define entities/types in `.cds` files (conventionally `db/schema.cds`). This is the source of truth; services and UI derive from it.
- **`srv/`** — service layer. `.cds` files expose entities as OData services (projections over `db/` entities); colocated `.js` files (e.g. `srv/cat-service.js`) hold custom event handlers (`srv.on`/`before`/`after`).
- **`app/`** — UI frontends (Fiori/UI5), consuming the OData services from `srv/`.

The flow is **db model → service projection → UI**. A change to a `db/` entity ripples outward; services reference db entities by name, and `cds watch` recompiles the whole graph on save.

### Stack specifics
- `@sap/cds` v9, Express v4.
- Dev/local persistence is `@cap-js/sqlite` (in-memory by default under `cds watch`). Production deployment targets a different DB (e.g. SAP HANA) via CAP profiles — no production DB is configured yet.

## SAP CAP Tooling

This environment has CAP-specific MCP tools and agents available. Prefer them for CAP-specific work:
- `search_model` / `search_docs` MCP tools for querying the CDS model and Capire docs.
- `sap-cap-capire` skills and `cap-*` subagents for CDS modeling, service handlers, and deployment.
