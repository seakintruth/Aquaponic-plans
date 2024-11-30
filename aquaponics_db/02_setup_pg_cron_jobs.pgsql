/*
MIT License Notice
Copyright (c) 2024 Jeremy D. Gerdes <seakintruth@gmail.com>
See full license in the repository.

Script Version: V0.2
Author: Jeremy D. Gerdes
Email: seakintruth@gmail.com
*/

DO $$
DECLARE
    job_id INTEGER;
    job_count INTEGER;
BEGIN
    -- Create the schema if it doesn't exist
    CREATE SCHEMA IF NOT EXISTS cron_management;

    -- Check if log table exists
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'log' AND schemaname = 'public') THEN
        RAISE EXCEPTION 'log table does not exist. Unable to proceed. Table log must be created by setup_aquaponics_db.sql';
    END IF;

    -- Unschedule all cron jobs
    SELECT COUNT(*) INTO job_count FROM cron.job;
    IF job_count > 0 THEN
        FOR job_id IN SELECT jobid FROM cron.job
        LOOP
            PERFORM cron.unschedule(job_id);
        END LOOP;
        INSERT INTO log (log_entry, log_category) VALUES ('All existing cron jobs have been unscheduled.', 'cron.unschedule_all');
    ELSE
        INSERT INTO log (log_entry, log_category) VALUES ('No cron jobs found to unschedule.', 'cron.unschedule_all');
    END IF;
    -- Schedule jobs
    -- Schedule MV_second_by_second_last_15_minutes
    SELECT jobid INTO job_id FROM cron.job WHERE command = 'REFRESH MATERIALIZED VIEW CONCURRENTLY second_by_second_last_15_minutes;';
    IF job_id IS NOT NULL THEN
        PERFORM cron.unschedule(job_id);
        INSERT INTO log (log_entry, log_category) VALUES ('Job MV_second_by_second_last_15_minutes unscheduled', 'cron.unschedule');
    END IF;
    job_id := cron.schedule('*/1 * * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY second_by_second_last_15_minutes;');
    INSERT INTO log (log_entry, log_category) VALUES (format('Job MV_second_by_second_last_15_minutes scheduled with job ID: %s', job_id), 'cron.schedule');

    -- Schedule DB_Status
    SELECT jobid INTO job_id FROM cron.job WHERE command = 'INSERT INTO log (log_entry) VALUES (''up'',''status'');';
    IF job_id IS NOT NULL THEN
        PERFORM cron.unschedule(job_id);
        INSERT INTO log (log_entry, log_category) VALUES ('Job DB_Status unscheduled', 'cron.unschedule');
    END IF;
    job_id := cron.schedule('*/10 * * * *', 'INSERT INTO log (log_entry) VALUES (''up'',''status'');');
    INSERT INTO log (log_entry, log_category) VALUES (format('Job DB_Status scheduled with job ID: %s', job_id), 'cron.schedule');

    -- Schedule MV_minute_by_minute_last_24_hours
    SELECT jobid INTO job_id FROM cron.job WHERE command = 'REFRESH MATERIALIZED VIEW CONCURRENTLY minute_by_minute_last_24_hours;';
    IF job_id IS NOT NULL THEN
        PERFORM cron.unschedule(job_id);
        INSERT INTO log (log_entry, log_category) VALUES ('Job MV_minute_by_minute_last_24_hours unscheduled', 'cron.unschedule');
    END IF;
    job_id := cron.schedule('*/5 * * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY minute_by_minute_last_24_hours;');
    INSERT INTO log (log_entry, log_category) VALUES (format('Job MV_minute_by_minute_last_24_hours scheduled with job ID: %s', job_id), 'cron.schedule');

    -- Schedule MV_hourly_last_week
    SELECT jobid INTO job_id FROM cron.job WHERE command = 'REFRESH MATERIALIZED VIEW CONCURRENTLY hourly_last_week;';
    IF job_id IS NOT NULL THEN
        PERFORM cron.unschedule(job_id);
        INSERT INTO log (log_entry, log_category) VALUES ('Job MV_hourly_last_week unscheduled', 'cron.unschedule');
    END IF;
    job_id := cron.schedule('2 * * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY hourly_last_week;');
    INSERT INTO log (log_entry, log_category) VALUES (format('Job MV_hourly_last_week scheduled with job ID: %s', job_id), 'cron.schedule');

    -- Schedule Sensor Data Cleanup
    SELECT jobid INTO job_id FROM cron.job WHERE jobname = 'sensor_data_cleanup';
    IF job_id IS NOT NULL THEN
        PERFORM cron.unschedule(job_id);
        INSERT INTO log (log_entry, log_category) VALUES ('Job sensor_data_cleanup unscheduled', 'cron.unschedule');
    END IF;
    job_id := cron.schedule('0 * * * *', $_$
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
    $_$);
    INSERT INTO log (log_entry, log_category) VALUES (format('Job sensor_data_cleanup scheduled with job ID: %s', job_id), 'cron.schedule');

    -- Handle any exceptions
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'An error occurred: %', SQLERRM;
END $$;