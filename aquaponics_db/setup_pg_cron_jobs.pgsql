/*
This PL/pgSQL block will:

    - Check for the existence of the 'log' table.
    - Quit if the 'log' table if it doesn't exist, with a comment indicating it should created by setup_aquaponics_db.sql.
    - Schedule a job to run every 5 minutes to insert the status of aquaponics_db into the 'log' table.
    - Log the scheduling of this job in the 'log' table with a category of 'cron.schedule'.
    - Exit if the 'log' table does not exist.

Remember, if pg_cron doesn't find a job to run at the exact time specified (due to the minute boundary), it will run the job as soon as possible after that time. So, if you run this script at 14:32:45, the job might not execute exactly at 14:33:45 but rather at the start of the next minute, 14:34:00.
*/
DO $$
DECLARE
    job_row RECORD;  -- Declare job_row as RECORD
BEGIN
    -- Check if log table exists, if not, exit
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_class c
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public' AND c.relname = 'log'
    ) THEN
        RAISE EXCEPTION 'log table does not exist. Unable to proceed. Table log must be created by setup_aquaponics_db.sql';
    END IF;

    -- Unschedule all existing cron jobs
    FOR job_row IN SELECT jobid FROM cron.job
    LOOP
        -- job_row is already a record, so we can directly use job_row.jobid
        PERFORM cron.unschedule(job_row.jobid);
    END LOOP;
    INSERT INTO log (log_entry, log_category) VALUES ('All existing cron jobs have been unscheduled.', 'cron.unschedule_all');

    -- Schedule the job to run every 5 minutes
    INSERT INTO log (log_entry, log_category)
    SELECT 
        cron.schedule(
            '*/5 * * * *', 'INSERT INTO log (log_entry) VALUES (''up'',''status'');'
        ) AS log_entry,
        'cron.schedule' AS log_category;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'An error occurred: %', SQLERRM;
        -- Optionally, log the error to another table or perform cleanup here
        RETURN;  -- Exit the function
END $$;