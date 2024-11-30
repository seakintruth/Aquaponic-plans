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
-- All table creations
DO $$
BEGIN
    -- Log table
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM pg_catalog.pg_class c
            JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' AND c.relname = 'log'
        ) THEN
            CREATE TABLE log (
                id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
                log_entry TEXT NOT NULL,
                log_category TEXT DEFAULT 'INFO',
                entry_time TIMESTAMP DEFAULT now()
            );
        ELSE
            RAISE NOTICE 'Table log already exists.';
        END IF;
    EXCEPTION WHEN others THEN
        RAISE NOTICE 'Error creating or checking log table: %', SQLERRM;
    END;

    -- Sensor_type table (should be created before sensor for FK reference)
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'sensor_type') THEN
            CREATE TABLE sensor_type (
                sensor_type_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
                type_name TEXT NOT NULL,
                scale_factor INTEGER NOT NULL,
                unit TEXT NOT NULL,
                capture_after_delta_percent DECIMAL(5,2) NOT NULL
            );
        ELSE
            RAISE NOTICE 'Table sensor_type already exists.';
        END IF;
    EXCEPTION WHEN others THEN
        RAISE EXCEPTION 'Failed to create or check for sensor_type table: %', SQLERRM;
    END;

    -- Area table
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'area') THEN
            CREATE TABLE area (
                area_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
                area_name TEXT NOT NULL,
                description TEXT
            );
        ELSE
            RAISE NOTICE 'Table area already exists.';
        END IF;
    EXCEPTION WHEN others THEN
        RAISE EXCEPTION 'Failed to create or check for area table: %', SQLERRM;
    END;

    -- geo_ref table
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'geo_ref') THEN
            CREATE TABLE geo_ref (
                anchor_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
                anchor_lat DECIMAL(10, 8) NOT NULL,
                anchor_lon DECIMAL(11, 8) NOT NULL,
                anchor_elevation DECIMAL(10, 3),
                anchor_description TEXT,
                CONSTRAINT unique_location UNIQUE (anchor_lat, anchor_lon)
            );
        ELSE
            RAISE NOTICE 'Table geo_ref already exists.';
        END IF;
    EXCEPTION WHEN others THEN
        RAISE NOTICE 'Error creating or checking geo_ref table: %', SQLERRM;
    END;

    -- System table
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'system') THEN
            CREATE TABLE system (
                system_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
                system_name TEXT NOT NULL,
                system_type TEXT NOT NULL
            );
        ELSE
            RAISE NOTICE 'Table system already exists.';
        END IF;
    EXCEPTION WHEN others THEN
        RAISE EXCEPTION 'Failed to create or check for system table: %', SQLERRM;
    END;

    -- Sensor table
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'sensor') THEN
            CREATE TABLE sensor (
                sensor_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
                sensor_type_id INTEGER NOT NULL,
                area_id INTEGER,
                system_id INTEGER,
                location TEXT,
                local_x DECIMAL(10,2),
                local_y DECIMAL(10,2),
                local_z DECIMAL(10,2),
                installation_date DATE,
                CONSTRAINT fk_sensor_to_sensor_type FOREIGN KEY (sensor_type_id) REFERENCES sensor_type(sensor_type_id),
                CONSTRAINT fk_sensor_to_area FOREIGN KEY (area_id) REFERENCES area(area_id),
                CONSTRAINT fk_sensor_to_system FOREIGN KEY (system_id) REFERENCES system(system_id)
            );
            -- Indexes 
            CREATE INDEX IF NOT EXISTS idx_sensor_type_id ON sensor (sensor_type_id);
            CREATE INDEX IF NOT EXISTS idx_sensor_area_id ON sensor (area_id);
            CREATE INDEX IF NOT EXISTS idx_sensor_system_id ON sensor (system_id);
        ELSE
            RAISE NOTICE 'Table sensor already exists.';
        END IF;
    EXCEPTION WHEN others THEN
        RAISE EXCEPTION 'Failed to create or check for sensor table: %', SQLERRM;
    END;

    -- Sensor_datum table
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'sensor_datum') THEN
            CREATE TABLE sensor_datum (
                time         TIMESTAMPTZ   NOT NULL,
                sensor_id    INTEGER       NOT NULL,
                value        INTEGER,
                PRIMARY KEY (time, sensor_id),
                CONSTRAINT fk_sensor_datum_to_sensor FOREIGN KEY (sensor_id) REFERENCES sensor(sensor_id)
            );
            PERFORM create_hypertable('sensor_datum', 'time');
        ELSE
            RAISE NOTICE 'Table sensor_datum already exists.';
        END IF;

        -- Create INDEX
        CREATE INDEX IF NOT EXISTS idx_sensor_datum_time ON sensor_datum (time);
    EXCEPTION WHEN others THEN
        RAISE EXCEPTION 'Failed to create or check for sensor_datum table: %', SQLERRM;
    END;

    -- Label table
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'label') THEN
            CREATE TABLE label (
                label_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
                label_name TEXT NOT NULL,
                description TEXT,
                CONSTRAINT unique_label_name UNIQUE (label_name)
            );
        ELSE
            RAISE NOTICE 'Table label already exists.';
        END IF;
    EXCEPTION WHEN others THEN
        RAISE EXCEPTION 'Failed to create or check for label table: %', SQLERRM;
    END;

    -- Label assignment table
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'label_assignment') THEN
            CREATE TABLE label_assignment (
                label_assignment_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
                entity_id INTEGER NOT NULL,
                entity_type TEXT NOT NULL CHECK (entity_type IN ('sensor', 'area', 'system', 'alert')),
                label_id INTEGER NOT NULL,
                FOREIGN KEY (label_id) REFERENCES label(label_id),
                CONSTRAINT unique_label_assignment UNIQUE (entity_id, entity_type, label_id)
            );
            CREATE INDEX IF NOT EXISTS idx_label_assignment_entity ON label_assignment (entity_id, entity_type);
        ELSE
            RAISE NOTICE 'Table label_assignment already exists.';
        END IF;
    EXCEPTION WHEN others THEN
        RAISE EXCEPTION 'Failed to create or check for label_assignment table: %', SQLERRM;
    END;

    -- Systemwide_alert table
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'systemwide_alert') THEN
            CREATE TABLE systemwide_alert (
                alert_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
                sensor_id INTEGER,
                area_id INTEGER,
                system_id INTEGER,
                alert_type TEXT NOT NULL,
                alert_message TEXT,
                alert_time TIMESTAMP DEFAULT now(),
                CONSTRAINT fk_sensor_datum_to_sensor FOREIGN KEY (sensor_id) REFERENCES sensor(sensor_id),
                CONSTRAINT fk_sensor_datum_to_area FOREIGN KEY (area_id) REFERENCES area(area_id),
                CONSTRAINT fk_sensor_datum_to_system FOREIGN KEY (system_id) REFERENCES system(system_id)
            );
        ELSE
            RAISE NOTICE 'Table systemwide_alert already exists.';
        END IF;
    EXCEPTION WHEN others THEN
        RAISE EXCEPTION 'Failed to create or check for systemwide_alert table: %', SQLERRM;
    END;

    -- Second by Second for Last 15 Minutes
    BEGIN
        -- DROP MATERIALIZED VIEW IF EXISTS second_by_second_last_15_minutes;
        CREATE MATERIALIZED VIEW second_by_second_last_15_minutes AS
        WITH seconds AS (
            SELECT generate_series(
                now() - interval '15 minutes',
                now(),
                interval '1 second'
            ) AS second_timestamp
        )
        SELECT 
            s.second_timestamp AS time,
            sd.sensor_id,
            sd.value,
            sd.time AS actual_record_time
        FROM seconds s
        LEFT JOIN (
            SELECT 
                sensor_id, 
                value, 
                time,
                LEAD(time) OVER (PARTITION BY sensor_id ORDER BY time) AS next_time
            FROM sensor_datum
            WHERE time > now() - interval '15 minutes'
        ) sd ON s.second_timestamp >= sd.time 
            AND (sd.next_time IS NULL OR s.second_timestamp < sd.next_time)
        ORDER BY s.second_timestamp, sd.sensor_id;

        CREATE INDEX IF NOT EXISTS idx_second_by_second_last_15_minutes ON second_by_second_last_15_minutes (time, sensor_id);
        
        REFRESH MATERIALIZED VIEW second_by_second_last_15_minutes;
    EXCEPTION WHEN others THEN
        RAISE NOTICE 'Error handling second_by_second_last_15_minutes: %', SQLERRM;
    END;

    -- Minute by Minute for Last 24 Hours
    BEGIN
        -- DROP MATERIALIZED VIEW IF EXISTS minute_by_minute_last_24_hours;
        CREATE MATERIALIZED VIEW minute_by_minute_last_24_hours AS
        WITH minutes AS (
            SELECT generate_series(
                now() - interval '24 hours',
                now(),
                interval '1 minute'
            ) AS minute_timestamp
        )
        SELECT 
            m.minute_timestamp AS time,
            sd.sensor_id,
            sd.value,
            sd.time AS actual_record_time
        FROM minutes m
        LEFT JOIN (
            SELECT 
                sensor_id, 
                value, 
                time,
                LEAD(time) OVER (PARTITION BY sensor_id ORDER BY time) AS next_time
            FROM sensor_datum
            WHERE time > now() - interval '24 hours'
        ) sd ON m.minute_timestamp >= sd.time 
            AND (sd.next_time IS NULL OR m.minute_timestamp < sd.next_time)
        ORDER BY m.minute_timestamp, sd.sensor_id;

        CREATE INDEX IF NOT EXISTS idx_minute_by_minute_last_24_hours ON minute_by_minute_last_24_hours (time, sensor_id);
        
        REFRESH MATERIALIZED VIEW minute_by_minute_last_24_hours;
    EXCEPTION WHEN others THEN
        RAISE NOTICE 'Error handling minute_by_minute_last_24_hours: %', SQLERRM;
    END;

    -- Hourly for Last Week
    BEGIN
        -- DROP MATERIALIZED VIEW IF EXISTS hourly_last_week;
        CREATE MATERIALIZED VIEW hourly_last_week AS
        WITH hours AS (
            SELECT generate_series(
                now() - interval '1 week',
                now(),
                interval '1 hour'
            ) AS hour_timestamp
        )
        SELECT 
            h.hour_timestamp AS time,
            sd.sensor_id,
            sd.value,
            sd.time AS actual_record_time
        FROM hours h
        LEFT JOIN (
            SELECT 
                sensor_id, 
                value, 
                time,
                LEAD(time) OVER (PARTITION BY sensor_id ORDER BY time) AS next_time
            FROM sensor_datum
            WHERE time > now() - interval '1 week'
        ) sd ON h.hour_timestamp >= sd.time 
            AND (sd.next_time IS NULL OR h.hour_timestamp < sd.next_time)
        ORDER BY h.hour_timestamp, sd.sensor_id;

        CREATE INDEX IF NOT EXISTS idx_hourly_last_week ON hourly_last_week (time, sensor_id);
        
        REFRESH MATERIALIZED VIEW hourly_last_week;
    EXCEPTION WHEN others THEN
        RAISE NOTICE 'Error handling hourly_last_week: %', SQLERRM;
    END;

EXCEPTION WHEN others THEN
    RAISE EXCEPTION 'An error occurred in the main transaction: %', SQLERRM;
END $$;