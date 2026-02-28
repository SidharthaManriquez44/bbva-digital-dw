-- =====================================================================
-- SCHEMA:raw
-- Purpose: Serve as the landing zone for unprocessed data
-- =====================================================================
CREATE TABLE raw.bank_year_metrics_raw (
    raw_id BIGSERIAL PRIMARY KEY,
    batch_id BIGINT,
    bank_code TEXT,
    year TEXT,
    branches TEXT,
    atms TEXT,
    total_clients TEXT,
    digital_clients TEXT,
    total_loans TEXT,
    total_deposits TEXT,
    net_income TEXT,
    source_file_name TEXT,
    ingestion_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
