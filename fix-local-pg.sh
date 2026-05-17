#!/bin/bash
# Found it! There's a LOCAL PostgreSQL 16 instance running on 127.0.0.1:5432
# This is intercepting connections before they reach the Docker container.
# The local PostgreSQL doesn't have the taskuser/taskpass credentials.
#
# Solution: Change the Spring Boot app to connect to the Docker container IP
# directly (172.21.0.2), OR stop the local PostgreSQL service.
#
# Best approach: Update application.properties to use the Docker container IP.

echo "=== Local PostgreSQL info ==="
sudo -u postgres psql -c "SELECT version();" 2>&1 | head -3
sudo -u postgres psql -c "\du" 2>&1

echo ""
echo "=== Checking if taskuser exists in local PostgreSQL ==="
sudo -u postgres psql -c "SELECT usename FROM pg_user WHERE usename='taskuser';" 2>&1
