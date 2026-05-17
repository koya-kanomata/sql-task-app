#!/bin/bash
echo "=== Who is listening on port 5432? ==="
ss -tlnp | grep 5432

echo ""
echo "=== Process info ==="
PID=$(ss -tlnp | grep 5432 | grep -oP 'pid=\K[0-9]+')
echo "PID: $PID"
if [ -n "$PID" ]; then
    cat /proc/$PID/cmdline | tr '\0' ' '
    echo ""
fi

echo ""
echo "=== Docker proxy processes ==="
ps aux | grep docker-proxy | grep -v grep

echo ""
echo "=== Try connecting to Docker container IP directly ==="
CONTAINER_IP=$(docker inspect sql-task-db --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
echo "Container IP: $CONTAINER_IP"
PGPASSWORD=taskpass psql -h $CONTAINER_IP -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;" 2>&1
echo "Exit: $?"
