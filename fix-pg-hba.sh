#!/bin/bash
# The local PostgreSQL pg_hba.conf requires md5 auth for 127.0.0.1 connections
# but the taskuser password may not be set correctly, or pg_hba.conf is blocking.
# Let's check and fix the pg_hba.conf to allow md5 auth for taskuser.

PG_HBA="/etc/postgresql/16/main/pg_hba.conf"

echo "=== Current pg_hba.conf (non-comment lines) ==="
sudo grep -v "^#" $PG_HBA | grep -v "^$"

echo ""
echo "=== Adding md5 auth for taskuser ==="
# Add a line to allow taskuser to connect with md5 from 127.0.0.1
sudo bash -c "echo 'host sqltaskdb taskuser 127.0.0.1/32 md5' >> $PG_HBA"
sudo bash -c "echo 'host sqltaskdb taskuser ::1/128 md5' >> $PG_HBA"

echo ""
echo "=== Reloading PostgreSQL ==="
sudo systemctl reload postgresql 2>&1 || sudo service postgresql reload 2>&1

echo ""
echo "=== Testing connection ==="
sleep 2
PGPASSWORD=taskpass psql -h 127.0.0.1 -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;" 2>&1
echo "Exit: $?"
