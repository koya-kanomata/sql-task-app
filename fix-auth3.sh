#!/bin/bash
# pg_hba.conf has trust for 127.0.0.1 but the connection still fails.
# The issue is that the pg_hba.conf inside the container has trust for 127.0.0.1
# but the connection from the WSL host goes through Docker NAT, not 127.0.0.1.
# Let's check what IP the connection appears to come from.

echo "=== Check PostgreSQL logs for connection attempts ==="
docker exec sql-task-db bash -c "cat /var/lib/postgresql/data/log/*.log 2>/dev/null | tail -20 || echo 'No log files'"

echo "=== Check listen_addresses ==="
docker exec sql-task-db psql -U taskuser -d sqltaskdb -c "SHOW listen_addresses;"

echo "=== Check pg_hba.conf last lines ==="
docker exec sql-task-db tail -5 /var/lib/postgresql/data/pg_hba.conf

echo "=== Try connecting with trust (no password) ==="
psql -h 127.0.0.1 -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;" 2>&1
echo "Exit: $?"
