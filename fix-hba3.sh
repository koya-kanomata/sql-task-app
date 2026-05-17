#!/bin/bash
# The md5 entries we added are AFTER the "trust" line, so they never get matched.
# But the "trust" line should allow all connections without password.
# The issue is that the app is still failing with password auth.
# This means the pg_hba.conf reload didn't take effect, or the app is connecting
# to a different port/host.
# 
# Let's check: the app connects to localhost:5432 but the Docker container
# listens on 0.0.0.0:5432. The WSL host's 127.0.0.1:5432 might be forwarded
# to the Docker container, but the container sees the connection coming from
# the Docker bridge network IP, not 127.0.0.1.
#
# Solution: Restart the Docker container to apply pg_hba.conf changes properly,
# OR recreate the container with a fresh volume.

echo "=== Restarting Docker container to apply pg_hba.conf ==="
docker restart sql-task-db
echo "Waiting for container to be healthy..."
sleep 10
docker ps --format "table {{.Names}}\t{{.Status}}"

echo "=== Testing connection after restart ==="
PGPASSWORD=taskpass psql -h 127.0.0.1 -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;" 2>&1
echo "Exit: $?"

echo "=== Testing without password ==="
psql -h 127.0.0.1 -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;" 2>&1
echo "Exit: $?"
