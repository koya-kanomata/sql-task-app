#!/bin/bash
CONTAINER_IP=172.21.0.2

echo "=== Test with container IP ==="
PGPASSWORD=taskpass psql -h $CONTAINER_IP -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;"
echo "Exit: $?"

echo ""
echo "=== Test without password with container IP ==="
psql -h $CONTAINER_IP -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;"
echo "Exit: $?"

echo ""
echo "=== Test with 127.0.0.1 ==="
psql -h 127.0.0.1 -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;"
echo "Exit: $?"
