#!/bin/bash

# Variables
DB_USER=${DB_USER}            # Change to the desired username
DB_PASSWORD=${DB_PASSWORD}    # Change to the desired password
DB_NAME=${DB_NAME}              # Change to the desired main database name
TABLE_NAME=${TABLE_NAME}             # Change to the desired table name
DB_ENDPOINT=${DB_ENDPOINT}
POSTGRES_USER=${POSTGRES_USER}    # Default PostgreSQL superuser
POSTGRES_PASS=${POSTGRES_PASS}
POSTGRES_DB=${POSTGRES_DB}  # Default PostgreSQL database for connection

export PGPASSWORD=$POSTGRES_PASS

# Check if the user already exists
USER_EXISTS=$(psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'")
if [ -z "$USER_EXISTS" ]; then
  USER_STATUS="new"
  psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
else
  USER_STATUS="existing"
fi

# Check if the database already exists
DB_EXISTS=$(psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")
if [ -z "$DB_EXISTS" ]; then
  DB_STATUS="new"
  psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE DATABASE $DB_NAME OWNER $POSTGRES_USER;"
else
  DB_STATUS="existing"
fi

# Grant CONNECT privilege to the user
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "GRANT CONNECT ON DATABASE $DB_NAME TO $DB_USER;"

# Grant necessary privileges on the specified table to the user
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_NAME" -c "GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE $TABLE_NAME TO $DB_USER;"

# Revoke DROP privileges on the table (if previously granted)
#psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_NAME" -c "REVOKE ALL PRIVILEGES ON TABLE $TABLE_NAME FROM $DB_USER;"

# Grant access to the sequence
SEQUENCE_NAME="${TABLE_NAME}_id_seq"  # Adjust according to your naming convention
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_NAME" -c "GRANT USAGE, SELECT, UPDATE ON SEQUENCE $SEQUENCE_NAME TO $DB_USER;"

# Ensure the user cannot drop the table or database
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_NAME" -c "REVOKE CREATE ON SCHEMA public FROM $DB_USER;"

# Ensure the user does not have unnecessary privileges on the database
#psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_NAME" -c "REVOKE ALL PRIVILEGES ON DATABASE $DB_NAME FROM $DB_USER;"

#psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "GRANT CONNECT ON DATABASE $DB_NAME TO $DB_USER;"

# Insert permission details into the table with user and DB status
psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
INSERT INTO user_permissions (username, database_name, permissions, assigned_by) 
VALUES ('$DB_USER ($USER_STATUS)', '$DB_NAME ($DB_STATUS)', 'SELECT, INSERT, UPDATE, DELETE on $TABLE_NAME', '$POSTGRES_USER');"

echo "User setup complete. $DB_USER has access to $TABLE_NAME with no DROP privileges."