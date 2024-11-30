import psycopg2
from psycopg2 import sql
from faker import Faker
import os
import random
from datetime import datetime, timedelta

# Initialize Faker
fake = Faker()

# Database connection details
db_name = "aquaponics_db"
db_user = "aquaponics"
# Password is kept in a file for security, format: "*:*:*:*:{password}"
with open(os.path.expanduser('~/.pgpass'), 'r') as file:
    _, _, _, _, db_password = file.read().strip().split(':')

# Function to set seed for random number generation
def set_seed_with_entropy():
    # Both should be of the same type for addition
    session_seed = hash(str(os.getpid()) + os.environ.get('USERNAME', 'default_user'))
    time_seed = int(datetime.now().timestamp() * 1000000)
    final_seed = ((session_seed + time_seed) / 1000000000000000000) % 1
    random.seed(final_seed)
    print(f'Random seed set to {final_seed}')
    
# Connect to the database
try:
    conn = psycopg2.connect(
        dbname=db_name,
        user=db_user,
        password=db_password,
        host="localhost"  # Adjust if your PostgreSQL server isn't on localhost
    )
    cur = conn.cursor()
    set_seed_with_entropy()

    # Area Table Insertion
    for _ in range(5):
        cur.execute(sql.SQL("INSERT INTO area (area_name, description) VALUES (%s, %s)"),
                    (fake.word() + " area", fake.sentence()))

    # System Table Insertion
    for _ in range(3):
        cur.execute(sql.SQL("INSERT INTO system (system_name, system_type) VALUES (%s, %s)"),
                    (fake.job(), "Hydroponic" if random.random() > 0.5 else "Electrical"))

    # Sensor Type Table Insertion (hardcoded values as in your original script)
    sensor_types = [
        ('Temperature', 1000, 'Celsius', 1.0),
        ('Humidity', 1000, 'Percent', 2.0),
        ('pH', 100, 'pH', 0.5),
        ('EC', 10, 'mS/cm', 5.0)
    ]
    for type_name, scale_factor, unit, capture_after_delta_percent in sensor_types:
        cur.execute(sql.SQL("INSERT INTO sensor_type (type_name, scale_factor, unit, capture_after_delta_percent) VALUES (%s, %s, %s, %s)"),
                    (type_name, scale_factor, unit, capture_after_delta_percent))

    # Sensor Table Insertion
    for _ in range(10):
        cur.execute(sql.SQL("""
            INSERT INTO sensor (sensor_type_id, area_id, system_id, location, installation_date) 
            VALUES (%s, %s, %s, %s, %s)
        """), (random.randint(1, 4), random.randint(1, 5), random.randint(1, 3), fake.street_address(), fake.date_between(start_date='-3y', end_date='today')))

    # Sensor Data Insertion
    for _ in range(1000):
        sensor_id = random.randint(1, 10)  # Assuming 10 sensors were created
        sensor_type_id = random.randint(1, 4)
        time = datetime.now() - timedelta(days=random.randint(0, 10))
        if sensor_type_id == 1:  # Temperature
            value = random.randint(0, 40000)
        elif sensor_type_id == 2:  # Humidity
            value = random.randint(0, 100000)
        elif sensor_type_id == 3:  # pH
            value = random.randint(0, 1400)
        else:  # EC
            value = random.randint(0, 500)
        cur.execute(sql.SQL("INSERT INTO sensor_datum (time, sensor_id, value) VALUES (%s, %s, %s)"),
                    (time, sensor_id, value))

    # System-wide Alert Insertion
    for _ in range(5):
        cur.execute(sql.SQL("""
            INSERT INTO systemwide_alert (sensor_id, area_id, system_id, alert_type, alert_message)
            VALUES (%s, %s, %s, %s, %s)
        """), (random.randint(1, 10), random.randint(1, 5), random.randint(1, 3), 
               "Warning" if random.random() > 0.5 else "Critical", fake.sentence()))

    # Label Table Insertion
    for _ in range(3):
        cur.execute(sql.SQL("INSERT INTO label (label_name, description) VALUES (%s, %s)"),
                    (fake.word(), fake.sentence()))

    # Label Assignment Insertion
    for _ in range(10):
        cur.execute(sql.SQL("INSERT INTO label_assignment (entity_id, entity_type, label_id) VALUES (%s, %s, %s)"),
                    (random.randint(1, 10), 'sensor', random.randint(1, 3)))

    # Refresh Materialized Views (this is PostgreSQL specific, might need adjustments if not all views exist)
    views = ['hourly_sensor_data', 'minute_by_minute_last_24_hours', 'hourly_last_week', 'second_by_second_last_15_minutes']
    for view in views:
        try:
            cur.execute(sql.SQL("REFRESH MATERIALIZED VIEW CONCURRENTLY {}").format(sql.Identifier(view)))
        except psycopg2.Error as e:
            print(f"Error refreshing materialized view {view}: {e}")

    conn.commit()
    print('Fake data loading completed.')

except Exception as e:
    print(f'An error occurred: {e}')
finally:
    if 'conn' in locals():
        conn.close()