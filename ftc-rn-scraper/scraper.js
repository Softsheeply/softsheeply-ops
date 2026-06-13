'use strict';

const path = require('path');
const axios = require('axios');
const cheerio = require('cheerio');
const Database = require('better-sqlite3');

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const START_RN = 10000;
const DB_PATH = path.join(__dirname, 'ftc_rn.db');
const MIN_DELAY_MS = 3000;
const MAX_DELAY_MS = 5000;
const BLOCK_PAUSE_MS = 10 * 60 * 1000; // 10 minutes
const REQUEST_TIMEOUT_MS = 30000;

const USER_AGENT =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
  '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

// Phrases that indicate the RN number has no record on file.
const NOT_FOUND_PATTERNS = [
  /no\s+record\s+found/i,
  /no\s+results?\s+found/i,
  /no\s+information\s+(is\s+)?available/i,
  /did\s+not\s+match\s+any/i,
  /0\s+results/i,
];

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
    company_name TEXT,
    business_name TEXT,
    address TEXT,
    status TEXT NOT NULL,
    scraped_at TEXT NOT NULL
  )
`);

const insertRecord = db.prepare(`
  INSERT OR REPLACE INTO rn_records
    (rn_number, company_name, business_name, address, status, scraped_at)
  VALUES (@rnNumber, @companyName, @businessName, @address, @status, @scrapedAt)
`);

const getLastRn = db.prepare('SELECT MAX(rn_number) AS maxRn FROM rn_records');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function randomDelay() {
  return Math.floor(Math.random() * (MAX_DELAY_MS - MIN_DELAY_MS + 1)) + MIN_DELAY_MS;
}

function getResumeRn() {
  const row = getLastRn.get();
  if (row && row.maxRn != null) {
    return row.maxRn + 1;
  }
  return START_RN;
}

function normalizeLabel(label) {
  return label
    .toLowerCase()
    .replace(/[^a-z\s]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function normalizeValue(value) {
  return value.replace(/\s+/g, ' ').trim();
}

/**
 * Builds a map of normalized label -> value by scanning common HTML
 * structures (tables, definition lists) and "Label: Value" text lines.
 * The FTC RN lookup result page isn't reachable from this sandbox, so this
 * uses a generic, layout-agnostic strategy. If the real page uses a
 * different structure, add a more specific selector-based strategy here.
 */
function extractFields($) {
  const fields = {};

  // Strategy 1: table rows where the first cell is a label and the second
  // cell is the value (e.g. <tr><th>Company Name</th><td>Acme Inc</td></tr>).
  $('table tr').each((_, tr) => {
    const cells = $(tr).find('th, td');
    if (cells.length >= 2) {
      const label = normalizeLabel($(cells[0]).text());
      const value = normalizeValue($(cells[1]).text());
      if (label && value && !fields[label]) {
        fields[label] = value;
      }
    }
  });

  // Strategy 2: definition lists (<dt>Label</dt><dd>Value</dd>).
  $('dl').each((_, dl) => {
    const dts = $(dl).find('dt');
    const dds = $(dl).find('dd');
    dts.each((i, dt) => {
      const label = normalizeLabel($(dt).text());
      const value = dds[i] ? normalizeValue($(dds[i]).text()) : '';
      if (label && value && !fields[label]) {
        fields[label] = value;
      }
    });
  });

  // Strategy 3: plain "Label: Value" text in leaf elements (elements with no
  // element children), so unrelated sibling text doesn't get concatenated.
  $('body *').each((_, el) => {
    if ($(el).children().length > 0) return;
    const text = normalizeValue($(el).text());
    const m = text.match(/^([A-Za-z][A-Za-z\s/]{1,40}?):\s*(.+)$/);
    if (m) {
      const label = normalizeLabel(m[1]);
      const value = normalizeValue(m[2]);
      if (label && value && !fields[label]) {
        fields[label] = value;
      }
    }
  });

  return fields;
}

function findField(fields, candidates) {
  for (const candidate of candidates) {
    if (fields[candidate]) return fields[candidate];
  }
  for (const key of Object.keys(fields)) {
    for (const candidate of candidates) {
      if (key.includes(candidate)) return fields[key];
    }
  }
  return null;
}

/**
 * Extracts company name, business name and address from a parsed RN page.
 */
function parseRecord($) {
  const fields = extractFields($);

  const companyName = findField(fields, ['company name', 'company']);
  const businessName = findField(fields, [
    'business name',
    'doing business as',
    'dba',
  ]);

  // Check for a single combined "address" field first (exact match only -
  // a partial match would also match "street address" below).
  let address = fields['address'] || null;
  if (!address) {
    const parts = [
      'street address',
      'street',
      'city',
      'state',
      'zip code',
      'zip',
      'postal code',
      'country',
    ]
      .map((key) => fields[key])
      .filter(Boolean);
    if (parts.length) address = parts.join(', ');
  }
  if (!address) {
    address = findField(fields, ['address']);
  }

  return { companyName, businessName, address };
}

function isBlockedResponse(status, html) {
  if (BLOCK_STATUS_CODES.has(status)) return true;
  if (!html) return false;
  return BLOCK_PATTERNS.some((pattern) => pattern.test(html));
}

function isNotFoundResponse(status, html, $) {
  if (status === 404) return true;
  if (!html) return true;
  if (NOT_FOUND_PATTERNS.some((pattern) => pattern.test(html))) return true;

  // If nothing usable was extracted, treat it as "no record".
  const { companyName, businessName, address } = parseRecord($);
  return !companyName && !businessName && !address;
}

async function fetchRn(rn) {
  return axios.get(`https://www.ftc.gov/rn/${rn}`, {
    timeout: REQUEST_TIMEOUT_MS,
    validateStatus: () => true, // handle all status codes ourselves
    headers: {
      'User-Agent': USER_AGENT,
      Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
    },
  });
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
  let rn = getResumeRn();
  console.log(`FTC RN scraper starting at RN ${rn} (DB: ${DB_PATH})`);

  while (!shuttingDown) {
    let response;
    try {
      response = await axiosWithRetryAwareGet(rn);
    } catch (err) {
      console.error(`RN ${rn}: request error (${err.message}). Pausing ${BLOCK_PAUSE_MS / 60000} min before retry...`);
      await sleep(BLOCK_PAUSE_MS);
      continue;
    }

    if (response.blocked) {
      console.warn(
        `RN ${rn}: looks blocked/rate-limited (status ${response.status}). ` +
          `Pausing ${BLOCK_PAUSE_MS / 60000} minutes before retrying...`
      );
      await sleep(BLOCK_PAUSE_MS);
      continue;
    }

    const scrapedAt = new Date().toISOString();

    if (response.notFound) {
      console.log(`RN ${rn}: no result found - skipping`);
      insertRecord.run({
        rnNumber: rn,
        companyName: null,
        businessName: null,
        address: null,
        status: 'not_found',
        scrapedAt,
      });
    } else {
      const record = response.record;
      insertRecord.run({
        rnNumber: rn,
        companyName: record.companyName,
        businessName: record.businessName,
        address: record.address,
        status: 'found',
        scrapedAt,
      });
      console.log(
        `RN ${rn}: FOUND - company="${record.companyName || ''}" ` +
          `business="${record.businessName || ''}" address="${record.address || ''}"`
      );
    }

    rn += 1;

    const delay = randomDelay();
    await sleep(delay);
  }
}

/**
 * Fetches a single RN page and classifies the response, without throwing
 * on non-2xx status codes.
 */
async function axiosWithRetryAwareGet(rn) {
  const res = await fetchRn(rn);
  const html = typeof res.data === 'string' ? res.data : '';
  const $ = cheerio.load(html || '<html></html>');

  if (isBlockedResponse(res.status, html)) {
    return { status: res.status, blocked: true };
  }

  if (isNotFoundResponse(res.status, html, $)) {
    return { status: res.status, blocked: false, notFound: true };
  }

  return { status: res.status, blocked: false, notFound: false, record: parseRecord($) };
}

main().catch((err) => {
  console.error('Fatal error:', err);
  db.close();
  process.exit(1);
});
