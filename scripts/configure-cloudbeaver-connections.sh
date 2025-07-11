#!/bin/bash

# Script to help configure CloudBeaver database connections
# This provides the exact connection details for copy-paste into CloudBeaver UI

echo "🔗 CLOUDBEAVER DATABASE CONNECTIONS"
echo "=================================================="
echo ""
echo "Access CloudBeaver at: http://database.localhost"
echo ""

# Check if MySQL credentials exist
MYSQL_CREDENTIALS_FILE="$HOME/.kube/database-credentials/mysql.txt"

if [ -f "$MYSQL_CREDENTIALS_FILE" ]; then
    MYSQL_DATABASE=$(grep "Database:" "$MYSQL_CREDENTIALS_FILE" | awk '{print $2}')
    MYSQL_USER=$(grep "User:" "$MYSQL_CREDENTIALS_FILE" | awk '{print $2}')
    MYSQL_PASSWORD=$(grep "Password:" "$MYSQL_CREDENTIALS_FILE" | awk '{print $2}')
    
    echo "📊 MYSQL CONNECTION DETAILS:"
    echo "--------------------------------------------------"
    echo "Connection Name: MySQL Production"
    echo "Driver: MySQL"
    echo "Host: mysql-service.database.svc.cluster.local"
    echo "Port: 3306"
    echo "Database: $MYSQL_DATABASE"
    echo "Username: $MYSQL_USER"
    echo "Password: $MYSQL_PASSWORD"
    echo "Authentication: Database Native"
    echo ""
    echo "📋 Quick Copy Commands:"
    echo "Host: mysql-service.database.svc.cluster.local"
    echo "Database: $MYSQL_DATABASE"
    echo "Username: $MYSQL_USER"
    echo "Password: $MYSQL_PASSWORD"
    echo ""
else
    echo "❌ MySQL not found. Deploy MySQL first with:"
    echo "   ./scripts/deploy-mysql.sh"
    echo ""
fi

echo "🐘 POSTGRESQL CONNECTION DETAILS:"
echo "--------------------------------------------------"
echo "Connection Name: PostgreSQL Production"
echo "Driver: PostgreSQL"
echo "Host: postgres-service.database.svc.cluster.local"
echo "Port: 5432"
echo "Database: postgres"
echo "Username: postgres"
echo "Password: postgres123"
echo "Authentication: Database Native"
echo ""
echo "📋 Quick Copy Commands:"
echo "Host: postgres-service.database.svc.cluster.local"
echo "Database: postgres"
echo "Username: postgres"
echo "Password: postgres123"
echo ""

echo "🚀 QUICK SETUP INSTRUCTIONS:"
echo "=================================================="
echo "1. Open http://database.localhost in your browser"
echo "2. Complete initial CloudBeaver setup (create admin user)"
echo "3. Click 'New Connection' button"
echo "4. Select database type (MySQL or PostgreSQL)"
echo "5. Copy-paste the connection details above"
echo "6. Click 'Test Connection' then 'Save'"
echo ""

echo "✅ All database services are running in the same cluster!"
echo "✅ No port forwarding needed - direct browser access!"
echo "✅ Internal DNS resolution handles all connectivity!"
