# FTC RN Scraper

Scrapes `https://www.ftc.gov/rn/[NUMBER]` one RN number at a time, starting
at `10000` and counting up, and stores the results in a local SQLite
database (`ftc_rn.db`).

## Setup

```bash
npm install
```

## Run

```bash
npm start
```

The script runs continuously until stopped with `Ctrl+C` (handled
gracefully - the DB is closed cleanly).

## Behavior

- Requests are throttled to roughly 1 every 3-5 seconds (randomized).
- If an RN number returns no record, it's logged and stored with
  `status = 'not_found'`, then the script moves on.
- If a response looks blocked/rate-limited (HTTP 403/429/503 or
  captcha/"access denied"-style pages), the script pauses for 10 minutes
  and retries the *same* RN number.
- Network errors are treated the same way: pause 10 minutes, then retry.
- Progress is logged to the console for every RN number processed.
- On restart, the script resumes from `MAX(rn_number) + 1` in the
  database, so it picks up where it left off.

## Database schema

Table `rn_records` in `ftc_rn.db`:

| column        | type    | notes                              |
|----------------|---------|------------------------------------|
| rn_number      | INTEGER | primary key                        |
| company_name   | TEXT    | null if not found                  |
| business_name  | TEXT    | null if not found                  |
| address        | TEXT    | null if not found                  |
| status         | TEXT    | `found` or `not_found`             |
| scraped_at     | TEXT    | ISO timestamp of the request       |

## Note on page parsing

This sandbox can't reach `www.ftc.gov` (it's not on the network
allowlist), so the field-extraction logic in `extractFields()` /
`parseRecord()` in `scraper.js` was written generically against common
HTML patterns (tables, `<dl>` definition lists, and "Label: Value" text
lines) rather than verified against the live page. If the live RN page
uses a different layout, adjust `extractFields()` / `findField()` in
`scraper.js` accordingly - run it for a handful of known RN numbers and
check the `rn_records` table to confirm the right values are being
captured.
