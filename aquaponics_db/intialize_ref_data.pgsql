/*
MIT License Notice
Copyright (c) [Year] Jeremy D. Gerdes <seakintruth@gmail.com>
See full license in the repository.

Script Version: V0.1.4 - Updated to include weather station and home automation sensor types.
Author: Jeremy D. Gerdes
Email: seakintruth@gmail.com
*/

-- Insert log for the beginning of data initialization
INSERT INTO log (log_entry, log_category) VALUES ('Initializing::Reference and Example Data','SETUP');

-- Initialize geo_ref table
INSERT INTO geo_ref (anchor_lat, anchor_lon, anchor_elevation, anchor_description) 
VALUES (
    36.81035635235504, 
    -76.17849335514821, 
    10.584,
    '924 Thompson Way, Virginia Beach, VA, 23464, USA'
)
ON CONFLICT (anchor_lat, anchor_lon) DO NOTHING;

-- Initialize zone table
INSERT INTO zone (zone_name, description)
SELECT 
    v::TEXT,
    CASE v
        WHEN 'Greenhouse Nursery' THEN 'Area for growing seedlings'
        WHEN 'Main Aquaponics' THEN 'Primary growing area'
        WHEN 'Fish Tanks' THEN 'Holding tanks for fish'
        WHEN 'Compost Area' THEN 'Composting station'
    END AS description
FROM (VALUES ('Greenhouse Nursery'), ('Main Aquaponics'), ('Fish Tanks'), ('Compost Area')) AS zones(v)
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
        WHEN 'Weather Station' THEN 'Meteorological'
        WHEN 'Home Automation' THEN 'Automation'
    END AS system_type
FROM (VALUES ('Water Management'), ('Electrical'), ('Temperature Control'), ('Lighting'), ('Weather Station'), ('Home Automation')) AS systems(v)
WHERE NOT EXISTS (SELECT 1 FROM system WHERE system_name = v);

-- Initialize sensor_type table with all types including weather station and home automation
INSERT INTO sensor_type (type_name, scale_factor, unit)
SELECT 
    v::TEXT,
    CASE v
        -- Aquaponics Sensors
        WHEN 'Temperature' THEN 10
        WHEN 'pH' THEN 100
        WHEN 'Water Level' THEN 1
        WHEN 'Light Intensity' THEN 1
        WHEN 'Dissolved Oxygen' THEN 100
        WHEN 'Conductivity' THEN 10
        WHEN 'Nitrate' THEN 1
        WHEN 'Ammonia' THEN 100
        WHEN 'Turbidity' THEN 1
        WHEN 'Salinity' THEN 10
        WHEN 'Total Dissolved Solids' THEN 1
        WHEN 'CO2 Concentration' THEN 10
        WHEN 'Humidity' THEN 10
        WHEN 'Pressure' THEN 1
        WHEN 'Flow Rate' THEN 10
        WHEN 'Nitrite' THEN 1
        WHEN 'ChF Pattern' THEN 1
        WHEN 'Barometric Pressure' THEN 100
        WHEN 'Air Flow' THEN 10
        WHEN 'Feed Weight' THEN 10
        WHEN 'Vibration Sensor' THEN 1000
        WHEN 'Power Draw' THEN 1
        WHEN 'Light Sensor' THEN 1
        -- Weather Station Sensors
        WHEN 'Wind Speed' THEN 10
        WHEN 'Wind Direction' THEN 1
        WHEN 'Rain Gauge' THEN 1
        WHEN 'Solar Radiation' THEN 1
        WHEN 'UV Index' THEN 10
        WHEN 'Leaf Wetness' THEN 1
        -- Home Automation Sensors
        WHEN 'Motion Detection' THEN 1
        WHEN 'Door/Window Sensor' THEN 1
        WHEN 'Smoke Detector' THEN 1
        WHEN 'Temperature (Home)' THEN 10
        WHEN 'Humidity (Home)' THEN 10
        WHEN 'Occupancy Sensor' THEN 1
        WHEN 'Sound Level' THEN 10
    END AS scale_factor,
    CASE v
        -- Aquaponics Sensors
        WHEN 'Temperature' THEN '°C'
        WHEN 'pH' THEN 'pH'
        WHEN 'Water Level' THEN 'cm'
        WHEN 'Light Intensity' THEN 'lux'
        WHEN 'Dissolved Oxygen' THEN 'mg/L'
        WHEN 'Conductivity' THEN 'µS/cm'
        WHEN 'Nitrate' THEN 'mg/L'
        WHEN 'Ammonia' THEN 'mg/L'
        WHEN 'Turbidity' THEN 'NTU'
        WHEN 'Salinity' THEN 'ppt'
        WHEN 'Total Dissolved Solids' THEN 'ppm'
        WHEN 'CO2 Concentration' THEN 'ppm'
        WHEN 'Humidity' THEN '%'
        WHEN 'Pressure' THEN 'kPa'
        WHEN 'Flow Rate' THEN 'L/min'
        WHEN 'Nitrite' THEN 'mg/L'
        WHEN 'ChF Pattern' THEN 'relative units'
        WHEN 'Barometric Pressure' THEN 'hPa'
        WHEN 'Air Flow' THEN 'm/s'
        WHEN 'Feed Weight' THEN 'g'
        WHEN 'Vibration Sensor' THEN 'Hz'
        WHEN 'Power Draw' THEN 'W'
        WHEN 'Light Sensor' THEN 'lux'
        -- Weather Station Sensors
        WHEN 'Wind Speed' THEN 'm/s'
        WHEN 'Wind Direction' THEN 'degrees'
        WHEN 'Rain Gauge' THEN 'mm'
        WHEN 'Solar Radiation' THEN 'W/m²'
        WHEN 'UV Index' THEN 'UV Index'
        WHEN 'Leaf Wetness' THEN 'hours'
        -- Home Automation Sensors
        WHEN 'Motion Detection' THEN 'binary'
        WHEN 'Door/Window Sensor' THEN 'binary'
        WHEN 'Smoke Detector' THEN 'binary'
        WHEN 'Temperature (Home)' THEN '°C'
        WHEN 'Humidity (Home)' THEN '%'
        WHEN 'Occupancy Sensor' THEN 'binary'
        WHEN 'Sound Level' THEN 'dB'
    END AS unit
FROM (VALUES 
    ('Temperature'), ('pH'), ('Water Level'), ('Light Intensity'), ('Dissolved Oxygen'),
    ('Conductivity'), ('Nitrate'), ('Ammonia'), ('Turbidity'), ('Salinity'),
    ('Total Dissolved Solids'), ('CO2 Concentration'), ('Humidity'), ('Pressure'), ('Flow Rate'),
    ('Nitrite'), ('ChF Pattern'), ('Barometric Pressure'), ('Air Flow'), ('Feed Weight'),
    ('Vibration Sensor'), ('Power Draw'), ('Light Sensor'),
    -- Weather Station Sensors
    ('Wind Speed'), ('Wind Direction'), ('Rain Gauge'), ('Solar Radiation'), ('UV Index'), ('Leaf Wetness'),
    -- Home Automation Sensors
    ('Motion Detection'), ('Door/Window Sensor'), ('Smoke Detector'), ('Temperature (Home)'), ('Humidity (Home)'),
    ('Occupancy Sensor'), ('Sound Level')
) AS types(v)
WHERE NOT EXISTS (SELECT 1 FROM sensor_type WHERE type_name = v);

-- Insert log for completion of data initialization
INSERT INTO log (log_entry, log_category) VALUES ('Completed::Reference and Example Data','SETUP');
