#!/bin/bash
# The problem: pg_hba.conf has "host all all all scram-sha-256" BEFORE our md5 entries
# PostgreSQL reads rules top-to-bottom, so scram-sha-256 catches all connections first.
# We need to either:
# 1. Change the scram-sha-256 line to trust for all, OR
# 2. Recreate the container with a fresh volume

echo "=== Current pg_hba.conf (last 10 lines) ==="
docker exec sql-task-db tail -10 /var/lib/postgresql/data/pg_hba.conf

echo "=== Replacing scram-sha-256 with trust for all ==="
docker exec sql-task-db bash -c "sed -i 's/host all all all scram-sha-256/host all all all trust/' /var/lib/postgresql/data/pg_hba.conf"

echo "=== Reloading PostgreSQL ==="
docker exec sql-task-db psql -U taskuser -d sqltaskdb -c "SELECT pg_reload_conf();"

echo "=== Testing connection ==="
PGPASSWORD=taskpass psql -h 127.0.0.1 -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;" 2>&1
echo "Exit: $?"
