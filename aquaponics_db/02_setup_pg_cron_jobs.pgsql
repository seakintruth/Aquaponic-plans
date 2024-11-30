/*
MIT License Noticeflo
Copyright (c) 2024 Jeremy D. Gerdes <seakintruth@gmail.com>
See full license in the repository.

Script Version: V0.1.1
Author: Jeremy D. Gerdes
Email: seakintruth@gmail.com
*/

DO $$
DECLARE
    job_id INTEGER;
BEGIN
    -- Create the schema if it doesn't exist
    CREATE SCHEMA IF NOT EXISTS cron_management;

    -- Function to check if log table exists
    CREATE OR REPLACE FUNCTION cron_management.check_log_table_exists()
    RETURNS BOOLEAN AS $$
    BEGIN
        RETURN EXISTS (SELECT FROM pg_tables WHERE tablename = 'log' AND schemaname = 'public');
    END;
    $$ LANGUAGE plpgsql;

    -- Function to unschedule all cron jobs
    CREATE OR REPLACE FUNCTION cron_management.unschedule_all_jobs()
    RETURNS VOID AS $$
    BEGIN
        FOR job_row IN SELECT jobid FROM cron.job
        LOOP
            PERFORM cron.unschedule(job_row.jobid);
        END LOOP;
        INSERT INTO log (log_entry, log_category) VALUES ('All existing cron jobs have been unscheduled.', 'cron.unschedule_all');
    END;
    $$ LANGUAGE plpgsql;

    -- Function to schedule a single job with logging
    CREATE OR REPLACE FUNCTION cron_management.schedule_job(
        job_schedule TEXT,
        job_command TEXT,
        job_name TEXT
    )
    RETURNS INTEGER AS $$
    DECLARE
        job_id INTEGER;
    BEGIN
        -- Unschedule the job if it already exists
        SELECT jobid INTO job_id FROM cron.job WHERE command = job_command;
        IF job_id IS NOT NULL THEN
            PERFORM cron.unschedule(job_id);
            INSERT INTO log (log_entry, log_category) VALUES ('Job ' || job_name || ' unscheduled', 'cron.unschedule');
        END IF;

        -- Schedule the job
        job_id := cron.schedule(job_schedule, job_command);
        INSERT INTO log (log_entry, log_category)
        VALUES (format('Job %s scheduled with job ID: %s', job_name, job_id), 'cron.schedule');

        RETURN job_id;
    END;
    $$ LANGUAGE plpgsql;

    -- Main procedure to manage cron jobs
    CREATE OR REPLACE FUNCTION cron_management.manage_cron_jobs()
    RETURNS VOID AS $$
    BEGIN
        IF NOT cron_management.check_log_table_exists() THEN
            RAISE EXCEPTION 'log table does not exist. Unable to proceed. Table log must be created by setup_aquaponics_db.sql';
        END IF;

        PERFORM cron_management.unschedule_all_jobs();

        -- Schedule jobs here 
        job_id := cron_management.schedule_job('*/1 * * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY second_by_second_last_15_minutes;', 'MV_second_by_second_last_15_minutes');
        job_id := cron_management.schedule_job('*/10 * * * *', 'INSERT INTO log (log_entry) VALUES (''up'',''status'');', 'DB_Status');
        job_id := cron_management.schedule_job('*/5 * * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY minute_by_minute_last_24_hours;', 'MV_minute_by_minute_last_24_hours');
        job_id := cron_management.schedule_job('2 * * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY hourly_last_week;', 'MV_hourly_last_week');

        -- Cron Job for Sensor Data Cleanup
        job_id := cron_management.schedule_job('0 * * * *', $$
            WITH last_run AS (
                SELECT 
                    COALESCE(MAX(end_time), now() - INTERVAL '1 hour') AS last_run_time
                FROM cron.job_run_details 
                WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'sensor_data_cleanup')
                AND status = 'succeeded'
            ),
            -- Keep at least one record per hour per sensor
            keep_one_per_hour AS (
                SELECT DISTINCT ON (sensor_id) 
                    sensor_id, 
                    MAX(time) AS keep_time
                FROM sensor_datum 
                WHERE time >= (SELECT last_run_time FROM last_run)
                GROUP BY sensor_id, date_trunc('hour', time)
            )
            DELETE FROM sensor_datum sd
            WHERE NOT EXISTS (
                SELECT 1 FROM keep_one_per_hour ko
                WHERE ko.sensor_id = sd.sensor_id 
                AND ko.keep_time = sd.time
            )
            AND NOT EXISTS (
                SELECT 1 FROM sensor_datum sd2 
                WHERE sd2.sensor_id = sd.sensor_id 
                AND sd2.time > (SELECT last_run_time FROM last_run)
                AND sd2.time = (
                    SELECT MAX(time) 
                    FROM sensor_datum 
                    WHERE sensor_id = sd.sensor_id 
                    AND time < sd.time
                )
                AND (
                    ABS(sd.value - sd2.value) * 100.0 / GREATEST(sd2.value, 1) > (
                        SELECT st.capture_after_delta_percent
                        FROM sensor s
                        JOIN sensor_type st ON s.sensor_type_id = st.sensor_type_id
                        WHERE s.sensor_id = sd.sensor_id
                    )
                    OR sd2.time IS NULL 
                )
            )
            AND sd.time < (SELECT last_run_time FROM last_run);
        $$, 'sensor_data_cleanup');

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'An error occurred: %', SQLERRM;
            RETURN;
    END;
    $$ LANGUAGE plpgsql;

    -- Call the main procedure
    PERFORM cron_management.manage_cron_jobs();

END $$;