#!/bin/bash
echo "=== ss output with process info ==="
ss -tlnp

echo ""
echo "=== All processes listening on 5432 ==="
ss -tlnp | grep ':5432'

echo ""
echo "=== Check if there's a local PostgreSQL service ==="
systemctl status postgresql 2>&1 | head -5 || echo "systemctl not available"
service postgresql status 2>&1 | head -5 || echo "service not available"

echo ""
echo "=== Check for local postgres process ==="
ps aux | grep postgres | grep -v grep | grep -v docker

echo ""
echo "=== Check /var/run/postgresql ==="
ls -la /var/run/postgresql/ 2>&1
