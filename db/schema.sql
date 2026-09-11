-- ============================================================
-- ARS Associated Realty Solutions
-- Saint Louis 8-Property Portfolio Database
-- SQLite schema
--
-- Source data:
--   * CoreLogic Property Details reports (8-Door-Flyer/Tax/*.pdf)
--   * ST. LOUIS REALTORS Listing Contracts, Form #2047 (Contracts/*.pdf)
-- ============================================================

PRAGMA foreign_keys = ON;

-- Drop in dependency order so the script is re-runnable
DROP VIEW  IF EXISTS v_portfolio_rollup;
DROP VIEW  IF EXISTS v_property_overview;
DROP TABLE IF EXISTS sale_history;
DROP TABLE IF EXISTS features;
DROP TABLE IF EXISTS valuations;
DROP TABLE IF EXISTS descriptions;
DROP TABLE IF EXISTS contracts;
DROP TABLE IF EXISTS properties;
DROP TABLE IF EXISTS owners;

-- ------------------------------------------------------------
-- Owners (sellers of record)
-- ------------------------------------------------------------
CREATE TABLE owners (
    owner_id        INTEGER PRIMARY KEY,
    name            TEXT NOT NULL,
    billing_address TEXT,
    billing_city    TEXT,
    billing_state   TEXT,
    billing_zip     TEXT
);

-- ------------------------------------------------------------
-- Properties (one row per parcel)
-- ------------------------------------------------------------
CREATE TABLE properties (
    property_id       INTEGER PRIMARY KEY,
    address           TEXT NOT NULL UNIQUE,
    city              TEXT NOT NULL DEFAULT 'Saint Louis',
    state             TEXT NOT NULL DEFAULT 'MO',
    zip               TEXT,
    county            TEXT NOT NULL DEFAULT 'St Louis County',
    owner_id          INTEGER REFERENCES owners(owner_id),
    apn               TEXT,               -- Assessor Parcel Number
    clip              TEXT,               -- CoreLogic property id
    property_type     TEXT DEFAULT 'SFR', -- Single Family Residence
    beds              INTEGER,
    full_baths        INTEGER,
    half_baths        INTEGER DEFAULT 0,
    living_sqft       INTEGER,            -- MLS/building sq ft
    lot_sqft          INTEGER,
    year_built        INTEGER,
    legal_description TEXT,
    mls_area          TEXT,
    fire_district     TEXT
);

-- ------------------------------------------------------------
-- Listing contracts (one active row per property here)
-- ------------------------------------------------------------
CREATE TABLE contracts (
    contract_id        INTEGER PRIMARY KEY,
    property_id        INTEGER NOT NULL REFERENCES properties(property_id),
    brokerage          TEXT DEFAULT 'ARS Associated Realty Solutions',
    brokerage_address  TEXT DEFAULT '119 N. Central Ave., Eureka, MO 63025',
    listing_agent      TEXT DEFAULT 'Robert Wibbenmeyer',
    agency_type        TEXT DEFAULT 'Seller''s Limited Agent (Exclusive Right to Sell)',
    form_ref           TEXT DEFAULT 'STL REALTORS Form #2047 (01/26)',
    commission_pct     REAL,              -- percent of purchase price
    commission_flat    REAL,              -- flat amount, if any
    list_price         REAL,              -- handwritten on form; confirm with owner
    effective_date     TEXT,              -- YYYY-MM-DD
    expiration_date    TEXT,              -- YYYY-MM-DD
    status             TEXT DEFAULT 'Draft/To confirm'
);

-- ------------------------------------------------------------
-- Valuations by year (tax assessment, market value, AVM)
-- ------------------------------------------------------------
CREATE TABLE valuations (
    valuation_id       INTEGER PRIMARY KEY,
    property_id        INTEGER NOT NULL REFERENCES properties(property_id),
    year               INTEGER NOT NULL,
    assessed_total     REAL,
    market_total       REAL,
    total_tax          REAL,
    realavm            REAL,              -- CoreLogic RealAVM point estimate
    realavm_low        REAL,
    realavm_high       REAL,
    UNIQUE (property_id, year)
);

-- ------------------------------------------------------------
-- Physical features (garage, porch, patio, etc.)
-- ------------------------------------------------------------
CREATE TABLE features (
    feature_id     INTEGER PRIMARY KEY,
    property_id    INTEGER NOT NULL REFERENCES properties(property_id),
    feature_type   TEXT NOT NULL,
    size_sqft      INTEGER
);

-- ------------------------------------------------------------
-- Listing descriptions (MLS, retail, investor tones)
-- ------------------------------------------------------------
CREATE TABLE descriptions (
    description_id  INTEGER PRIMARY KEY,
    property_id     INTEGER NOT NULL UNIQUE REFERENCES properties(property_id),
    mls_description TEXT NOT NULL,
    retail_description TEXT NOT NULL,
    investor_description TEXT NOT NULL
);

-- ------------------------------------------------------------
-- Sale history (public record deed transfers)
-- ------------------------------------------------------------
CREATE TABLE sale_history (
    sale_id        INTEGER PRIMARY KEY,
    property_id    INTEGER NOT NULL REFERENCES properties(property_id),
    sale_date      TEXT,                  -- YYYY-MM-DD
    sale_price     REAL,
    buyer_name     TEXT,
    seller_name    TEXT,
    deed_type      TEXT,
    is_last_sale   INTEGER DEFAULT 0      -- 1 = most recent recorded sale
);

-- ============================================================
-- Views
-- ============================================================

-- Per-property overview joining core detail + latest valuation + contract
CREATE VIEW v_property_overview AS
SELECT
    p.property_id,
    p.address,
    p.zip,
    o.name                AS owner,
    p.beds,
    p.full_baths,
    p.half_baths,
    p.living_sqft,
    p.lot_sqft,
    p.year_built,
    v.market_total        AS market_value_2025,
    v.total_tax           AS tax_2025,
    v.realavm             AS realavm,
    v.realavm_low,
    v.realavm_high,
    c.list_price,
    c.commission_pct
FROM properties p
LEFT JOIN owners     o ON o.owner_id = p.owner_id
LEFT JOIN valuations v ON v.property_id = p.property_id AND v.year = 2025
LEFT JOIN contracts  c ON c.property_id = p.property_id;

-- Portfolio-level rollup (package view)
CREATE VIEW v_portfolio_rollup AS
SELECT
    COUNT(*)                          AS num_properties,
    SUM(beds)                         AS total_beds,
    SUM(living_sqft)                  AS total_living_sqft,
    SUM(market_value_2025)            AS total_market_value_2025,
    SUM(realavm)                      AS total_realavm,
    SUM(tax_2025)                     AS total_annual_tax_2025,
    SUM(list_price)                   AS total_list_price
FROM v_property_overview;
