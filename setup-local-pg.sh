#!/bin/bash
# Create taskuser and sqltaskdb in the local PostgreSQL instance
# that is running on 127.0.0.1:5432

echo "=== Creating taskuser in local PostgreSQL ==="
sudo -u postgres psql -c "CREATE USER taskuser WITH PASSWORD 'taskpass';" 2>&1 || echo "User may already exist"

echo ""
echo "=== Creating sqltaskdb database ==="
sudo -u postgres psql -c "CREATE DATABASE sqltaskdb OWNER taskuser;" 2>&1 || echo "DB may already exist"

echo ""
echo "=== Granting privileges ==="
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE sqltaskdb TO taskuser;" 2>&1

echo ""
echo "=== Testing connection ==="
PGPASSWORD=taskpass psql -h 127.0.0.1 -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;" 2>&1
echo "Exit: $?"
