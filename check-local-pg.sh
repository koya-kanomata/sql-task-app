#!/bin/bash
echo "=== Local PostgreSQL users ==="
sudo -u postgres psql -c "SELECT usename, passwd IS NOT NULL as has_password FROM pg_shadow;" 2>&1

echo ""
echo "=== Local PostgreSQL databases ==="
sudo -u postgres psql -c "SELECT datname FROM pg_database;" 2>&1

echo ""
echo "=== pg_hba.conf ==="
sudo cat /etc/postgresql/16/main/pg_hba.conf 2>&1 | grep -v "^#" | grep -v "^$"

echo ""
echo "=== Test connection as taskuser ==="
PGPASSWORD=taskpass psql -h 127.0.0.1 -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;" 2>&1
echo "Exit: $?"
