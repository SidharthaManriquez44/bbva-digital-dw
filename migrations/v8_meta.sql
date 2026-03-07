-- =====================================================
-- Table: meta.etl_runs
-- Purpose: This is one of the most important improvements
--          in real-world pipelines because it allows:
--          * pipeline auditing
--          * knowing when it ran
--          * knowing if it failed
--          * knowing how many records it loaded
-- =====================================================
CREATE TABLE meta.etl_runs (
    run_id BIGSERIAL PRIMARY KEY,
    pipeline_name VARCHAR(100),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    status VARCHAR(20),
    rows_loaded INTEGER,
    error_message TEXT
);

-- =====================================================
-- We must to create a initial insert in the table watermarks
--          INSERT INTO meta.pipeline_watermarks
--          VALUES ('bbva_data_pipeline', 0);
-- =====================================================

CREATE TABLE meta.pipeline_watermarks (
    pipeline_name TEXT PRIMARY KEY,
    last_year INTEGER
);
