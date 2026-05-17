#!/bin/bash
# The issue: pg_hba.conf has "host all all all scram-sha-256" at the bottom
# which catches all connections. But 127.0.0.1 has "trust" above it.
# The problem might be that the password stored in postgres doesn't match.
# Let's reset the password using the postgres superuser.

echo "=== Resetting password as postgres superuser ==="
docker exec sql-task-db psql -U postgres -c "ALTER USER taskuser WITH PASSWORD 'taskpass';"

echo "=== Testing connection ==="
PGPASSWORD=taskpass psql -h 127.0.0.1 -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;"
echo "Exit: $?"
