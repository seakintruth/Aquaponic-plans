-- sudo dnf install postgresql_faker_16.x86_64
-- Generate fake sensor data
INSERT INTO sensors (sensor_id, sensor_type_id, location, installation_date)
SELECT 
    faker.uuid(),
    st.sensor_type_id,
    faker.city(),
    faker.date_this_year()
FROM generate_series(1, 10) AS gs(i)
CROSS JOIN sensor_types st
-- Ensure we don't exceed the number of sensor types
WHERE gs.i <= (SELECT COUNT(*) FROM sensor_types);

-- Generate fake sensor readings
INSERT INTO sensor_data (time, sensor_id, value)
SELECT 
    faker.timestamp(),
    s.sensor_id,
    CASE
        WHEN st.type_name = 'temperature' THEN faker.number_between(100000, 400000)  -- 10.0 to 40.0 * 10000
        WHEN st.type_name = 'humidity' THEN faker.number_between(0, 100000)        -- 0.0 to 100.0 * 1000
        ELSE faker.number_between(1, 100000)                                       -- Example for other sensors
    END
FROM generate_series(1, 100) AS gs(i)
JOIN sensors s ON faker.number_between(1, (SELECT COUNT(*) FROM sensors)) = gs.i
JOIN sensor_types st ON s.sensor_type_id = st.sensor_type_id;

/*
Explanation:

    UUID for Sensor ID: Using faker.uuid() to generate unique identifiers for sensors.
    Location: faker.city() creates a fake city name for the sensor location.
    Installation Date: faker.date_this_year() generates a random date in the current year.
    Sensor Readings: 
        For temperature, we're generating a number between 10,0000 and 40,0000 (10°C to 40°C when divided by 10000).
        For humidity, it's between 0 and 100,000 (0% to 100% when divided by 1000).
        For other sensors, an arbitrary range is used. Adjust as needed for your sensor types.


Notes:

    Faker Functions: The faker extension might have different or additional functions than those listed here (like faker.name() for names or faker.text() for text). Check the documentation or use \dx in psql to list available functions if you have installed the extension.
    Data Consistency: If you need to ensure that the same sensor always has readings for the same type, you'll need to join with the sensors table in your data generation query, as shown above.
    Indexes and Performance: Remember that inserting a large amount of data can take time, especially if you have indexes on your tables. For large data sets, consider disabling triggers or constraints temporarily, or use bulk insert methods.
    Customization: You can customize the range or type of data generated by adjusting the CASE statement or using different faker functions based on your specific requirements.


This script should give you a start on populating your database with fake data to test or develop your application. Remember to adjust the scale factors and data ranges to match your actual sensor capabilities and needs.
*/
