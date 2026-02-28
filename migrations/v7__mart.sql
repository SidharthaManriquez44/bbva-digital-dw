-- ---------------------------------------------------------------------
-- Mart View
-- View: Bank KPI year
-- Purpose: Calculate derived metrics
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW mart.bank_kpi_year AS
SELECT
    b.bank_code,
    d.year,
    f.branches,
    f.atms,
    f.total_clients,
    f.digital_clients,

    ROUND(
        (f.digital_clients::numeric / NULLIF(f.total_clients,0)) * 100,
        2
    ) AS digital_penetration_pct,

    -- EFFICIENCY METRICS
    ROUND(f.total_clients::numeric / NULLIF(f.branches,0), 2)
        AS clients_per_branch,

    ROUND(f.total_loans::numeric / NULLIF(f.branches,0), 2)
        AS loans_per_branch,

    ROUND(f.total_deposits::numeric / NULLIF(f.branches,0), 2)
        AS deposits_per_branch,

    ROUND(f.net_income::numeric / NULLIF(f.branches,0), 2)
        AS profit_per_branch,

    f.total_loans,
    f.total_deposits,
    f.net_income

FROM core.fact_bank_metrics f
JOIN core.dim_bank b ON f.bank_key = b.bank_key
JOIN core.dim_date d ON f.date_key = d.date_key;

-- ---------------------------------------------------------------------
-- Mart View
-- View: Bank KPI YOY
-- Purpose: Calculate derived metrics
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW mart.bank_kpi_yoy AS

WITH base AS (
    SELECT
        b.bank_code,
        d.year,
        f.branches,
        f.atms,
        f.total_clients,
        f.digital_clients,
        f.total_loans,
        f.total_deposits,
        f.net_income,

        -- Values from the previous year
        LAG(f.total_clients) OVER (PARTITION BY b.bank_code ORDER BY d.year)
            AS prev_total_clients,

        LAG(f.total_loans) OVER (PARTITION BY b.bank_code ORDER BY d.year)
            AS prev_total_loans,

        LAG(f.total_deposits) OVER (PARTITION BY b.bank_code ORDER BY d.year)
            AS prev_total_deposits,

        LAG(f.net_income) OVER (PARTITION BY b.bank_code ORDER BY d.year)
            AS prev_net_income

    FROM core.fact_bank_metrics f
    JOIN core.dim_bank b ON f.bank_key = b.bank_key
    JOIN core.dim_date d ON f.date_key = d.date_key
)

SELECT
    bank_code,
    year,
    branches,
    atms,
    total_clients,
    digital_clients,

    -- Digital Penetration
    ROUND(
        (digital_clients::numeric / NULLIF(total_clients, 0)) * 100,
        2
    ) AS digital_penetration_pct,

    -- Efficiency
    ROUND(total_clients::numeric / NULLIF(branches, 0), 2)
        AS clients_per_branch,

    ROUND(total_loans::numeric / NULLIF(branches, 0), 2)
        AS loans_per_branch,

    ROUND(total_deposits::numeric / NULLIF(branches, 0), 2)
        AS deposits_per_branch,

    ROUND(net_income::numeric / NULLIF(branches, 0), 2)
        AS profit_per_branch,

    -- ==============================
    -- year-on-year growth (YoY)
    -- ==============================

    ROUND(
        (total_clients - prev_total_clients)::numeric
        / NULLIF(prev_total_clients, 0) * 100,
        2
    ) AS clients_yoy_pct,

    ROUND(
        (total_loans - prev_total_loans)::numeric
        / NULLIF(prev_total_loans, 0) * 100,
        2
    ) AS loans_yoy_pct,

    ROUND(
        (total_deposits - prev_total_deposits)::numeric
        / NULLIF(prev_total_deposits, 0) * 100,
        2
    ) AS deposits_yoy_pct,

    ROUND(
        (net_income - prev_net_income)::numeric
        / NULLIF(prev_net_income, 0) * 100,
        2
    ) AS net_income_yoy_pct

FROM base;