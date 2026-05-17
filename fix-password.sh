#!/bin/bash
docker exec sql-task-db psql -U taskuser -d sqltaskdb -c "ALTER USER taskuser WITH PASSWORD 'taskpass';"
echo "Password reset exit code: $?"
PGPASSWORD=taskpass psql -h localhost -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;" 2>&1
echo "Connection test exit code: $?"
