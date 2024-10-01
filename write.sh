#!/bin/bash

# Variables
DB_USER="$1"           # Change to the desired username
DB_PASSWORD="$2"      # Change to the desired password
DB_NAME="$3"            # Change to the desired main database name
DB_ENDPOINT="$4"
POSTGRES_USER="$5"  # Default PostgreSQL superuser
POSTGRES_PASS="$6"
POSTGRES_DB="$7"   # Default PostgreSQL database for connection
ADMIN_USER_DB="$8"

export PGPASSWORD=$POSTGRES_PASS

psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE DATABASE $DB_NAME OWNER $POSTGRES_USER;"

# Revoke CONNECT from PUBLIC and grant to user
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "REVOKE CONNECT ON DATABASE $DB_NAME FROM PUBLIC;"
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "GRANT CONNECT ON DATABASE $DB_NAME TO $DB_USER;"

# Grant full privileges except database deletion on the main database
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "GRANT CREATE ON DATABASE $DB_NAME TO $DB_USER;"
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_NAME" -c "GRANT USAGE ON SCHEMA public TO $DB_USER;"
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_NAME" -c "GRANT CREATE ON SCHEMA public TO $DB_USER;"

# Grant full privileges on all tables and sequences in the public schema
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;"
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;"

# Use DO block to grant full privileges to all existing schemas, tables, and sequences
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_NAME" -c "
DO \$\$
DECLARE
    current_schema_name text;
BEGIN
    FOR current_schema_name IN
        SELECT s.schema_name
        FROM information_schema.schemata s
        WHERE s.schema_name NOT IN ('pg_catalog', 'information_schema')
    LOOP
        EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA %I TO $DB_USER;', current_schema_name);
        EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA %I TO $DB_USER;', current_schema_name);
        EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA %I TO $DB_USER;', current_schema_name);
    END LOOP;
END \$\$;"

# Grant full privileges on future tables and sequences in the public schema
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_NAME" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO $DB_USER;"
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_NAME" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO $DB_USER;"

# Ensure default privileges on future schemas, tables, and sequences
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_NAME" -c "
ALTER DEFAULT PRIVILEGES FOR ROLE $POSTGRES_USER GRANT ALL PRIVILEGES ON TABLES TO $DB_USER;"
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_NAME" -c "
ALTER DEFAULT PRIVILEGES FOR ROLE $POSTGRES_USER GRANT ALL PRIVILEGES ON SEQUENCES TO $DB_USER;"

# Insert permission details into the table with user and DB status
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$ADMIN_USER_DB" -c "
INSERT INTO user_permissions (username, database_name, write_permission, assigned_by) 
VALUES ('$DB_USER', '$DB_NAME', 'True', '$POSTGRES_USER');"

echo "User setup complete. Full privileges (except database deletion) for $DB_USER on $DB_NAME."