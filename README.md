# ARS St. Louis Portfolio

Local database and web frontend for the 8-property Saint Louis investment package
(Riverview Gardens, MO 63137), listed by ARS Associated Realty Solutions.

## Contents

```
db/
  schema.sql   SQLite schema (tables + views)
  seed.sql     Seed data for all 8 properties
  ars.db       The built database
web/
  server.js    Dependency-free Node server (built-in http; reads DB via sqlite3 CLI)
  public/      Frontend (index.html, styles.css, app.js, assets/ars-logo.png)
```

## Requirements

- Node.js (any recent version — no npm install needed)
- `sqlite3` CLI (used by the server to read the DB and to rebuild it)

## Rebuild the database

```bash
npm run db:build
# or, in order:
sqlite3 db/ars.db < db/schema.sql \
  && sqlite3 db/ars.db < db/seed.sql \
  && sqlite3 db/ars.db < db/analysis.sql
```

## Run the frontend

```bash
npm start
# then open http://localhost:4321
```

The server opens the database **read-only**. The query box accepts a single
read-only `SELECT` / `WITH` statement only.

## Features

- ARS-branded UI (logo + black/yellow/silver palette)
- Portfolio summary cards (package view)
- Sortable, filterable property table
- Per-property detail drawer (valuation history, features, sale history)
- Listing description generator — per property (MLS / retail / investor tones)
  and a whole-package description, with copy-to-clipboard
- **Investment Analysis tab** — per-property returns (NOI, cap rate on basis and
  on value, GRM, cash flow, cash-on-cash, DSCR), a click-through pro-forma,
  portfolio KPIs, package price-discount sensitivity, and price-at-target-cap
  pricing. Assumptions live in `db/analysis.sql`.
- Ad-hoc SQL query box with example queries

## Data notes

- **List prices are not yet set.** The listing contract prices are handwritten and
  did not extract from the PDFs; `contracts.list_price` is `NULL` until confirmed.
- Source data: CoreLogic Property Details reports and STL REALTORS Form #2047
  listing contracts.
- Figures (market value, RealAVM, tax) are from public/estimated data and should be
  independently verified before use in a listing.
