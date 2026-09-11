// ============================================================
// Shared read-only database helper.
// Loads db/ars.db into an in-memory SQLite via sql.js (WebAssembly),
// so it works both locally (node) and on Vercel serverless functions
// (no native sqlite3 binary required).
//
// The database is treated as read-only: only the query runner is
// exposed, and the query box guards against non-SELECT statements.
// ============================================================

const fs = require('node:fs');
const path = require('node:path');
const initSqlJs = require('sql.js');

// Resolve a file that may live relative to this module or to the repo root
// (Vercel functions sometimes resolve bundled files from process.cwd()).
function resolveFile(relFromRoot) {
  const candidates = [
    path.join(__dirname, '..', relFromRoot),
    path.join(process.cwd(), relFromRoot),
  ];
  for (const c of candidates) {
    if (fs.existsSync(c)) return c;
  }
  return candidates[0];
}

const DB_PATH = resolveFile(path.join('db', 'ars.db'));
// sql.js ships the wasm inside its package; resolve via require for portability.
const WASM_PATH = path.join(path.dirname(require.resolve('sql.js')), 'sql-wasm.wasm');

// Cache the opened DB across warm invocations.
let dbPromise = null;

async function getDb() {
  if (!dbPromise) {
    dbPromise = (async () => {
      const SQL = await initSqlJs({
        // Provide the wasm binary directly so we don't rely on network/CDN.
        wasmBinary: fs.readFileSync(WASM_PATH),
      });
      const fileBuffer = fs.readFileSync(DB_PATH);
      return new SQL.Database(fileBuffer);
    })();
  }
  return dbPromise;
}

// Run a SQL statement and return all rows as objects.
async function all(sql, params = []) {
  const db = await getDb();
  const stmt = db.prepare(sql);
  try {
    if (params.length) stmt.bind(params);
    const rows = [];
    while (stmt.step()) rows.push(stmt.getAsObject());
    return rows;
  } finally {
    stmt.free();
  }
}

// Run a SQL statement and return the first row (or undefined).
async function get(sql, params = []) {
  const rows = await all(sql, params);
  return rows[0];
}

// Validate an integer id before inlining into SQL.
function sqlNum(v) {
  const n = Number(v);
  if (!Number.isInteger(n)) throw new Error('invalid numeric parameter');
  return String(n);
}

// Only allow a single read-only SELECT/WITH statement (for the query box).
function isSafeSelect(sql) {
  const trimmed = String(sql).trim().replace(/;+\s*$/, '');
  if (/;/.test(trimmed)) return false;
  if (!/^(select|with)\b/i.test(trimmed)) return false;
  if (/\b(insert|update|delete|drop|alter|create|attach|detach|replace|pragma|vacuum|reindex)\b/i.test(trimmed)) return false;
  return true;
}

module.exports = { all, get, sqlNum, isSafeSelect };
