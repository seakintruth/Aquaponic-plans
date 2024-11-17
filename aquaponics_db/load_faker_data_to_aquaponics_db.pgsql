

/*
MIT License Notice
Copyright (c) [Year] Jeremy D. Gerdes <seakintruth@gmail.com>
See full license in the repository.

Script Version: V0.3.0 - Updated to use aquaponics_db_fake schema for fake data.
Author: Jeremy D. Gerdes
Email: seakintruth@gmail.com
*/

/*
This script populates an aquaponics monitoring database with fake data for testing and demonstration purposes.
It uses the 'faker' PostgreSQL extension to generate realistic but fictitious data.
*/

-- Create schema for fake data if it doesn't exist
CREATE SCHEMA IF NOT EXISTS aquaponics_db_fake;

-- Function to set seed for random number generation based on entropy sources
CREATE OR REPLACE FUNCTION aquaponics_db_fake.set_seed_with_entropy()
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
SELECT aquaponics_db_fake.set_seed_with_entropy();

-- Zone Table Insertion
-- This block creates entries for different zones within the aquaponics system.
-- Each zone is given a random name and description.
INSERT INTO aquaponics_db_fake.zone (zone_name, description)
SELECT 
    faker.word() || ' Zone',  -- The '||' operator concatenates ' Zone' to a random word for the zone name.
    faker.sentence()  -- Generates a random sentence for the zone description.
FROM generate_series(1, 5);  -- Will insert 5 zones.

-- System Table Insertion
-- This creates entries for different systems or subsystems in the aquaponics setup.
-- Each system is randomly assigned as either Hydroponic or Electrical.
INSERT INTO aquaponics_db_fake.system (system_name, system_type)
SELECT 
    faker.job_field(),  -- Generates a random job-related term for the system name, e.g., 'Nutrient Dosing'.
    CASE WHEN random() > 0.5 THEN 'Hydroponic' ELSE 'Electrical' END  -- Randomly assigns system type.
FROM generate_series(1, 3);  -- Will insert 3 systems.

-- Sensor Type Table Insertion
-- Defines different types of sensors used in the system with their scale factor and unit of measurement.
INSERT INTO aquaponics_db_fake.sensor_type (type_name, scale_factor, unit)
VALUES 
    ('Temperature', 1000, 'Celsius'),  -- Temperature sensor with 0.001°C precision
    ('Humidity', 1000, 'Percent'),     -- Humidity sensor with 0.1% precision
    ('pH', 100, 'pH'),                 -- pH sensor with 0.01 pH unit precision
    ('EC', 10, 'mS/cm');               -- Electrical Conductivity sensor with 0.1 mS/cm precision

-- Sensor Table Insertion
-- Creates sensor entries with random associations to zones and systems.
INSERT INTO aquaponics_db_fake.sensor (sensor_id, sensor_type_id, zone_id, system_id, location, installation_date)
SELECT 
    faker.uuid(),  -- Generates a unique identifier for each sensor.
    (random() * 4)::INT + 1,  -- Assigns a random sensor type from 1 to 4.
    (random() * 5)::INT + 1,  -- Assigns a random zone from 1 to 5.
    (random() * 3)::INT + 1,  -- Assigns a random system from 1 to 3.
    faker.street_address(),  -- Provides a fake address for the sensor location.
    faker.date_between('2020-01-01', '2023-12-31')  -- Random installation date within the specified range.
FROM generate_series(1, 10);  -- Will insert 10 sensors.

-- Sensor Data Insertion
-- Generates fake sensor readings over a 10-day period.
INSERT INTO aquaponics_db_fake.sensor_datum (time, sensor_id, value)
SELECT 
    now() - (random() * interval '10 day'),  -- Random timestamp within the last 10 days.
    (SELECT sensor_id FROM aquaponics_db_fake.sensor ORDER BY random() LIMIT 1),  -- Randomly selects a sensor ID from the fake schema.
    CASE (SELECT sensor_type_id FROM aquaponics_db_fake.sensor WHERE sensor_id = sd.sensor_id)
        WHEN 1 THEN (random() * 40000)::INT -- Temperature: scale_factor is 1000, so value is in range 0-40°C
        WHEN 2 THEN (random() * 100000)::INT -- Humidity: scale_factor is 1000, so value is in range 0-100%
        WHEN 3 THEN (random() * 1400)::INT -- pH: scale_factor is 100, so value is in range 0-14 pH
        WHEN 4 THEN (random() * 500)::INT -- EC: scale_factor is 10, so value is in range 0-50 mS/cm
    END
FROM generate_series(1, 1000) AS sd; -- Inserts 1000 data points.

-- System-wide Alert Insertion
-- Generates fake alerts for the system, with each alert randomly linked to a sensor, zone, and system.
INSERT INTO aquaponics_db_fake.systemwide_alert (sensor_id, zone_id, system_id, alert_type, alert_message)
SELECT 
    (SELECT sensor_id FROM aquaponics_db_fake.sensor ORDER BY random() LIMIT 1),
    (random() * 5)::INT + 1,
    (random() * 3)::INT + 1,
    CASE WHEN random() > 0.5 THEN 'Warning' ELSE 'Critical' END,
    faker.sentence()  -- Generates a random sentence for the alert message.
FROM generate_series(1, 5);  -- Will insert 5 alerts.