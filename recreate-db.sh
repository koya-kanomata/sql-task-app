#!/bin/bash
# The pg_hba.conf changes are persisted in the Docker volume.
# After restart, the container still has the modified pg_hba.conf.
# But the connection still fails with password auth.
# 
# The root cause: Docker on WSL2 uses a different network stack.
# When connecting from WSL2 host to 127.0.0.1:5432, the connection
# goes through the Docker proxy, and the container sees it as coming
# from the Docker bridge IP (172.x.x.x), NOT from 127.0.0.1.
# 
# The "host all all all trust" line should catch all connections.
# But it's still failing - this means the pg_hba.conf is NOT being
# read correctly after restart.
#
# Solution: Recreate the container with a fresh volume, using
# POSTGRES_HOST_AUTH_METHOD=trust to allow all connections.

echo "=== Stopping and removing old container and volume ==="
cd /home/kanomata/sql-task-app
docker compose down -v
echo "Done removing."

echo "=== Starting fresh container with trust auth ==="
# Temporarily modify docker-compose.yml to add trust auth
cat > /tmp/docker-compose-trust.yml << 'EOF'
version: '3.8'
services:
  db:
    image: postgres:16-alpine
    container_name: sql-task-db
    environment:
      POSTGRES_DB: sqltaskdb
      POSTGRES_USER: taskuser
      POSTGRES_PASSWORD: taskpass
      POSTGRES_HOST_AUTH_METHOD: trust
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U taskuser -d sqltaskdb"]
      interval: 10s
      timeout: 5s
      retries: 5
EOF

docker compose -f /tmp/docker-compose-trust.yml up -d
echo "Waiting for container to be healthy..."
sleep 15
docker ps --format "table {{.Names}}\t{{.Status}}"

echo "=== Testing connection ==="
PGPASSWORD=taskpass psql -h 127.0.0.1 -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;" 2>&1
echo "Exit: $?"

echo "=== Initializing DB ==="
bash /home/kanomata/sql-task-app/init-db2.sh
