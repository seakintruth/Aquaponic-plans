#!/bin/bash

# Database connection details
DB_USER="aquaponics"
DB_NAME="aquaponics_db"
# using .pgpass for authentication for password with -> (*:*:*:*:your_password)

# Array of all scripts to execute in order
SCRIPTS=(
    "./00_Reset_aquaponics_db_for_schema_dev.pgsql"
    "./01_setup_aquaponics_db.pgsql"
    "./02_setup_pg_cron_jobs.pgsql"
    "./03_intialize_ref_data.pgsql"
    "./10_load_faker_data.py"
    #"./20_additional_sql_after_python.pgsql"
    #"./30_additional_python.py"
)


# Function to execute scripts
execute_script() {
    local script="$1"
    echo "Running $script"
    if [[ "$script" == *.pgsql ]]; then
        psql -U $DB_USER -d $DB_NAME -f "$script" || {
            echo "Error executing $script. Exiting."
            exit 1
        }
    elif [[ "$script" == *.py ]]; then
        python3 "$script" || {
            echo "Error executing $script. Exiting."
            exit 1
        }
    else
        echo "Unsupported script type: $script"
        exit 1
    fi
}

# Execute scripts in order
for script in "${SCRIPTS[@]}"; do
    execute_script "$script"
done

echo "All scripts executed successfully!"