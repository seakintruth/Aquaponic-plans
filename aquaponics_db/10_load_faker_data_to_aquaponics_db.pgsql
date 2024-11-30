/*
MIT License Notice
Copyright (c) 2024 Jeremy D. Gerdes <seakintruth@gmail.com>
See full license in the repository.

Script Version: V0.3.1 - Updated for development in the standard database with error handling.
Author: Jeremy D. Gerdes
Email: seakintruth@gmail.com
*/

/*
This script populates an aquaponics monitoring database with fake data for testing and demonstration purposes.
It uses the 'faker' PostgreSQL extension to generate realistic but fictitious data.
*/

DO $$
DECLARE
    error_message TEXT;
BEGIN
    -- Function to set seed for random number generation based on entropy sources
    CREATE OR REPLACE FUNCTION set_seed_with_entropy()
    RETURNS void AS $_$
    DECLARE
        -- Session ID (or a hash of it if it's too long)
        session_seed TEXT := substring(CAST(current_setting('application_name') AS TEXT), 1, 32);
        -- Machine info (e.g., hostname)
        --machine_seed TEXT := substring(inet_server_addr()::TEXT, 1, 32);  -- This will be the server's IP or hostname
        -- Current timestamp in microseconds
        time_seed BIGINT := EXTRACT(EPOCH FROM clock_timestamp()) * 1000000;
        -- Final seed value
        final_seed NUMERIC;
    BEGIN
        -- Convert string seeds to numeric values safely
        final_seed := (COALESCE(NULLIF(CAST(NULLIF(session_seed, '') AS BIGINT), 0), 1) +
                       time_seed) / 1000000000000000000 % 1;

        --COALESCE(NULLIF(CAST(NULLIF(machine_seed, '') AS BIGINT), 0), 1) +

        -- Set the seed for the random functions
        PERFORM setseed(final_seed);

        -- Log the seed for debugging or auditing
        RAISE NOTICE 'Random seed set to %', final_seed;
    EXCEPTION WHEN others THEN
        -- If there's an error setting the seed, use a fallback seed based on the current time
        PERFORM setseed(EXTRACT(EPOCH FROM clock_timestamp()) / 1000000000000000000 % 1);
        RAISE NOTICE 'Fallback seed used due to error: %', SQLERRM;
    END;
    $_$ LANGUAGE plpgsql SECURITY DEFINER;

    -- Call the function to set the seed before your INSERT statements
    BEGIN
        PERFORM set_seed_with_entropy();
    EXCEPTION WHEN others THEN
        error_message := 'Error setting seed: ' || SQLERRM;
        RAISE NOTICE '%', error_message;
        -- Continue execution even if seed setting fails, using a default seed
        PERFORM setseed(EXTRACT(EPOCH FROM clock_timestamp()) / 1000000000000000000 % 1);
    END;

    -- Area Table Insertion
    BEGIN
        INSERT INTO area (area_name, description)
        SELECT 
            faker.word() || ' area',
            faker.sentence()
        FROM generate_series(1, 5);
    EXCEPTION WHEN others THEN
        error_message := 'Error inserting into area table: ' || SQLERRM;
        RAISE NOTICE '%', error_message;
    END;

    -- System Table Insertion
    BEGIN
        INSERT INTO system (system_name, system_type)
        SELECT 
            faker.job_field(),
            CASE WHEN random() > 0.5 THEN 'Hydroponic' ELSE 'Electrical' END
        FROM generate_series(1, 3);
    EXCEPTION WHEN others THEN
        error_message := 'Error inserting into system table: ' || SQLERRM;
        RAISE NOTICE '%', error_message;
    END;

    -- Sensor Type Table Insertion
    BEGIN
        INSERT INTO sensor_type (type_name, scale_factor, unit, capture_after_delta_percent)
        VALUES 
            ('Temperature', 1000, 'Celsius', 1.0),  
            ('Humidity', 1000, 'Percent', 2.0),     
            ('pH', 100, 'pH', 0.5),                 
            ('EC', 10, 'mS/cm', 5.0);
    EXCEPTION WHEN others THEN
        error_message := 'Error inserting into sensor_type table: ' || SQLERRM;
        RAISE NOTICE '%', error_message;
    END;

    -- Sensor Table Insertion
    BEGIN
        INSERT INTO sensor (sensor_type_id, area_id, system_id, location, installation_date)
        SELECT 
            (random() * 4)::INT + 1,
            (random() * 5)::INT + 1,
            (random() * 3)::INT + 1,
            faker.street_address(),
            faker.date_between('2020-01-01', '2023-12-31')
        FROM generate_series(1, 10);
    EXCEPTION WHEN others THEN
        error_message := 'Error inserting into sensor table: ' || SQLERRM;
        RAISE NOTICE '%', error_message;
    END;

    -- Sensor Data Insertion
    BEGIN
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
    EXCEPTION WHEN others THEN
        error_message := 'Error inserting into sensor_datum table: ' || SQLERRM;
        RAISE NOTICE '%', error_message;
    END;

    -- System-wide Alert Insertion
    BEGIN
        INSERT INTO systemwide_alert (sensor_id, area_id, system_id, alert_type, alert_message)
        SELECT 
            (SELECT sensor_id FROM sensor ORDER BY random() LIMIT 1),
            (random() * 5)::INT + 1,
            (random() * 3)::INT + 1,
            CASE WHEN random() > 0.5 THEN 'Warning' ELSE 'Critical' END,
            faker.sentence()
        FROM generate_series(1, 5);
    EXCEPTION WHEN others THEN
        error_message := 'Error inserting into systemwide_alert table: ' || SQLERRM;
        RAISE NOTICE '%', error_message;
    END;

    -- Label Table Insertion
    BEGIN
        INSERT INTO label (label_name, description)
        SELECT 
            faker.word(),
            faker.sentence()
        FROM generate_series(1, 3);
    EXCEPTION WHEN others THEN
        error_message := 'Error inserting into label table: ' || SQLERRM;
        RAISE NOTICE '%', error_message;
    END;

    -- Label Assignment Insertion
    BEGIN
        INSERT INTO label_assignment (entity_id, entity_type, label_id)
        SELECT 
            (random() * 10)::INT + 1,  -- Sensor IDs range from 1 to 10
            'sensor',
            (random() * 3)::INT + 1  -- Label IDs range from 1 to 3
        FROM generate_series(1, 10);
    EXCEPTION WHEN others THEN
        error_message := 'Error inserting into label_assignment table: ' || SQLERRM;
        RAISE NOTICE '%', error_message;
    END;

    -- Refresh Materialized Views after inserting data
    BEGIN
        REFRESH MATERIALIZED VIEW CONCURRENTLY hourly_sensor_data;
        REFRESH MATERIALIZED VIEW CONCURRENTLY minute_by_minute_last_24_hours;
        REFRESH MATERIALIZED VIEW CONCURRENTLY hourly_last_week;
        REFRESH MATERIALIZED VIEW CONCURRENTLY second_by_second_last_15_minutes;
    EXCEPTION WHEN others THEN
        error_message := 'Error refreshing materialized views: ' || SQLERRM;
        RAISE NOTICE '%', error_message;
    END;

    RAISE NOTICE 'Fake data loading completed.';

EXCEPTION WHEN others THEN
    RAISE NOTICE 'An error occurred in the main script execution: %', SQLERRM;
END $$;