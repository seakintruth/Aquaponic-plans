/*
MIT License Notice
Copyright (c) 2024 Jeremy D. Gerdes <seakintruth@gmail.com>
See full license in the repository.

Script Version: V0.3.1 - Updated for development in the standard database.
Author: Jeremy D. Gerdes
Email: seakintruth@gmail.com
*/

/*
This script populates an aquaponics monitoring database with fake data for testing and demonstration purposes.
It uses the 'faker' PostgreSQL extension to generate realistic but fictitious data.
*/

-- Function to set seed for random number generation based on entropy sources
CREATE OR REPLACE FUNCTION set_seed_with_entropy()
RETURNS void AS $$
DECLARE
    -- Session ID (or a hash of it if it's too long)
    session_seed TEXT := substring(CAST(current_setting('application_name') AS TEXT), 1, 32);
    -- Machine info (e.g., hostname)
    machine_seed TEXT := substring(inet_server_addr()::TEXT, 1, 32);  -- This will be the server's IP or hostname
    -- Current timestamp in microseconds
    time_seed BIGINT := EXTRACT(EPOCH FROM clock_timestamp()) * 1000000;
    -- Additional entropy from random bytes (if available)
    entropy_seed TEXT := NULL;
    -- Final seed value
    final_seed NUMERIC;
BEGIN
    -- Check if we can get entropy from pg_read_file
    -- This is not guaranteed to work, depends on server configuration
    IF has_function_privilege('pg_read_file(text,bigint)', 'execute') THEN
        -- Changed to get 8 bytes from /dev/urandom
        entropy_seed := pg_read_file('/dev/urandom', 8); 
    ELSE
        -- Fallback if pg_read_file isn't available
        -- We use a simple hash of session and machine info as entropy
        entropy_seed := substring(CAST(MD5(session_seed || machine_seed) AS TEXT), 1, 8);
    END IF;

    -- Combine all sources to create a seed
    final_seed := (CAST(CAST(session_seed AS BIGINT) + CAST(machine_seed AS BIGINT) + time_seed AS NUMERIC) / 1000000000000000000) % 1;

    -- Set the seed for the random functions
    PERFORM setseed(final_seed);

    -- Log the seed for debugging or auditing
    RAISE NOTICE 'Random seed set to %', final_seed;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Call the function to set the seed before your INSERT statements
SELECT set_seed_with_entropy();

-- Area Table Insertion
INSERT INTO area (area_name, description)
SELECT 
    faker.word() || ' area',
    faker.sentence()
FROM generate_series(1, 5);

-- System Table Insertion
INSERT INTO system (system_name, system_type)
SELECT 
    faker.job_field(),
    CASE WHEN random() > 0.5 THEN 'Hydroponic' ELSE 'Electrical' END
FROM generate_series(1, 3);

-- Sensor Type Table Insertion
-- Added capture_after_delta_percent for deviation logging
INSERT INTO sensor_type (type_name, scale_factor, unit, capture_after_delta_percent)
VALUES 
    ('Temperature', 1000, 'Celsius', 1.0),  
    ('Humidity', 1000, 'Percent', 2.0),     
    ('pH', 100, 'pH', 0.5),                 
    ('EC', 10, 'mS/cm', 5.0);

-- Sensor Table Insertion
INSERT INTO sensor (sensor_type_id, area_id, system_id, location, installation_date)
SELECT 
    (random() * 4)::INT + 1,
    (random() * 5)::INT + 1,
    (random() * 3)::INT + 1,
    faker.street_address(),
    faker.date_between('2020-01-01', '2023-12-31')
FROM generate_series(1, 10);

-- Sensor Data Insertion
-- Adjusted to reflect the new sensor data logic where deviation is considered
INSERT INTO sensor_datum (time, sensor_id, value)
SELECT 
    now() - (random() * interval '10 day'),
    (SELECT sensor_id FROM sensor ORDER BY random() LIMIT 1),
    CASE (SELECT sensor_type_id FROM sensor WHERE sensor_id = sd.sensor_id)
        WHEN 1 THEN (random() * 40000)::INT -- Temperature
        WHEN 2 THEN (random() * 100000)::INT -- Humidity
        WHEN 3 THEN (random() * 1400)::INT -- pH
        WHEN 4 THEN (random() * 500)::INT -- EC
    END
FROM generate_series(1, 1000) AS sd;

-- System-wide Alert Insertion
INSERT INTO systemwide_alert (sensor_id, area_id, system_id, alert_type, alert_message)
SELECT 
    (SELECT sensor_id FROM sensor ORDER BY random() LIMIT 1),
    (random() * 5)::INT + 1,
    (random() * 3)::INT + 1,
    CASE WHEN random() > 0.5 THEN 'Warning' ELSE 'Critical' END,
    faker.sentence()
FROM generate_series(1, 5);

-- Label Table Insertion
INSERT INTO label (label_name, description)
SELECT 
    faker.word(),
    faker.sentence()
FROM generate_series(1, 3);

-- Label Assignment Insertion
INSERT INTO label_assignment (entity_id, entity_type, label_id)
SELECT 
    (random() * 10)::INT + 1,  -- Sensor IDs range from 1 to 10
    'sensor',
    (random() * 3)::INT + 1  -- Label IDs range from 1 to 3
FROM generate_series(1, 10);

-- Refresh Materialized Views after inserting data
REFRESH MATERIALIZED VIEW CONCURRENTLY hourly_sensor_data;
REFRESH MATERIALIZED VIEW CONCURRENTLY minute_by_minute_last_24_hours;
REFRESH MATERIALIZED VIEW CONCURRENTLY hourly_last_week;
REFRESH MATERIALIZED VIEW CONCURRENTLY second_by_second_last_15_minutes;

RAISE NOTICE 'Fake data loading completed for standard database.';