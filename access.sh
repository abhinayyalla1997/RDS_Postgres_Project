#!/bin/bash

# Variables
DB_USER="$1"          # Change to the desired username
DB_PASSWORD="$2"      # Change to the desired password
DB_READONLY_NAME="$3"  # The name of the existing database for read-only access
DB_ENDPOINT="$4"
POSTGRES_USER="$5"  # Default PostgreSQL superuser
POSTGRES_PASS="$6"
POSTGRES_DB="$7"   # Default PostgreSQL database for connection
ADMIN_USER_DB="$8"

export PGPASSWORD=$POSTGRES_PASS

psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"

# Revoke default SELECT permission from PUBLIC and grant connect to user
#psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_READONLY_NAME" -c "REVOKE CONNECT ON DATABASE $DB_READONLY_NAME FROM PUBLIC;"
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_READONLY_NAME" -c "GRANT CONNECT ON DATABASE $DB_READONLY_NAME TO $DB_USER;"

# Grant read access on the existing tables and sequences in all schemas in the database
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_READONLY_NAME" -c "
DO \$\$
DECLARE
    current_schema_name text;
BEGIN
    FOR current_schema_name IN
        SELECT s.schema_name
        FROM information_schema.schemata s
        WHERE s.schema_name NOT IN ('pg_catalog', 'information_schema')
    LOOP
        EXECUTE format('GRANT USAGE ON SCHEMA %I TO $DB_USER;', current_schema_name);
        EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO $DB_USER;', current_schema_name);
        EXECUTE format('GRANT SELECT ON ALL SEQUENCES IN SCHEMA %I TO $DB_USER;', current_schema_name);
    END LOOP;
END \$\$;"

# Grant default read-only privileges for future tables and sequences in all existing and future schemas
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_READONLY_NAME" -c "
ALTER DEFAULT PRIVILEGES FOR ROLE $POSTGRES_USER IN SCHEMA public GRANT SELECT ON TABLES TO $DB_USER;"
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_READONLY_NAME" -c "
ALTER DEFAULT PRIVILEGES FOR ROLE $POSTGRES_USER IN SCHEMA public GRANT SELECT ON SEQUENCES TO $DB_USER;"

# Ensure that future schemas also apply default read-only privileges
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_READONLY_NAME" -c "
ALTER DEFAULT PRIVILEGES FOR ROLE $POSTGRES_USER GRANT USAGE ON SCHEMAS TO $DB_USER;"
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_READONLY_NAME" -c "
ALTER DEFAULT PRIVILEGES FOR ROLE $POSTGRES_USER GRANT SELECT ON TABLES TO $DB_USER;"
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_READONLY_NAME" -c "
ALTER DEFAULT PRIVILEGES FOR ROLE $POSTGRES_USER GRANT SELECT ON SEQUENCES TO $DB_USER;"

# Insert permission details into the table
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$ADMIN_USER_DB" -c "
INSERT INTO user_permissions (username, database_name, read_permission, assigned_by) 
VALUES ('$DB_USER', '$DB_READONLY_NAME', 'True', '$POSTGRES_USER');"

echo "User setup complete. Read-only access to all existing and future tables and schemas in $DB_READONLY_NAME for $DB_USER."