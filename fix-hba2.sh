#!/bin/bash
# The sed replacement worked but the md5 entries we added earlier are AFTER the trust line.
# Let's check the full current state and try a different approach:
# Remove all the extra lines we added and replace the whole bottom section.

echo "=== Current pg_hba.conf (last 15 lines) ==="
docker exec sql-task-db tail -15 /var/lib/postgresql/data/pg_hba.conf

echo "=== Checking what the scram line looks like now ==="
docker exec sql-task-db grep "host all all all" /var/lib/postgresql/data/pg_hba.conf

echo "=== Try connecting without password (trust mode) ==="
psql -h 127.0.0.1 -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;" 2>&1
echo "Exit: $?"

echo "=== Try connecting with password ==="
PGPASSWORD=taskpass psql -h 127.0.0.1 -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;" 2>&1
echo "Exit: $?"
