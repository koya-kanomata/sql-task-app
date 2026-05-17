#!/bin/bash
# Comprehensive fix script
# The sudo commands seem to be hanging (waiting for password input)
# Let's try a different approach

echo "=== Check if kanomata has sudo access ==="
sudo -n true 2>&1
echo "sudo exit: $?"

echo ""
echo "=== Check pg_hba.conf location ==="
ls -la /etc/postgresql/16/main/pg_hba.conf 2>&1

echo ""
echo "=== Try connecting as postgres user directly ==="
psql -U postgres -h 127.0.0.1 -p 5432 -c "SELECT 1;" 2>&1

echo ""
echo "=== Try connecting via unix socket ==="
psql -U postgres -c "SELECT usename FROM pg_user;" 2>&1

echo ""
echo "=== Check if taskuser exists ==="
psql -U postgres -c "SELECT usename FROM pg_user WHERE usename='taskuser';" 2>&1
