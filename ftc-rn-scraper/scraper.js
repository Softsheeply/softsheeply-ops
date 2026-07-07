'use strict';

const path = require('path');
const axios = require('axios');
const cheerio = require('cheerio');
const Database = require('better-sqlite3');

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const BASE_URL = 'https://www.ftc.gov';
const SEARCH_PATH = '/rn-database/search';
const DB_PATH = path.join(__dirname, 'ftc_rn.db');
const MIN_DELAY_MS = 3000;
const MAX_DELAY_MS = 5000;
const BLOCK_PAUSE_MS = 10 * 60 * 1000; // 10 minutes
const REQUEST_TIMEOUT_MS = 30000;

const USER_AGENT =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
  '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

// Phrases / status codes that indicate we've been rate limited or blocked.
const BLOCK_PATTERNS = [
  /access\s+denied/i,
  /request\s+unsuccessful/i,
  /pardon\s+our\s+interruption/i,
  /are\s+you\s+a\s+robot/i,
  /captcha/i,
  /too\s+many\s+requests/i,
  /rate\s+limit/i,
];
const BLOCK_STATUS_CODES = new Set([403, 429, 503]);

// ---------------------------------------------------------------------------
// Database setup
// ---------------------------------------------------------------------------
const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');

db.exec(`
  CREATE TABLE IF NOT EXISTS rn_records (
    rn_number INTEGER PRIMARY KEY,
    internal_id INTEGER,
    legal_business_name TEXT,
    company_name TEXT,
    company_type TEXT,
    business_type TEXT,
    product_line TEXT,
    material TEXT,
    address TEXT,
    street_address_line1 TEXT,
    street_address_line2 TEXT,
    city TEXT,
    state TEXT,
    zip TEXT,
    mailing_address_line1 TEXT,
    mailing_address_line2 TEXT,
    mailing_city TEXT,
    mailing_state TEXT,
    mailing_country TEXT,
    mailing_zip TEXT,
    url TEXT,
    status TEXT NOT NULL,
    scraped_at TEXT NOT NULL
  )
`);

db.exec(`
  CREATE TABLE IF NOT EXISTS scrape_progress (
    key TEXT PRIMARY KEY,
    value TEXT
  )
`);

const insertRecord = db.prepare(`
  INSERT OR REPLACE INTO rn_records
    (rn_number, internal_id, legal_business_name, company_name, company_type,
     business_type, product_line, material, address, street_address_line1,
     street_address_line2, city, state, zip, mailing_address_line1,
     mailing_address_line2, mailing_city, mailing_state, mailing_country,
     mailing_zip, url, status, scraped_at)
  VALUES
    (@rnNumber, @internalId, @legalBusinessName, @companyName, @companyType,
     @businessType, @productLine, @material, @address, @streetAddressLine1,
     @streetAddressLine2, @city, @state, @zip, @mailingAddressLine1,
     @mailingAddressLine2, @mailingCity, @mailingState, @mailingCountry,
     @mailingZip, @url, @status, @scrapedAt)
`);

const getProgress = db.prepare('SELECT value FROM scrape_progress WHERE key = ?');
const setProgress = db.prepare(`
  INSERT INTO scrape_progress (key, value) VALUES (@key, @value)
  ON CONFLICT(key) DO UPDATE SET value = @value
`);

function getLastCompletedPage() {
  const row = getProgress.get('last_completed_page');
  return row ? parseInt(row.value, 10) : -1;
}

function setLastCompletedPage(pageIndex) {
  setProgress.run({ key: 'last_completed_page', value: String(pageIndex) });
}

// ---------------------------------------------------------------------------
// Cookie jar (axios doesn't persist cookies between requests by itself)
// ---------------------------------------------------------------------------
const cookieJar = {};

function updateCookies(setCookieHeaders) {
  if (!setCookieHeaders) return;
  for (const line of setCookieHeaders) {
    const pair = line.split(';')[0];
    const eq = pair.indexOf('=');
    if (eq === -1) continue;
    const name = pair.slice(0, eq).trim();
    const value = pair.slice(eq + 1).trim();
    cookieJar[name] = value;
  }
}

function cookieHeader() {
  return Object.entries(cookieJar)
    .map(([k, v]) => `${k}=${v}`)
    .join('; ');
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function randomDelay() {
  return Math.floor(Math.random() * (MAX_DELAY_MS - MIN_DELAY_MS + 1)) + MIN_DELAY_MS;
}

function normalizeValue(value) {
  return (value || '').replace(/\s+/g, ' ').trim() || null;
}

function isBlockedResponse(status, text) {
  if (BLOCK_STATUS_CODES.has(status)) return true;
  if (!text) return false;
  return BLOCK_PATTERNS.some((pattern) => pattern.test(text));
}

/**
 * Pulls Drupal's ajaxPageState (theme, theme_token, libraries) out of a
 * rendered page's HTML. Needed on every "open RN Details modal" request.
 */
function extractPageState(html) {
  let json = null;

  let match = html.match(
    /<script type="application\/json" data-drupal-selector="drupal-settings-json">([\s\S]*?)<\/script>/
  );
  if (match) {
    try {
      json = JSON.parse(match[1]);
    } catch (err) {
      json = null;
    }
  }

  if (!json) {
    match = html.match(/drupalSettings\s*=\s*(\{[\s\S]*?\});/);
    if (match) {
      try {
        json = JSON.parse(match[1]);
      } catch (err) {
        json = null;
      }
    }
  }

  return json && json.ajaxPageState ? json.ajaxPageState : null;
}

/**
 * Fetches one page of search results (100 records per page).
 * Returns { status, blocked, total, rows, pageState }.
 */
async function fetchListingPage(pageIndex) {
  const url = `${BASE_URL}${SEARCH_PATH}`;
  const res = await axios.get(url, {
    params: { search: '', page: pageIndex },
    timeout: REQUEST_TIMEOUT_MS,
    validateStatus: () => true,
    headers: {
      'User-Agent': USER_AGENT,
      Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      ...(cookieHeader() ? { Cookie: cookieHeader() } : {}),
    },
  });
  updateCookies(res.headers['set-cookie']);

  const html = typeof res.data === 'string' ? res.data : '';

  if (isBlockedResponse(res.status, html)) {
    return { status: res.status, blocked: true, url: res.request?.res?.responseUrl || url };
  }

  const $ = cheerio.load(html || '<html></html>');

  let total = null;
  const displayText = $('body').text();
  const totalMatch = displayText.match(/Displaying\s+[\d,]+\s*-\s*[\d,]+\s+of\s+([\d,]+)/i);
  if (totalMatch) {
    total = parseInt(totalMatch[1].replace(/,/g, ''), 10);
  }

  const rows = [];
  $('tr').each((_, tr) => {
    const link = $(tr).find('.views-field-field-rn-no a').first();
    if (!link.length) return;
    const href = link.attr('href') || '';
    const idMatch = href.match(/\/rn\/(\d+)/);
    if (!idMatch) return;
    rows.push({
      rnNumber: parseInt(normalizeValue(link.text()), 10),
      internalId: parseInt(idMatch[1], 10),
      legalBusinessName: normalizeValue(
        $(tr).find('.views-field-field-legal-business-name a').first().text()
      ),
    });
  });

  const pageState = extractPageState(html);

  return {
    status: res.status,
    blocked: false,
    total,
    rows,
    pageState,
    url: `${url}?search=&page=${pageIndex}`,
  };
}

/**
 * Fetches the "RN Details" modal content for one record (mirrors the AJAX
 * request the site itself makes when you click an RN link).
 */
async function fetchRnDetail(internalId, pageState, refererUrl) {
  const url = `${BASE_URL}/rn/${internalId}`;

  const body = new URLSearchParams();
  body.append('js', 'true');
  body.append('dialogOptions[width]', '700');
  body.append('dialogOptions[title]', 'RN Details');
  body.append('_drupal_ajax', '1');
  body.append('ajax_page_state[theme]', pageState.theme || '');
  body.append('ajax_page_state[theme_token]', pageState.theme_token || '');
  body.append('ajax_page_state[libraries]', pageState.libraries || '');

  const res = await axios.post(url, body.toString(), {
    params: { _wrapper_format: 'drupal_modal' },
    timeout: REQUEST_TIMEOUT_MS,
    validateStatus: () => true,
    headers: {
      'User-Agent': USER_AGENT,
      Accept: 'application/json, text/javascript, */*; q=0.01',
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'X-Requested-With': 'XMLHttpRequest',
      Referer: refererUrl,
      ...(cookieHeader() ? { Cookie: cookieHeader() } : {}),
    },
  });
  updateCookies(res.headers['set-cookie']);

  const rawText = typeof res.data === 'string' ? res.data : JSON.stringify(res.data);

  if (isBlockedResponse(res.status, rawText)) {
    return { status: res.status, blocked: true };
  }

  if (res.status !== 200 || !Array.isArray(res.data)) {
    return { status: res.status, blocked: false, error: true };
  }

  const dialogCommand = res.data.find((cmd) => cmd.command === 'openDialog');
  if (!dialogCommand || !dialogCommand.data) {
    return { status: res.status, blocked: false, error: true };
  }

  return { status: res.status, blocked: false, record: parseDetailHtml(dialogCommand.data) };
}

const FIELD_SELECTORS = {
  rnNumber: '.views-field-field-rn-no .rn-value',
  legalBusinessName: '.views-field-field-legal-business-name .rn-value',
  companyName: '.views-field-field-company-name .rn-value',
  companyType: '.views-field-field-rn-company-type .rn-value',
  material: '.views-field-field-rn-material .rn-value',
  streetAddressLine1: '.views-field-field-address-line-1 .rn-value',
  streetAddressLine2: '.views-field-field-address-line-2 .rn-value',
  city: '.views-field-field-city .rn-value',
  state: '.views-field-field-rn-geography .rn-value',
  zip: '.views-field-field-zip-code .rn-value',
  mailingAddressLine1: '.views-field-field-mailing-address-line-1 .rn-value',
  mailingAddressLine2: '.views-field-field-mailing-address-line-2 .rn-value',
  mailingCity: '.views-field-field-mailing-city .rn-value',
  mailingState: '.views-field-field-mailing-geography .rn-value',
  mailingCountry: '.views-field-parent .rn-value',
  mailingZip: '.views-field-field-mailing-zip-code .rn-value',
  url: '.views-field-field-link-text .rn-value',
};

function parseDetailHtml(html) {
  const $ = cheerio.load(html);
  const record = {};

  for (const [key, selector] of Object.entries(FIELD_SELECTORS)) {
    record[key] = normalizeValue($(selector).first().text());
  }

  const businessTypeItems = $('.views-field-field-rn-business-type .rn-value li')
    .map((_, li) => normalizeValue($(li).text()))
    .get()
    .filter(Boolean);
  record.businessType = businessTypeItems.length
    ? businessTypeItems.join(', ')
    : normalizeValue($('.views-field-field-rn-business-type .rn-value').first().text());

  const productLineItems = $('.views-field-nothing-2 .term-title')
    .map((_, el) => normalizeValue($(el).text()))
    .get()
    .filter(Boolean);
  record.productLine = productLineItems.length ? productLineItems.join(', ') : null;

  record.rnNumber = record.rnNumber ? parseInt(record.rnNumber, 10) : null;

  const addressParts = [
    record.streetAddressLine1,
    record.streetAddressLine2,
    record.city,
    record.state,
    record.zip,
  ].filter(Boolean);
  record.address = addressParts.length ? addressParts.join(', ') : null;

  return record;
}

// ---------------------------------------------------------------------------
// Main loop
// ---------------------------------------------------------------------------
let shuttingDown = false;

function shutdown() {
  if (shuttingDown) return;
  shuttingDown = true;
  console.log('\nShutting down... closing database.');
  db.close();
  process.exit(0);
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

async function main() {
  let pageIndex = getLastCompletedPage() + 1;
  console.log(`FTC RN scraper starting at search results page ${pageIndex} (DB: ${DB_PATH})`);

  while (!shuttingDown) {
    let listing;
    try {
      listing = await fetchListingPage(pageIndex);
    } catch (err) {
      console.error(
        `Page ${pageIndex}: request error (${err.message}). Pausing ${BLOCK_PAUSE_MS / 60000} min before retry...`
      );
      await sleep(BLOCK_PAUSE_MS);
      continue;
    }

    if (listing.blocked) {
      console.warn(
        `Page ${pageIndex}: looks blocked/rate-limited (status ${listing.status}). ` +
          `Pausing ${BLOCK_PAUSE_MS / 60000} minutes before retrying...`
      );
      await sleep(BLOCK_PAUSE_MS);
      continue;
    }

    if (!listing.pageState) {
      console.warn(`Page ${pageIndex}: couldn't find Drupal page state tokens, retrying...`);
      await sleep(randomDelay());
      continue;
    }

    if (listing.rows.length === 0) {
      console.log(`Page ${pageIndex}: no rows found - assuming end of results. Stopping.`);
      setLastCompletedPage(pageIndex);
      break;
    }

    console.log(
      `Page ${pageIndex}: ${listing.rows.length} records` +
        (listing.total ? ` (total in DB: ${listing.total})` : '')
    );

    await sleep(randomDelay());

    for (const row of listing.rows) {
      if (shuttingDown) break;

      let detail;
      try {
        detail = await fetchRnDetail(row.internalId, listing.pageState, listing.url);
      } catch (err) {
        console.error(`RN ${row.rnNumber}: request error (${err.message}) - skipping for now`);
        await sleep(randomDelay());
        continue;
      }

      if (detail.blocked) {
        console.warn(
          `RN ${row.rnNumber}: looks blocked/rate-limited (status ${detail.status}). ` +
            `Pausing ${BLOCK_PAUSE_MS / 60000} minutes before retrying this record...`
        );
        await sleep(BLOCK_PAUSE_MS);
        continue; // note: this row is retried by re-running the page after resume
      }

      const scrapedAt = new Date().toISOString();

      if (detail.error || !detail.record) {
        console.log(`RN ${row.rnNumber}: no details returned - logging and skipping`);
        insertRecord.run({
          rnNumber: row.rnNumber,
          internalId: row.internalId,
          legalBusinessName: row.legalBusinessName,
          companyName: null,
          companyType: null,
          businessType: null,
          productLine: null,
          material: null,
          address: null,
          streetAddressLine1: null,
          streetAddressLine2: null,
          city: null,
          state: null,
          zip: null,
          mailingAddressLine1: null,
          mailingAddressLine2: null,
          mailingCity: null,
          mailingState: null,
          mailingCountry: null,
          mailingZip: null,
          url: null,
          status: 'no_details',
          scrapedAt,
        });
      } else {
        const r = detail.record;
        insertRecord.run({
          rnNumber: row.rnNumber,
          internalId: row.internalId,
          legalBusinessName: r.legalBusinessName || row.legalBusinessName,
          companyName: r.companyName,
          companyType: r.companyType,
          businessType: r.businessType,
          productLine: r.productLine,
          material: r.material,
          address: r.address,
          streetAddressLine1: r.streetAddressLine1,
          streetAddressLine2: r.streetAddressLine2,
          city: r.city,
          state: r.state,
          zip: r.zip,
          mailingAddressLine1: r.mailingAddressLine1,
          mailingAddressLine2: r.mailingAddressLine2,
          mailingCity: r.mailingCity,
          mailingState: r.mailingState,
          mailingCountry: r.mailingCountry,
          mailingZip: r.mailingZip,
          url: r.url,
          status: 'found',
          scrapedAt,
        });
        console.log(
          `RN ${row.rnNumber}: FOUND - company="${r.companyName || ''}" ` +
            `legal="${r.legalBusinessName || row.legalBusinessName || ''}" address="${r.address || ''}"`
        );
      }

      await sleep(randomDelay());
    }

    setLastCompletedPage(pageIndex);
    pageIndex += 1;
  }
}

main().catch((err) => {
  console.error('Fatal error:', err);
  db.close();
  process.exit(1);
});
