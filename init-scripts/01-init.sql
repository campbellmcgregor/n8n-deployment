-- n8n Database Initialization Script
-- This script runs when the PostgreSQL container starts for the first time

-- Ensure the database exists
SELECT 'CREATE DATABASE n8n' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'n8n')\gexec

-- Set timezone to UTC for consistency
SET timezone = 'UTC';

-- Create a function to log initialization messages
CREATE OR REPLACE FUNCTION log_init_message(message TEXT)
RETURNS VOID AS $$
BEGIN
    RAISE NOTICE '[n8n-init] %', message;
END;
$$ LANGUAGE plpgsql;

-- Log the initialization
SELECT log_init_message('Starting n8n database initialization...');

-- Create additional schemas if needed for custom extensions
-- CREATE SCHEMA IF NOT EXISTS n8n_custom;
-- SELECT log_init_message('Created custom schema for extensions');

-- Set up performance optimizations
-- These will help with n8n's workflow execution queries

-- Enable some useful extensions if they're available
DO $$
BEGIN
    -- UUID extension for better ID generation
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    PERFORM log_init_message('Enabled uuid-ossp extension');
EXCEPTION
    WHEN others THEN
        PERFORM log_init_message('uuid-ossp extension not available, skipping');
END;
$$;

DO $$
BEGIN
    -- pg_stat_statements for query performance monitoring
    CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
    PERFORM log_init_message('Enabled pg_stat_statements extension');
EXCEPTION
    WHEN others THEN
        PERFORM log_init_message('pg_stat_statements extension not available, skipping');
END;
$$;

-- Configure some PostgreSQL settings for better n8n performance
-- Note: These settings should also be set in postgresql.conf for persistence

-- Increase work_mem for complex queries
-- SET work_mem = '32MB';

-- Increase shared_buffers if you have enough RAM
-- SET shared_buffers = '256MB';

-- Set up logging preferences
SET log_statement = 'none';  -- Change to 'all' for debugging
SET log_min_duration_statement = 1000;  -- Log slow queries (1 second+)

-- Create a table for storing custom n8n metadata if needed
CREATE TABLE IF NOT EXISTS n8n_deployment_info (
    id SERIAL PRIMARY KEY,
    key VARCHAR(255) UNIQUE NOT NULL,
    value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert deployment information
INSERT INTO n8n_deployment_info (key, value) 
VALUES ('initialization_date', CURRENT_TIMESTAMP::TEXT),
       ('version', '1.0.0'),
       ('deployment_type', 'local-docker')
ON CONFLICT (key) DO UPDATE SET 
    value = EXCLUDED.value,
    updated_at = CURRENT_TIMESTAMP;

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for the deployment info table
CREATE TRIGGER update_n8n_deployment_info_updated_at 
    BEFORE UPDATE ON n8n_deployment_info 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Final initialization message
SELECT log_init_message('n8n database initialization completed successfully!');
SELECT log_init_message('Database is ready for n8n workflow automation platform.');

-- Clean up the temporary function
DROP FUNCTION log_init_message(TEXT); 