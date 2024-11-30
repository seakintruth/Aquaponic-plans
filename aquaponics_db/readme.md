# Aquaponics Database Schema Setup

## Overview

This project includes scripts for setting up, populating, and managing an aquaponics system database using PostgreSQL with TimescaleDB for time-series data. The setup involves creating tables, materialized views, and automated jobs for data management and maintenance.

## Project Structure

- **wipe_and_rebuild.sh**: Main Bash script to orchestrate the execution of SQL and Python scripts.
- **00_Reset_aquaponics_db_for_schema_dev.pgsql**: SQL script to reset the database by dropping all tables, indexes, views, and cron jobs related to the aquaponics schema.
- **01_setup_aquaponics_db.pgsql**: SQL script to create the necessary tables, indexes, and materialized views for the aquaponics system.
- **02_setup_pg_cron_jobs.pgsql**: SQL script to schedule cron jobs for database maintenance and data aggregation.
- **03_intialize_ref_data.pgsql**: SQL script to initialize reference data like sensor types, areas, systems, and geographical references.
- **10_load_faker_data.py**: Python script to populate the database with fake data for testing and development.

## Setup Instructions

### Prerequisites

- PostgreSQL with TimescaleDB installed.
- `pg_cron` extension for scheduling jobs (must be enabled in your PostgreSQL setup).
- Python 3 with `psycopg2` and `Faker` libraries installed.
- A `~/.pgpass` file with database credentials in the format `*:*:*:*:your_password`.

### Execution

1. **Database Connection**:
   - Ensure your database credentials are correctly set in `wipe_and_rebuild.sh`. The script uses `.pgpass` for authentication.

2. **Run the Setup**:
   - From the command line, navigate to the directory containing the scripts and run:
     ```bash
     ./wipe_and_rebuild.sh
     ```
   - This script will:
     - Reset the database if necessary.
     - Set up the schema.
     - Configure cron jobs.
     - Initialize reference data.
     - Load fake data for testing.

### Script Descriptions

- **wipe_and_rebuild.sh**: 
  - Executes scripts in order, handling both SQL and Python. 
  - It uses `psql` for SQL scripts and `python3` for Python scripts.

- **00_Reset_aquaponics_db_for_schema_dev.pgsql**:
  - Drops all schema-related structures including tables, indexes, materialized views, and cron jobs. Use with caution as this will erase all data.

- **01_setup_aquaponics_db.pgsql**:
  - Creates tables for system components, sensor data, and metadata. 
  - Sets up materialized views for time-based data aggregation.

- **02_setup_pg_cron_jobs.pgsql**:
  - Schedules cron jobs to automatically refresh materialized views and perform data cleanup.

- **03_intialize_ref_data.pgsql**:
  - Populates tables with initial data for areas, systems, sensor types, and geographical references.

- **10_load_faker_data.py**:
  - Generates and inserts fake data into the database for testing purposes, respecting foreign key constraints and uniqueness.

## Maintenance

- Regularly check the `log` table for any operational messages or errors from cron jobs or other automated tasks.
- Monitor the performance of materialized view refreshes, adjusting job schedules if necessary.
- Consider adding more data cleanup or archival strategies as the dataset grows.

## Contributions

Feel free to contribute by improving scripts, adding more functionalities, or fixing issues. Please ensure that any changes align with the MIT license terms.

## Acknowledgments

Special thanks to the spirit of Douglas Adams from X (GROK 2) for the inspiration behind this script's wit and wisdom.

## License

This project is licensed under the MIT License - see the LICENSE file for details.