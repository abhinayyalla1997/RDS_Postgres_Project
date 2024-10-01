#!/bin/bash

# Variables
DB_ENDPOINT="$1"
POSTGRES_USER="$2"  # Default PostgreSQL superuser
POSTGRES_PASS="$3"
POSTGRES_DB="$4"   # Default PostgreSQL database for connection
DB_NAME="$5"

# Export password to avoid interactive prompt
export PGPASSWORD="$POSTGRES_PASS"

psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE DATABASE $DB_NAME OWNER $POSTGRES_USER;"

psql -h "$DB_ENDPOINT" -U "$POSTGRES_USER" -d "$DB_NAME"  <<EOF
CREATE TABLE user_permissions (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    database_name VARCHAR(255) NOT NULL,
    read_permission BOOLEAN DEFAULT FALSE,
    write_permission BOOLEAN DEFAULT FALSE,
    assigned_by VARCHAR(255),
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

