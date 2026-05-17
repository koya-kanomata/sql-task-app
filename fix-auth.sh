#!/bin/bash
# Check pg_hba.conf
echo "=== pg_hba.conf ==="
docker exec sql-task-db cat /var/lib/postgresql/data/pg_hba.conf

# Add md5 auth for localhost connections
echo "=== Adding md5 auth for localhost ==="
docker exec sql-task-db bash -c "echo 'host all all 127.0.0.1/32 md5' >> /var/lib/postgresql/data/pg_hba.conf"
docker exec sql-task-db bash -c "echo 'host all all ::1/128 md5' >> /var/lib/postgresql/data/pg_hba.conf"

# Reload PostgreSQL config
echo "=== Reloading PostgreSQL ==="
docker exec sql-task-db psql -U taskuser -d sqltaskdb -c "SELECT pg_reload_conf();"

# Test connection
echo "=== Testing connection ==="
PGPASSWORD=taskpass psql -h 127.0.0.1 -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;"
echo "Exit: $?"
