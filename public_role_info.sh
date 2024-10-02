#!/bin/bash

# Environment variables for database connection
POSTGRES_USER=${POSTGRES_USER}   # PostgreSQL superuser
POSTGRES_PASS=${POSTGRES_PASS}  # Password for superuser
POSTGRES_DB=${POSTGRES_DB} # Default PostgreSQL database for initial connection
DB_ENDPOINT=${DB_ENDPOINT}   # Database endpoint (host)

# Set the PGPASSWORD environment variable to use non-interactively
export PGPASSWORD=${POSTGRES_PASS}

# Create a table to store revoked permissions if it doesn't exist
psql -U $POSTGRES_USER -h $DB_ENDPOINT -d $POSTGRES_DB -c "CREATE TABLE IF NOT EXISTS public.revoke_public (database_name TEXT, revoked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"

# Fetch all databases excluding template databases and rdsadmin
databases=$(psql -U $POSTGRES_USER -h $DB_ENDPOINT -d $POSTGRES_DB -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'rdsadmin';")

# Loop over each database and revoke CONNECT privilege from PUBLIC
for db in $databases; do
    echo "Revoking CONNECT privilege from database: $db"
    psql -U $POSTGRES_USER -h $DB_ENDPOINT -d "$db" -c "REVOKE CONNECT ON DATABASE $db FROM PUBLIC;"
    
    # Insert the revoked database name into the revoke_public table
    psql -U $POSTGRES_USER -h $DB_ENDPOINT -d $POSTGRES_DB -c "INSERT INTO public.revoke_public (database_name) VALUES ('$db');"
done
