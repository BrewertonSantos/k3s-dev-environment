#!/bin/bash

# This script fixes MySQL user privileges to resolve access denied errors

echo "🔧 MYSQL PRIVILEGE FIX"
echo "====================="
echo ""

# Check if MySQL credentials exist
MYSQL_CREDENTIALS_FILE="$HOME/.kube/database-credentials/mysql.txt"

if [ ! -f "$MYSQL_CREDENTIALS_FILE" ]; then
    echo "❌ MySQL credentials file not found: $MYSQL_CREDENTIALS_FILE"
    echo "Please deploy MySQL first with: ./deploy-mysql.sh"
    exit 1
fi

# Read MySQL credentials
MYSQL_DATABASE=$(grep "Database:" "$MYSQL_CREDENTIALS_FILE" | awk '{print $2}')
MYSQL_USER=$(grep "User:" "$MYSQL_CREDENTIALS_FILE" | awk '{print $2}')
MYSQL_PASSWORD=$(grep "Password:" "$MYSQL_CREDENTIALS_FILE" | awk '{print $2}')
MYSQL_ROOT_PASSWORD=$(grep "Root Password:" "$MYSQL_CREDENTIALS_FILE" | awk '{print $3}')

echo "📋 Current MySQL Configuration:"
echo "Database: $MYSQL_DATABASE"
echo "User: $MYSQL_USER"
echo ""

# Check if MySQL pod is running
if ! kubectl get pod -n database -l app=mysql | grep -q Running; then
    echo "❌ MySQL pod is not running. Please check deployment status:"
    echo "kubectl get pods -n database"
    exit 1
fi

echo "🔄 Applying privilege fixes..."

# Create a SQL file and execute it directly
cat > /tmp/mysql_privileges.sql << EOF
GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';
GRANT SUPER ON *.* TO '$MYSQL_USER'@'%';
GRANT SYSTEM_VARIABLES_ADMIN ON *.* TO '$MYSQL_USER'@'%';
GRANT RELOAD ON *.* TO '$MYSQL_USER'@'%';
GRANT PROCESS ON *.* TO '$MYSQL_USER'@'%';
GRANT SHOW DATABASES ON *.* TO '$MYSQL_USER'@'%';
GRANT REPLICATION CLIENT ON *.* TO '$MYSQL_USER'@'%';
GRANT REPLICATION SLAVE ON *.* TO '$MYSQL_USER'@'%';
GRANT SELECT ON mysql.* TO '$MYSQL_USER'@'%';
GRANT SELECT ON information_schema.* TO '$MYSQL_USER'@'%';
GRANT SELECT ON performance_schema.* TO '$MYSQL_USER'@'%';
GRANT SELECT ON sys.* TO '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
SHOW GRANTS FOR '$MYSQL_USER'@'%';
EOF

# Copy the SQL file to the MySQL pod and execute it
kubectl cp /tmp/mysql_privileges.sql database/$(kubectl get pod -n database -l app=mysql -o jsonpath='{.items[0].metadata.name}'):/tmp/privileges.sql

# Execute the SQL file
kubectl exec -n database deployment/mysql -- mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "source /tmp/privileges.sql"

# Clean up
rm /tmp/mysql_privileges.sql
kubectl exec -n database deployment/mysql -- rm /tmp/privileges.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ MySQL privileges have been successfully updated!"
    echo ""
    echo "🔗 Updated privileges for user '$MYSQL_USER':"
    echo "  - ALL PRIVILEGES on database '$MYSQL_DATABASE'"
    echo "  - SUPER (administrative privileges)"
    echo "  - SYSTEM_VARIABLES_ADMIN (fixes SQL Error 1227)"
    echo "  - RELOAD, PROCESS, SHOW DATABASES"
    echo "  - REPLICATION CLIENT, REPLICATION SLAVE"
    echo "  - SELECT on system databases (mysql, information_schema, performance_schema, sys)"
    echo ""
    echo "🎉 You should now be able to execute system queries without privilege errors!"
    echo ""
    echo "💡 Test the connection in CloudBeaver with these credentials:"
    echo "   Host: mysql-service.database.svc.cluster.local"
    echo "   Port: 3306"
    echo "   Database: $MYSQL_DATABASE"
    echo "   User: $MYSQL_USER"
    echo "   Password: $MYSQL_PASSWORD"
else
    echo ""
    echo "❌ Failed to update MySQL privileges"
    echo "Please check the MySQL deployment status and try again"
    echo ""
    echo "🔍 Debug commands:"
    echo "kubectl logs -n database deployment/mysql"
    echo "kubectl exec -n database deployment/mysql -- mysql -u root -p"
fi
