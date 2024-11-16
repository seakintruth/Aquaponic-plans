/*
PGSQL Dependancies 
-> aquaponics_db=# \dx;
                                               List of installed extensions
    Name     | Version |   Schema   |                                     Description                    
 faker       | 0.5.3   | public     | Wrapper for the Faker Python library
 pg_cron     | 1.6     | pg_catalog | Job scheduler for PostgreSQL
 plpgsql     | 1.0     | pg_catalog | PL/pgSQL procedural language
 plpython3u  | 1.0     | pg_catalog | PL/Python3U untrusted procedural language
 timescaledb | 2.17.2  | public     | Enables scalable inserts and complex queries for time-series data (
Apache 2 Edition)

This script sets up a database schema for an aquaponics system using PostgreSQL with TimescaleDB.
It creates tables for sensor types, sensor metadata, and sensor data, which is stored as hypertables for efficient time-series data management.
The script also includes sample data insertion and demonstrates the use of a regular materialized view for data analysis.
*/

-- All table creations
DO $$
BEGIN

    -- Create log_table if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_class c
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public' AND c.relname = 'log_table'
    ) THEN
        CREATE TABLE log_table (
            id SERIAL PRIMARY KEY,
            log_entry TEXT NOT NULL,
            log_category TEXT DEFAULT 'INFO',
            entry_time TIMESTAMP DEFAULT now()
        );
    ELSE
        RAISE NOTICE 'Table log_table already exists.';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'sensor_types') THEN
        CREATE TABLE sensor_types (
            sensor_type_id SERIAL PRIMARY KEY,
            type_name TEXT NOT NULL,
            scale_factor INTEGER NOT NULL
        );
    ELSE
        RAISE NOTICE 'Table sensor_types already exists.';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'sensors') THEN
        CREATE TABLE sensors (
            sensor_id TEXT PRIMARY KEY,
            sensor_type_id INTEGER NOT NULL,
            location TEXT,
            installation_date DATE,
            CONSTRAINT fk_sensors_to_sensor_types FOREIGN KEY (sensor_type_id) REFERENCES sensor_types(sensor_type_id)
        );
        CREATE INDEX idx_sensor_type_id ON sensors (sensor_type_id);
    ELSE
        RAISE NOTICE 'Table sensors already exists.';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'sensor_data') THEN
        CREATE TABLE sensor_data (
            time         TIMESTAMPTZ   NOT NULL,
            sensor_id    TEXT          NOT NULL,
            value        INTEGER,
            PRIMARY KEY (time, sensor_id),
            CONSTRAINT fk_sensor_data_to_sensors FOREIGN KEY (sensor_id) REFERENCES sensors(sensor_id)
        );
        PERFORM create_hypertable('sensor_data', 'time');
    ELSE
        RAISE NOTICE 'Table sensor_data already exists.';
    END IF;
END $$;

-- Schedule db status logging 

--  Unschedule the status job running every 5 minutes if it allready is
DO $$
DECLARE
  status_job_id INTEGER;
BEGIN
  SELECT jobid INTO status_job_id FROM cron.job WHERE command = 'INSERT INTO log_table (log_entry,log_category) VALUES (''status'',''up'');';
  IF status_job_id is not null THEN
      INSERT INTO log_table (log_entry, log_category)
      SELECT cron.unschedule(status_job_id), 'cron.unschedule';
  END IF;
END $$;

-- Schedule the status job to run every 5 minutes
INSERT INTO log_table (log_entry, log_category)
SELECT 
    'Status job scheduled, jobid=' || cron.schedule(
        '*/5 * * * *', 'INSERT INTO log_table (log_entry,log_category) VALUES (''status'',''up'');'
    ) AS log_entry,
    'cron.schedule' AS log_category;



-- Insert data into tables
INSERT INTO sensor_types (type_name, scale_factor) 
VALUES 
    ('temperature', 10000),
    ('humidity', 10000),
    ('other_sensor', 100)
ON CONFLICT (sensor_type_id) DO NOTHING;

INSERT INTO sensors (sensor_id, sensor_type_id, location, installation_date)
VALUES 
    ('fake_sensor1', 1, 'Greenhouse A', '2023-01-01'),
    ('fake_sensor2', 2, 'Greenhouse B', '2023-02-01')
ON CONFLICT (sensor_id) DO NOTHING;

INSERT INTO sensor_data (time, sensor_id, value)
VALUES 
    (NOW(), 'fake_sensor1', 225000),
    (NOW() - INTERVAL '1 hour', 'fake_sensor1', 218000),
    (NOW(), 'fake_sensor2', 550000)
ON CONFLICT (time, sensor_id) DO NOTHING;

-- Create a regular materialized view
CREATE MATERIALIZED VIEW IF NOT EXISTS hourly_sensor_data AS
SELECT 
    time_bucket('1 hour', time) AS bucket,
    sensor_id,
    AVG(value) AS avg_value_scaled
FROM sensor_data
GROUP BY bucket, sensor_id;

-- Refresh the materialized view manually or schedule it
REFRESH MATERIALIZED VIEW CONCURRENTLY hourly_sensor_data;

-- Example queries
SELECT 
    sd.time,
    sd.sensor_id,
    st.type_name,
    sd.value::NUMERIC / st.scale_factor AS actual_value
FROM sensor_data sd
JOIN sensors s ON sd.sensor_id = s.sensor_id
JOIN sensor_types st ON s.sensor_type_id = st.sensor_type_id;

SELECT 
    bucket,
    sd.sensor_id,
    st.type_name,
    avg_value_scaled / st.scale_factor AS avg_value
FROM hourly_sensor_data sd
JOIN sensors s ON sd.sensor_id = s.sensor_id
JOIN sensor_types st ON s.sensor_type_id = st.sensor_type_id;
