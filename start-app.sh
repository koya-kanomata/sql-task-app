#!/bin/bash
# Start the Spring Boot app with trust-based connection (no password needed since pg_hba.conf is now trust)
cd /home/kanomata/sql-task-app

echo "Starting Spring Boot app..."
java -jar target/sql-task-app-1.0.0.jar > target/app-new.log 2>&1 &
APP_PID=$!
echo "PID: $APP_PID"

# Wait for startup
for i in $(seq 1 30); do
    sleep 2
    if grep -q "Started SqlTaskAppApplication" target/app-new.log 2>/dev/null; then
        echo "App started successfully!"
        break
    fi
    if grep -q "Application run failed" target/app-new.log 2>/dev/null; then
        echo "App failed to start!"
        tail -20 target/app-new.log
        exit 1
    fi
    echo "Waiting... ($i/30)"
done

echo "--- Final log ---"
tail -20 target/app-new.log
