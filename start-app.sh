#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

JAR_FILE="target/sql-task-app-1.0.0.jar"
LOG_FILE="target/app-new.log"
PID_FILE="target/app.pid"

echo "Building application..."
./mvnw -q -DskipTests package

if [[ -f "$PID_FILE" ]]; then
    EXISTING_PID=$(cat "$PID_FILE")
    if kill -0 "$EXISTING_PID" 2>/dev/null; then
        echo "Application is already running (PID: $EXISTING_PID)"
        exit 0
    fi
fi

echo "Starting Spring Boot app..."
echo "Using embedded H2 for this session. Set USE_POSTGRES=true to use an external PostgreSQL instance."
export SPRING_DATASOURCE_URL="jdbc:h2:mem:sqltaskdb;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE"
export SPRING_DATASOURCE_DRIVER_CLASS_NAME="org.h2.Driver"
export SPRING_DATASOURCE_USERNAME="sa"
export SPRING_DATASOURCE_PASSWORD=""

nohup java -jar "$JAR_FILE" > "$LOG_FILE" 2>&1 &
APP_PID=$!
echo "$APP_PID" > "$PID_FILE"
echo "PID: $APP_PID"

for i in $(seq 1 30); do
    sleep 2
    if grep -q "Started SqlTaskAppApplication" "$LOG_FILE" 2>/dev/null; then
        echo "App started successfully!"
        break
    fi
    if grep -q "Application run failed" "$LOG_FILE" 2>/dev/null; then
        echo "App failed to start!"
        tail -20 "$LOG_FILE"
        exit 1
    fi
    echo "Waiting... ($i/30)"
done

echo "--- Final log ---"
tail -20 "$LOG_FILE"
