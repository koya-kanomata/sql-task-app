#!/bin/bash
echo "=== Test 1: psql without password ==="
psql -h 127.0.0.1 -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;"
echo "Exit: $?"

echo ""
echo "=== Test 2: psql with password ==="
PGPASSWORD=taskpass psql -h 127.0.0.1 -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;"
echo "Exit: $?"

echo ""
echo "=== Test 3: psql via docker exec ==="
docker exec sql-task-db psql -U taskuser -d sqltaskdb -c "SELECT 1;"
echo "Exit: $?"

echo ""
echo "=== pg_hba.conf last 5 lines ==="
docker exec sql-task-db tail -5 /var/lib/postgresql/data/pg_hba.conf
