-- Reset script for aquaponics_db schema
/*
MIT License Notice
Copyright (c) 2024 Jeremy D. Gerdes <seakintruth@gmail.com>
See full license in the repository.

Script Version: V0.1 (Reset)
Author: Jeremy D. Gerdes
Email: seakintruth@gmail.com

This script removes all tables, indexes, and materialized views related to the aquaponics system schema.
Use with caution as it will delete all data and structures in tables, indexes, and views created by the setup script.
*/

DO $$
DECLARE
    table_name RECORD;
    view_name RECORD;
    index_name RECORD;
    job_id RECORD;
BEGIN
    -- Drop indexes first to avoid constraint errors
    FOR index_name IN 
        SELECT indexname FROM pg_indexes WHERE schemaname = 'public' AND indexname IN (
            'idx_sensor_type_id', 
            'idx_zone_id', 
            'idx_system_id', 
            'idx_hourly_sensor_data_bucket_sensor_id'
        )
    LOOP
        EXECUTE format('DROP INDEX IF EXISTS %I', index_name.indexname);
    END LOOP;

    -- Drop the materialized view
    FOR view_name IN 
        SELECT matviewname FROM pg_matviews WHERE schemaname = 'public' AND matviewname = 'hourly_sensor_data'
    LOOP
        EXECUTE format('DROP MATERIALIZED VIEW IF EXISTS %I', view_name.matviewname);
    END LOOP;

    -- Drop tables, this will cascade to drop related constraints like foreign keys
    FOR table_name IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename IN (
            'log', 
            'zone', 
            'system', 
            'sensor_type', 
            'sensor', 
            'sensor_datum', 
            'systemwide_alert'
        )
    LOOP
        EXECUTE format('DROP TABLE IF EXISTS %I CASCADE', table_name.tablename);
    END LOOP;

    -- Clean up any remaining cron jobs related to the schema
    FOR job_id IN 
        SELECT jobid FROM cron.job WHERE command LIKE 'INSERT INTO log (log_entry,log_category) VALUES (''status'',''up'');'
    LOOP
        PERFORM cron.unschedule(job_id.jobid);
    END LOOP;

    RAISE NOTICE 'All tables, indexes, views, and associated cron jobs have been dropped.';
END $$;