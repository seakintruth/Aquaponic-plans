/*
MIT License Noticeflo
Copyright (c) 2024 Jeremy D. Gerdes <seakintruth@gmail.com>
See full license in the repository.

Script Version: V0.2
Author: Jeremy D. Gerdes
Email: seakintruth@gmail.com
*/

/*
PGSQL Dependencies 
-> aquaponics_db=# \dx;
                                               List of installed extensions
    Name     | Version |   Schema   |                                     Description                    
 faker       | 0.5.3   | public     | Wrapper for the Faker Python library
 pg_cron     | 1.6     | pg_catalog | Job scheduler for PostgreSQL
 plpgsql     | 1.0     | pg_catalog | PL/pgSQL procedural language
 plpython3u  | 1.0     | pg_catalog | PL/Python3U untrusted procedural language
 timescaledb | 2.17.2  | public     | Enables scalable inserts and complex queries for time-series data (Apache 2 Edition)

This script sets up a database schema for an aquaponics system using PostgreSQL with TimescaleDB.
It creates tables for various system components, sensor types, metadata, and data storage for efficient management and analysis.
*/
-- All table creations
DO $$
BEGIN
    -- Create log_table if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_class c
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public' AND c.relname = 'log'
    ) THEN
        CREATE TABLE log (
            id SERIAL PRIMARY KEY,
            log_entry TEXT NOT NULL,
            log_category TEXT DEFAULT 'INFO',
            entry_time TIMESTAMP DEFAULT now()
        );
    ELSE
        RAISE NOTICE 'Table log already exists.';
    END IF;

    -- Create zone table for different areas in the aquaponics system
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'zone') THEN
        CREATE TABLE zone (
            zone_id SERIAL PRIMARY KEY,
            zone_name TEXT NOT NULL,
            description TEXT
        );
    ELSE
        RAISE NOTICE 'Table zone already exists.';
    END IF;

    -- Create system table for different subsystems (e.g., water, electrical)
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'system') THEN
        CREATE TABLE system (
            system_id SERIAL PRIMARY KEY,
            system_name TEXT NOT NULL,
            system_type TEXT NOT NULL
        );
    ELSE
        RAISE NOTICE 'Table system already exists.';
    END IF;

    -- Create sensor_type table for sensor metadata
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'sensor_type') THEN
        CREATE TABLE sensor_type (
            sensor_type_id SERIAL PRIMARY KEY,
            type_name TEXT NOT NULL,
            scale_factor INTEGER NOT NULL,
            unit TEXT NOT NULL
        );
    ELSE
        RAISE NOTICE 'Table sensor_type already exists.';
    END IF;

    -- Create sensor table for individual sensors information
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'sensor') THEN
        CREATE TABLE sensor (
            sensor_id TEXT PRIMARY KEY,
            sensor_type_id INTEGER NOT NULL,
            zone_id INTEGER,
            system_id INTEGER,
            location TEXT,
            installation_date DATE,
            CONSTRAINT fk_sensor_to_sensor_type FOREIGN KEY (sensor_type_id) REFERENCES sensor_type(sensor_type_id),
            CONSTRAINT fk_sensor_to_zone FOREIGN KEY (zone_id) REFERENCES zone(zone_id),
            CONSTRAINT fk_sensor_to_system FOREIGN KEY (system_id) REFERENCES system(system_id)
        );
        
        -- Check if index exists before creating it
        IF NOT EXISTS (
            SELECT 1 FROM pg_class c JOIN pg_index i ON c.oid = i.indexrelid
            JOIN pg_class c2 ON c2.oid = i.indrelid
            WHERE c.relname = 'idx_sensor_type_id' AND c2.relname = 'sensor'
        ) THEN
            CREATE INDEX idx_sensor_type_id ON sensor (sensor_type_id);
        ELSE
            RAISE NOTICE 'Index idx_sensor_type_id already exists.';
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM pg_class c JOIN pg_index i ON c.oid = i.indexrelid
            JOIN pg_class c2 ON c2.oid = i.indrelid
            WHERE c.relname = 'idx_zone_id' AND c2.relname = 'sensor'
        ) THEN
            CREATE INDEX idx_zone_id ON sensor (zone_id);
        ELSE
            RAISE NOTICE 'Index idx_zone_id already exists.';
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM pg_class c JOIN pg_index i ON c.oid = i.indexrelid
            JOIN pg_class c2 ON c2.oid = i.indrelid
            WHERE c.relname = 'idx_system_id' AND c2.relname = 'sensor'
        ) THEN
            CREATE INDEX idx_system_id ON sensor (system_id);
        ELSE
            RAISE NOTICE 'Index idx_system_id already exists.';
        END IF;

    ELSE
        RAISE NOTICE 'Table sensor already exists.';
    END IF;

    -- Create sensor_datum hypertable for time-series data
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'sensor_datum') THEN
        CREATE TABLE sensor_datum (
            time         TIMESTAMPTZ   NOT NULL,
            sensor_id    TEXT          NOT NULL,
            value        INTEGER,
            PRIMARY KEY (time, sensor_id),
            CONSTRAINT fk_sensor_datum_to_sensor FOREIGN KEY (sensor_id) REFERENCES sensor(sensor_id)
        );
        PERFORM create_hypertable('sensor_datum', 'time');
    ELSE
        RAISE NOTICE 'Table sensor_datum already exists.';
    END IF;

    -- Create alert table for system alerts
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'systemwide_alert') THEN
        CREATE TABLE systemwide_alert (
            alert_id SERIAL PRIMARY KEY,
            sensor_id TEXT,
            zone_id INTEGER,
            system_id INTEGER,
            alert_type TEXT NOT NULL,
            alert_message TEXT,
            alert_time TIMESTAMP DEFAULT now(),
            FOREIGN KEY (sensor_id) REFERENCES sensor(sensor_id),
            FOREIGN KEY (zone_id) REFERENCES zone(zone_id),
            FOREIGN KEY (system_id) REFERENCES system(system_id)
        );
    ELSE
        RAISE NOTICE 'Table systemwide_alert already exists.';
    END IF;

END $$;

-- Schedule db status logging 

-- Unschedule the status job running every 5 minutes if it already exists
DO $$
DECLARE
  status_job_id INTEGER;
BEGIN
  SELECT jobid INTO status_job_id FROM cron.job WHERE command = $$INSERT INTO log (log_entry,log_category) VALUES ('status','up');$$;
  IF status_job_id IS NOT NULL THEN
      PERFORM cron.unschedule(status_job_id);
      INSERT INTO log (log_entry, log_category) VALUES ('Status job unscheduled', 'cron.unschedule');
  END IF;

  -- Schedule the status job to run every 5 minutes
  SELECT cron.schedule('*/5 * * * *', $$INSERT INTO log (log_entry,log_category) VALUES ('status','up');$$) INTO status_job_id;
  INSERT INTO log (log_entry, log_category) VALUES ('Status job scheduled', 'cron.schedule');
END $$;

-- Insert data into tables
-- ... (Your existing INSERT statements here, adjusted for singular table names)

-- Create a regular materialized view
CREATE MATERIALIZED VIEW IF NOT EXISTS hourly_sensor_data AS
SELECT 
    time_bucket('1 hour', time) AS bucket,
    sensor_id,
    AVG(value) AS avg_value_scaled
FROM sensor_datum
GROUP BY bucket, sensor_id;

-- Create a unique index on the materialized view for concurrent refresh
CREATE UNIQUE INDEX IF NOT EXISTS idx_hourly_sensor_data_bucket_sensor_id ON hourly_sensor_data (bucket, sensor_id);

-- Refresh the materialized view concurrently
REFRESH MATERIALIZED VIEW CONCURRENTLY hourly_sensor_data;


