-- =====================================================================
-- SCHEMA:banking
-- Purpose: Crete all the schemas for the DW
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS mart;
SET search_path TO raw;
SET search_path TO staging;
SET search_path TO core;
SET search_path TO mart;
