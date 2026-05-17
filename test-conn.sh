#!/bin/bash
echo "Testing psql connection..."
psql -h 127.0.0.1 -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;" 2>&1
echo "Exit: $?"

echo ""
echo "Testing with PGPASSWORD..."
PGPASSWORD=taskpass psql -h 127.0.0.1 -p 5432 -U taskuser -d sqltaskdb -c "SELECT 1;" 2>&1
echo "Exit: $?"

echo ""
echo "Testing Java app connection..."
cd /home/kanomata/sql-task-app
java -jar target/sql-task-app-1.0.0.jar > target/app.log 2>&1 &
APP_PID=$!
echo "App PID: $APP_PID"
sleep 20
echo "--- App log ---"
cat target/app.log
echo "--- End log ---"
kill $APP_PID 2>/dev/null
