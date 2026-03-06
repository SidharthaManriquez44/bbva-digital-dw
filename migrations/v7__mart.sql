-- =====================================================
-- Table: mart.bank_financial_year
-- Purpose: Financial metrics aggregated by year
-- Grain: 1 row per bank per year per load
-- Strategy: Full refresh with lineage tracking
-- =====================================================

CREATE TABLE mart.bank_financial_year (

    -- Business Keys
    bank_code TEXT NOT NULL,
    year INT NOT NULL,

    -- Financial Metrics
    total_loans NUMERIC(18,2) NOT NULL,
    total_deposits NUMERIC(18,2) NOT NULL,
    net_income NUMERIC(18,2) NOT NULL,

    -- ===============================
    -- Data Lineage & Audit Metadata
    -- ===============================

    load_timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
    source_system TEXT NOT NULL DEFAULT 'core.fact_bank_metrics',
    created_by TEXT NOT NULL DEFAULT 'pipeline',


    -- ===============================
    -- Constraints
    -- ===============================

    CONSTRAINT pk_bank_financial_year
        PRIMARY KEY (bank_code, year)
);

-- =====================================================
-- Table: mart.bank_digital_year
-- Purpose: Digital transformation metrics by year
-- Grain: 1 row per bank per year
-- Refresh Strategy: Full refresh from CORE
-- =====================================================

CREATE TABLE mart.bank_digital_year (

    -- Business Keys
    bank_code TEXT NOT NULL,
    year INT NOT NULL,

    -- Digital Metrics
    digital_clients BIGINT NOT NULL,
    total_clients BIGINT NOT NULL,
    digital_penetration_pct NUMERIC(5,2) NOT NULL,

    -- ===============================
    -- Data Lineage & Audit Metadata
    -- ===============================

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    source_system TEXT NOT NULL DEFAULT 'core.fact_bank_metrics',
    created_by TEXT NOT NULL DEFAULT 'pipeline',

    -- ===============================
    -- Constraints
    -- ===============================

    CONSTRAINT pk_bank_digital_year
        PRIMARY KEY (bank_code, year)
);

-- =====================================================
-- Table: mart.bank_efficiency_year
-- Purpose: Operational efficiency metrics by year
-- Grain: 1 row per bank per year
-- Refresh Strategy: Full refresh from CORE
-- =====================================================

CREATE TABLE mart.bank_efficiency_year (

    -- Business Keys
    bank_code TEXT NOT NULL,
    year INT NOT NULL,

    -- Structural Metrics
    branches INT NOT NULL,
    atms INT NOT NULL,

    -- Efficiency Ratios
    clients_per_branch NUMERIC(18,2) NOT NULL,
    loans_per_branch NUMERIC(18,2) NOT NULL,
    deposits_per_branch NUMERIC(18,2) NOT NULL,
    profit_per_branch NUMERIC(18,2) NOT NULL,

    -- ===============================
    -- Data Lineage & Audit Metadata
    -- ===============================

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    source_system TEXT NOT NULL DEFAULT 'core.fact_bank_metrics',
    created_by TEXT NOT NULL DEFAULT 'pipeline',

    -- ===============================
    -- Constraints
    -- ===============================

    CONSTRAINT pk_bank_efficiency_year
        PRIMARY KEY (bank_code, year)
);

-- =====================================================
-- Table: mart.bank_growth_year
-- Purpose: Year-over-year growth metrics
-- Grain: 1 row per bank per year
-- Refresh Strategy: Full refresh from CORE
-- =====================================================

CREATE TABLE mart.bank_growth_year (

    -- Business Keys
    bank_code TEXT NOT NULL,
    year INT NOT NULL,

    -- Growth Metrics (% YoY)
    loans_yoy_pct NUMERIC(7,2),
    deposits_yoy_pct NUMERIC(7,2),
    net_income_yoy_pct NUMERIC(7,2),

    -- Audit metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    source_system TEXT NOT NULL DEFAULT 'core.fact_bank_metrics',
    created_by TEXT NOT NULL DEFAULT 'pipeline',

    CONSTRAINT pk_bank_growth_year
        PRIMARY KEY (bank_code, year)
);

-- =====================================================
-- Table: mart.v_bank_executive_dashboard
-- Purpose: For metrics in dashboard
-- Grain: 1 row per year
-- Refresh Strategy: Full refresh from CORE alive
-- =====================================================

CREATE OR REPLACE VIEW mart.v_bank_executive_dashboard AS
SELECT
    -- ==============================
    -- Identifiers
    -- ==============================
    f.bank_code,
    f.year,

    -- ==============================
    -- Financial Size
    -- ==============================
    f.total_loans,
    f.total_deposits,
    f.net_income,

    -- ==============================
    -- Digital Metrics
    -- ==============================
    d.total_clients,
    d.digital_clients,
    d.digital_penetration_pct,

    -- ==============================
    -- Operational Structure
    -- ==============================
    e.branches,
    e.atms,
    e.profit_per_branch,

    -- ==============================
    -- Growth Metrics (YoY)
    -- ==============================
    g.loans_yoy_pct,
    g.deposits_yoy_pct,
    g.net_income_yoy_pct

FROM mart.bank_financial_year f

LEFT JOIN mart.bank_digital_year d
    ON f.bank_code = d.bank_code
    AND f.year = d.year

LEFT JOIN mart.bank_efficiency_year e
    ON f.bank_code = e.bank_code
    AND f.year = e.year

LEFT JOIN mart.bank_growth_year g
    ON f.bank_code = g.bank_code
    AND f.year = g.year;

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