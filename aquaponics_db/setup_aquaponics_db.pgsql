/*
MIT License Notice
Copyright (c) 2024 Jeremy D. Gerdes <seakintruth@gmail.com>
See full license in the repository.

Script Version: V0.2.2
Author: Jeremy D. Gerdes
Email: seakintruth@gmail.com
*/

/*
PGSQL Dependencies 
-> aquaponics_db=# \dx;
                                               List of installed extensions
    Name     | Version |   Schema   |                                     Description   
 adminpack   | 2.1     | pg_catalog | administrative functions for PostgreSQL                   
 faker       | 0.5.3   | public     | Wrapper for the Faker Python library
 pg_cron     | 1.6     | pg_catalog | Job scheduler for PostgreSQL
 plpgsql     | 1.0     | pg_catalog | PL/pgSQL procedural language
 plpython3u  | 1.0     | pg_catalog | PL/Python3U untrusted procedural language
 timescaledb | 2.17.2  | public     | Enables scalable inserts and complex queries for time-series data (Apache 2 Edition)

--CREATE EXTENSION adminpack;
SELECT * FROM pg_available_extensions WHERE name = 'adminpack';

This script sets up a database schema for an aquaponics system using PostgreSQL with TimescaleDB.
It creates tables for various system components, sensor types, metadata, and data storage for efficient management and analysis.
*/

DO $$
BEGIN
    -- ********************************
    -- Create tables 
    -- ********************************

    -- Log table, no foreign keys needed here as it's for logging system events.
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

    -- geo_ref table, no foreign keys since it's a base reference.
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'geo_ref') THEN
        CREATE TABLE geo_ref (
            anchor_id SERIAL PRIMARY KEY,
            anchor_lat DECIMAL(10, 8) NOT NULL,
            anchor_lon DECIMAL(11, 8) NOT NULL,
            anchor_elevation DECIMAL(10, 3),
            anchor_description TEXT,
            CONSTRAINT unique_location UNIQUE (anchor_lat, anchor_lon)
        );
    ELSE
        RAISE NOTICE 'Table geo_ref already exists.';
    END IF;

    -- Zone table, no foreign keys as zones are independent entities.
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'zone') THEN
        CREATE TABLE zone (
            zone_id SERIAL PRIMARY KEY,
            zone_name TEXT NOT NULL,
            description TEXT
        );
    ELSE
        RAISE NOTICE 'Table zone already exists.';
    END IF;

    -- System table, similarly, no foreign keys as systems are independent.
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'system') THEN
        CREATE TABLE system (
            system_id SERIAL PRIMARY KEY,
            system_name TEXT NOT NULL,
            system_type TEXT NOT NULL
        );
    ELSE
        RAISE NOTICE 'Table system already exists.';
    END IF;

    -- Sensor_type table, no foreign keys required.
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

    -- Sensor table with foreign keys to relate to other tables
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'sensor') THEN
        CREATE TABLE sensor (
            sensor_id TEXT PRIMARY KEY,
            sensor_type_id INTEGER NOT NULL,
            zone_id INTEGER,
            system_id INTEGER,
            location TEXT,
            local_x DECIMAL(10,2),
            local_y DECIMAL(10,2),
            local_z DECIMAL(10,2),
            installation_date DATE,
            FOREIGN KEY (sensor_type_id) REFERENCES sensor_type(sensor_type_id),
            FOREIGN KEY (zone_id) REFERENCES zone(zone_id),
            FOREIGN KEY (system_id) REFERENCES system(system_id)
        );
        
        -- Indexes for faster lookups
        CREATE INDEX IF NOT EXISTS idx_sensor_type_id ON sensor (sensor_type_id);
        CREATE INDEX IF NOT EXISTS idx_sensor_zone_id ON sensor (zone_id);
        CREATE INDEX IF NOT EXISTS idx_sensor_system_id ON sensor (system_id);
    ELSE
        RAISE NOTICE 'Table sensor already exists.';
    END IF;

    -- Sensor_datum table with foreign key to sensor
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'sensor_datum') THEN
        CREATE TABLE sensor_datum (
            time         TIMESTAMPTZ   NOT NULL,
            sensor_id    TEXT          NOT NULL,
            value        INTEGER,
            PRIMARY KEY (time, sensor_id),
            FOREIGN KEY (sensor_id) REFERENCES sensor(sensor_id)
        );
        PERFORM create_hypertable('sensor_datum', 'time');
    ELSE
        RAISE NOTICE 'Table sensor_datum already exists.';
    END IF;

    -- Systemwide_alert table with foreign keys to multiple tables
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
