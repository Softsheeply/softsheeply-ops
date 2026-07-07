# FTC RN Scraper

Crawls the FTC's RN Database search results
(`https://www.ftc.gov/rn-database/search`), 100 records per page, and for
every record found fetches its full details (address, company name, etc.)
via the same AJAX request the site's own "RN Details" popup uses. Results
are stored in a local SQLite database (`ftc_rn.db`).

## Why not just guess RN numbers 1, 2, 3...?

The public "RN No." shown on the site (e.g. `127880`) is **not** the ID
used in the site's URLs. Each record has a separate internal ID (e.g.
`104349`) that has no predictable relationship to the RN number. There's
also no way to fetch `ftc.gov/rn/[number]` as a plain page and get the
full record - clicking an RN number in the site's UI triggers a specific
AJAX `POST` request (Drupal's modal/dialog system) that returns the
details as JSON. This scraper replicates that exact request.

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

## How it works

1. Fetches `https://www.ftc.gov/rn-database/search?search=&page=N` (100
   records per page) and parses each row for its RN number, internal ID,
   and legal business name.
2. For every row, sends the same AJAX request the site's own UI sends
   when you click an RN number, to `https://www.ftc.gov/rn/[internal_id]`,
   and parses the returned "RN Details" HTML for the full record: company
   name, legal business name, company type, business type, product line,
   material, street address, mailing address, and URL.
3. Stores each record in `ftc_rn.db`.
4. Moves to the next page once every row on the current page has been
   processed.

## Behavior

- Requests (both listing pages and detail lookups) are throttled to
  roughly 1 every 3-5 seconds (randomized).
- If a response looks blocked/rate-limited (HTTP 403/429/503 or
  captcha/"access denied"-style pages), the script pauses for 10 minutes
  and retries.
- Network errors are treated the same way: pause 10 minutes, then retry.
- Progress is logged to the console for every page and every record
  processed.
- On restart, the script resumes from the last fully-completed search
  results page (tracked in the `scrape_progress` table), so it picks up
  where it left off without re-scraping everything from the start.

## Database schema

Table `rn_records` in `ftc_rn.db` (one row per RN record):

| column                  | type    | notes                                |
|-------------------------|---------|---------------------------------------|
| rn_number               | INTEGER | primary key - the public "RN No."     |
| internal_id             | INTEGER | the site's internal ID (used in URLs) |
| legal_business_name     | TEXT    |                                        |
| company_name            | TEXT    |                                        |
| company_type            | TEXT    | e.g. CORPORATION, LLC / LLP            |
| business_type           | TEXT    | comma-separated if multiple            |
| product_line            | TEXT    | comma-separated if multiple            |
| material                | TEXT    |                                        |
| address                 | TEXT    | combined street address                |
| street_address_line1/2  | TEXT    |                                        |
| city / state / zip      | TEXT    | street address city/state/zip          |
| mailing_address_line1/2 | TEXT    |                                        |
| mailing_city/state/zip  | TEXT    |                                        |
| mailing_country         | TEXT    |                                        |
| url                     | TEXT    | company URL, if listed                 |
| status                  | TEXT    | `found` or `no_details`                |
| scraped_at              | TEXT    | ISO timestamp of the request           |

Table `scrape_progress` tracks resume state (`last_completed_page`).

## Note on an earlier (removed) approach

An earlier version of this script guessed sequential RN numbers against
`ftc.gov/rn/[number]` directly, starting at 10000. That approach never
found any real records - the URL scheme doesn't work that way (see
above). It's been fully replaced by the page-crawling approach described
here. If you have an old `ftc_rn.db` from that version, delete it before
running this version - the schema is different and the old data was
never valid.
