/*
MIT License Notice
Copyright (c) 2024 Jeremy D. Gerdes <seakintruth@gmail.com>
See full license in the repository.

Script Version: V0.1.0 - Updated to use aquaponics_db_fake schema for fake data.
Author: Jeremy D. Gerdes
Email: seakintruth@gmail.com
*/

-- Insert log
INSERT INTO log (log_entry,log_category) VALUES ('Initializing::Reference and Example Data','SETUP');

-- Insert the single anchor point
INSERT INTO geo_ref (anchor_lat, anchor_lon, anchor_elevation, anchor_description) 
    -- Use the coordinates you've determined as the southwest anchor
    -- lattitude, logitude, and elevation in meters.
    VALUES (
        36.81035635235504, 
        -76.17849335514821, 
        10.584,
        '924 Thompson Way, Virginia Beach, VA, 23464, USA'
    )
    ON CONFLICT (anchor_lat, anchor_lon) DO NOTHING;
    -- This ensures uniqueness based on lat and lon, not anchor_id


-- Initialize zone table
INSERT INTO zone (zone_name, description)
SELECT 
    v::TEXT,
    CASE v
        WHEN 'Greenhouse Nursery' THEN 'Area for growing seedlings above the rainwater collection tank'
        WHEN 'Main Aquaponics' THEN 'Primary growing area internal to the 8 x 22 ft shed'
        WHEN 'External Filtration' THEN 'External filtration and sump pump'
        WHEN 'Rainwater Collection Tank' THEN 'Holding tanks for fish and makeup water for main aquaponics'
        WHEN 'Compost Area' THEN 'Composting station'
        WHEN 'Fermeculture Area' THEN 'Fermeculture station'
    END AS description
FROM (VALUES ('Greenhouse Nursery'), ('Main Aquaponics'), ('External Filtration'), ('Rainwater Collection Tank'), ('Compost Area'),('Fermeculture Area')) AS zones(v)
WHERE NOT EXISTS (SELECT 1 FROM zone WHERE zone_name = v);

-- Initialize system table
INSERT INTO system (system_name, system_type)
SELECT 
    v::TEXT,
    CASE v
        WHEN 'Water Management' THEN 'Hydraulic'
        WHEN 'Electrical' THEN 'Power'
        WHEN 'Temperature Control' THEN 'Environmental'
        WHEN 'Lighting' THEN 'Environmental'
    END AS system_type
FROM (VALUES ('Water Management'), ('Electrical'), ('Temperature Control'), ('Lighting')) AS systems(v)
WHERE NOT EXISTS (SELECT 1 FROM system WHERE system_name = v);

-- Initialize sensor_type table
INSERT INTO sensor_type (type_name, scale_factor, unit)
SELECT 
    v::TEXT,
    CASE v
        WHEN 'Temperature' THEN 10
        WHEN 'pH' THEN 100
        WHEN 'Water Level' THEN 1
        WHEN 'Light Intensity' THEN 1
        WHEN 'Dissolved Oxygen' THEN 100
    END AS scale_factor,
    CASE v
        WHEN 'Temperature' THEN '°C'
        WHEN 'pH' THEN 'pH'
        WHEN 'Water Level' THEN 'cm'
        WHEN 'Light Intensity' THEN 'lux'
        WHEN 'Dissolved Oxygen' THEN 'mg/L'
    END AS unit
FROM (VALUES ('Temperature'), ('pH'), ('Water Level'), ('Light Intensity'), ('Dissolved Oxygen')) AS types(v)
WHERE NOT EXISTS (SELECT 1 FROM sensor_type WHERE type_name = v);

-- Insert log
INSERT INTO log (log_entry,log_category) VALUES ('Completed::Reference and Example Data','SETUP');