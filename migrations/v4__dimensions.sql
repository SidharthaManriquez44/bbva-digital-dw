-- =====================================================================
-- SCHEMA: core
-- Purpose: Dimension tables in a data warehouse store descriptive, textual
--          attributes (context)
-- ====================================================================

CREATE TABLE core.dim_bank (
    bank_key SERIAL PRIMARY KEY,
    bank_code VARCHAR(20) NOT NULL UNIQUE,
    bank_name VARCHAR(100) NOT NULL,
    country VARCHAR(50) DEFAULT 'México',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE core.dim_date (
    date_key INT PRIMARY KEY,
    date DATE NOT NULL,
    year SMALLINT NOT NULL,
    quarter SMALLINT,
    month SMALLINT,
    is_year_end BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE core.dim_channel (
    channel_key SERIAL PRIMARY KEY,
    channel_code VARCHAR(20) NOT NULL,
    channel_name VARCHAR(50) NOT NULL,
    channel_description VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to DATE,
    is_current BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_channel UNIQUE (channel_code, effective_from)
);