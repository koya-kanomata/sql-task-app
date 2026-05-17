#!/bin/bash
echo "Pulling postgres:16-alpine..."
docker pull postgres:16-alpine
echo "Pull exit code: $?"
docker images --format '{{.Repository}}:{{.Tag}}'
