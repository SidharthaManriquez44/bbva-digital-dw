-- =====================================================================
-- SCHEMA:staging
-- Purpose: Acts as a temporary, intermediate storage area for
--          raw data extracted from source systems before it is
--          transformed and loaded into the final data warehouse.
-- ====================================================================
CREATE TABLE staging.bank_year_metrics_clean (
    staging_id BIGSERIAL PRIMARY KEY,
    raw_id BIGINT NOT NULL,
    bank_code VARCHAR(20) NOT NULL,
    year SMALLINT NOT NULL CHECK (year BETWEEN 2000 AND 2100),
    branches INT CHECK (branches >= 0),
    atms INT CHECK (atms >= 0),
    total_clients INT CHECK (total_clients >= 0),
    digital_clients INT CHECK (digital_clients >= 0),
    total_loans BIGINT CHECK (total_loans >= 0),
    total_deposits BIGINT CHECK (total_deposits >= 0),
    net_income BIGINT,
    is_valid BOOLEAN DEFAULT TRUE,
    validation_message TEXT,
    ingestion_timestamp TIMESTAMP NOT NULL,

    CONSTRAINT uq_staging_grain UNIQUE (bank_code, year)
);

CREATE TABLE staging.etl_batch_control (
    batch_id BIGSERIAL PRIMARY KEY,
    source_name TEXT,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    status VARCHAR(20),
    records_raw INT,
    records_staging INT
);
