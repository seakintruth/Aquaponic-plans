/*
MIT License Noticeflo
Copyright (c) 2024 Jeremy D. Gerdes <seakintruth@gmail.com>
See full license in the repository.

Script Version: V0.1.0
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
        job_id := cron_management.schedule_job('*/5 * * * *', 'INSERT INTO log (log_entry) VALUES (''up'',''status'');', 'DB_Status');

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'An error occurred: %', SQLERRM;
            RETURN;
    END;
    $$ LANGUAGE plpgsql;

    -- Call the main procedure
    PERFORM cron_management.manage_cron_jobs();

END $$;