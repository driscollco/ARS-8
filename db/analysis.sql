-- ============================================================
-- ARS St. Louis Portfolio - Investment Analysis layer
--
-- Adds an assumptions table (adjustable inputs) and a view that
-- computes standard rental-investment metrics from REAL data
-- (purchase basis, taxes, value) plus EXPLICIT assumptions.
--
-- IMPORTANT - assumption sourcing:
--   * purchase_price  = last recorded sale (sale_history, REAL)
--   * annual_tax      = 2025 county total tax (valuations, REAL)
--   * current_value   = 2025 RealAVM if present else county market value (REAL/estimated)
--   * monthly_rent    = ESTIMATE. No rent roll available. Default seeded from a
--                       rent-to-value ratio (~0.85-0.95%/mo of value) typical of
--                       this lower-priced STL tier. REPLACE with real comps/rent roll.
--   * vacancy/opex %  = modeled. STL investor guidance commonly uses a 25-40%
--                       operating-expense ratio and meaningful vacancy in North County.
--                       Defaults here are deliberately conservative.
--   * financing       = scenario inputs (down %, rate, amortization years).
-- ============================================================

PRAGMA foreign_keys = ON;

DROP VIEW  IF EXISTS v_investment_analysis;
DROP TABLE IF EXISTS analysis_assumptions;

CREATE TABLE analysis_assumptions (
    property_id        INTEGER PRIMARY KEY REFERENCES properties(property_id),
    monthly_rent       REAL,     -- ESTIMATE - replace with real rent
    vacancy_pct        REAL DEFAULT 8.0,    -- % of gross rent lost to vacancy
    mgmt_pct           REAL DEFAULT 8.0,    -- property management, % of collected rent
    maintenance_pct    REAL DEFAULT 8.0,    -- repairs/maintenance, % of gross rent
    capex_pct          REAL DEFAULT 5.0,    -- capital reserves, % of gross rent
    insurance_annual   REAL DEFAULT 1000,   -- annual hazard insurance ($)
    other_annual       REAL DEFAULT 0,      -- misc annual expense ($)
    -- financing scenario
    down_pct           REAL DEFAULT 25.0,   -- down payment % of purchase price
    interest_rate_pct  REAL DEFAULT 7.5,    -- annual mortgage rate
    amort_years        INTEGER DEFAULT 30,  -- amortization period
    closing_pct        REAL DEFAULT 3.0     -- closing costs % of purchase (part of cash in)
);

-- Seed defaults. monthly_rent estimated at ~0.9%/mo of 2025 market value,
-- rounded to nearest $25 (documented estimate; override per property).
INSERT INTO analysis_assumptions (property_id, monthly_rent)
SELECT p.property_id,
       ROUND( (v.market_total * 0.009) / 25.0 ) * 25.0
FROM properties p
JOIN valuations v ON v.property_id = p.property_id AND v.year = 2025;

-- ------------------------------------------------------------
-- v_investment_analysis: one row per property with full metrics
-- ------------------------------------------------------------
CREATE VIEW v_investment_analysis AS
WITH base AS (
    SELECT
        p.property_id,
        p.address,
        s.sale_price                                   AS purchase_price,
        COALESCE(val.realavm, val.market_total)        AS current_value,
        val.total_tax                                  AS annual_tax,
        a.monthly_rent,
        a.vacancy_pct, a.mgmt_pct, a.maintenance_pct, a.capex_pct,
        a.insurance_annual, a.other_annual,
        a.down_pct, a.interest_rate_pct, a.amort_years, a.closing_pct
    FROM properties p
    JOIN analysis_assumptions a ON a.property_id = p.property_id
    LEFT JOIN sale_history s ON s.property_id = p.property_id AND s.is_last_sale = 1
    LEFT JOIN valuations  val ON val.property_id = p.property_id AND val.year = 2025
),
calc AS (
    SELECT
        base.*,
        (monthly_rent * 12.0)                                       AS gross_rent,
        (monthly_rent * 12.0) * (vacancy_pct / 100.0)               AS vacancy_loss,
        (monthly_rent * 12.0) * (1 - vacancy_pct / 100.0)           AS egi_pre,  -- effective gross income
        -- operating expenses (exclude mortgage)
        (monthly_rent * 12.0) * (mgmt_pct / 100.0)                  AS mgmt_exp,
        (monthly_rent * 12.0) * (maintenance_pct / 100.0)           AS maint_exp,
        (monthly_rent * 12.0) * (capex_pct / 100.0)                 AS capex_exp,
        annual_tax                                                  AS tax_exp,
        insurance_annual                                            AS ins_exp,
        other_annual                                                AS other_exp,
        -- financing
        (purchase_price * down_pct / 100.0)                         AS down_payment,
        (purchase_price * (1 - down_pct / 100.0))                   AS loan_amount,
        (purchase_price * closing_pct / 100.0)                      AS closing_costs
    FROM base
),
fin AS (
    SELECT
        calc.*,
        (mgmt_exp + maint_exp + capex_exp + tax_exp + ins_exp + other_exp) AS opex_total,
        -- monthly mortgage payment via amortization formula
        CASE WHEN interest_rate_pct = 0
             THEN loan_amount / (amort_years * 12.0)
             ELSE loan_amount
                  * ( (interest_rate_pct/100.0/12.0)
                      * POWER(1 + interest_rate_pct/100.0/12.0, amort_years*12) )
                  / ( POWER(1 + interest_rate_pct/100.0/12.0, amort_years*12) - 1 )
        END                                                          AS monthly_pi
    FROM calc
)
SELECT
    property_id,
    address,
    ROUND(purchase_price)                          AS purchase_price,
    ROUND(current_value)                           AS current_value,
    ROUND(monthly_rent)                            AS monthly_rent,
    ROUND(gross_rent)                              AS gross_rent,
    ROUND(egi_pre)                                 AS effective_gross_income,
    ROUND(opex_total)                              AS operating_expenses,
    ROUND(egi_pre - opex_total)                    AS noi,
    -- cap rate on purchase price and on current value
    ROUND(100.0 * (egi_pre - opex_total) / purchase_price, 2)   AS cap_rate_on_purchase,
    ROUND(100.0 * (egi_pre - opex_total) / current_value, 2)    AS cap_rate_on_value,
    -- gross rent multiplier
    ROUND(purchase_price / gross_rent, 2)          AS grm,
    -- operating expense ratio
    ROUND(100.0 * opex_total / egi_pre, 1)         AS opex_ratio_pct,
    -- financing
    ROUND(down_payment)                            AS down_payment,
    ROUND(loan_amount)                             AS loan_amount,
    ROUND(closing_costs)                           AS closing_costs,
    ROUND(down_payment + closing_costs)            AS total_cash_invested,
    ROUND(monthly_pi)                              AS monthly_debt_service,
    ROUND(monthly_pi * 12.0)                       AS annual_debt_service,
    ROUND((egi_pre - opex_total) - (monthly_pi * 12.0))         AS annual_cash_flow,
    ROUND(((egi_pre - opex_total) - (monthly_pi * 12.0)) / 12.0) AS monthly_cash_flow,
    -- cash-on-cash return
    ROUND(100.0 * ((egi_pre - opex_total) - (monthly_pi * 12.0))
          / NULLIF(down_payment + closing_costs, 0), 2)         AS cash_on_cash_pct,
    -- debt service coverage ratio
    ROUND((egi_pre - opex_total) / NULLIF(monthly_pi * 12.0, 0), 2) AS dscr
FROM fin;

-- ------------------------------------------------------------
-- v_investment_portfolio: package-level rollup
-- Blended cap rate = total NOI / total value (and / total purchase).
-- ------------------------------------------------------------
DROP VIEW IF EXISTS v_investment_portfolio;
CREATE VIEW v_investment_portfolio AS
SELECT
    COUNT(*)                                          AS num_properties,
    SUM(purchase_price)                               AS total_purchase_price,
    SUM(current_value)                                AS total_current_value,
    SUM(gross_rent)                                   AS total_gross_rent,
    SUM(noi)                                          AS total_noi,
    ROUND(100.0 * SUM(noi) / SUM(purchase_price), 2)  AS blended_cap_on_purchase,
    ROUND(100.0 * SUM(noi) / SUM(current_value), 2)   AS blended_cap_on_value,
    SUM(total_cash_invested)                          AS total_cash_invested,
    SUM(annual_debt_service)                          AS total_annual_debt_service,
    SUM(annual_cash_flow)                             AS total_annual_cash_flow,
    ROUND(100.0 * SUM(annual_cash_flow) / NULLIF(SUM(total_cash_invested),0), 2) AS portfolio_cash_on_cash,
    ROUND(SUM(noi) / NULLIF(SUM(annual_debt_service),0), 2) AS portfolio_dscr
FROM v_investment_analysis;
