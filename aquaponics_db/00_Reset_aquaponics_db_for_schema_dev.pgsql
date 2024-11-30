-- Reset script for aquaponics_db schema
/*
MIT License Notice
Copyright (c) 2024 Jeremy D. Gerdes <seakintruth@gmail.com>
See full license in the repository.

Script Version: V0.1.1 (Reset)
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
            'idx_area_id', 
            'idx_system_id', 
            'idx_hourly_sensor_data_bucket_sensor_id',
            'label_assignment.idx_label_assignment_entity',
            'label_assignment.label_assignment_pkey',
            'label_assignment.unique_label_assignment'
        )
    LOOP
        EXECUTE format('DROP INDEX IF EXISTS %I', index_name.indexname);
    END LOOP;

    -- Drop all materialized views
    FOR view_name IN 
        SELECT matviewname FROM pg_matviews WHERE schemaname = 'public' AND matviewname in ('hourly_sensor_data','minute_by_minute_last_24_hours','second_by_second_last_15_minutes')
    LOOP
        EXECUTE format('DROP MATERIALIZED VIEW IF EXISTS %I', view_name.matviewname);
    END LOOP;

    -- Drop tables, this will cascade to drop related constraints like foreign keys
    FOR table_name IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename IN (
            'log', 
            'sensor', 
            'geo_ref',
            'area', 
            'system', 
            'sensor_type', 
            'sensor_datum', 
            'systemwide_alert',
            'label',
            'label_assignment',
            'zone'
        )
    LOOP
        EXECUTE format('DROP TABLE IF EXISTS %I CASCADE', table_name.tablename);
    END LOOP;

    -- Drop the materialized views
    FOR view_name IN 
        SELECT matviewname FROM pg_matviews WHERE schemaname = 'public' AND matviewname IN (
            'second_by_second_last_15_minutes',
            'minute_by_minute_last_24_hours',
            'hourly_last_week'
        )
    LOOP
        EXECUTE format('DROP MATERIALIZED VIEW IF EXISTS %I', view_name.matviewname);
    END LOOP;

    -- Clean up any remaining cron jobs related to the schema
    FOR job_id IN 
        SELECT jobid FROM cron.job
    LOOP
        PERFORM cron.unschedule(job_id.jobid);
    END LOOP;

    RAISE NOTICE 'All tables, indexes, views, and associated cron jobs have been dropped.';
END $$;