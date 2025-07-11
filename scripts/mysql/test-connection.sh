#!/bin/bash

# Simple MySQL connection test from external client

echo "🔌 MYSQL CONNECTION TEST"
echo "========================"
echo ""

# Read credentials
MYSQL_PASSWORD=$(grep "Password:" ~/.kube/database-credentials/mysql.txt | awk '{print $2}')
MYSQL_DATABASE=$(grep "Database:" ~/.kube/database-credentials/mysql.txt | awk '{print $2}')

echo "Testing external connection to MySQL..."

# Create a temporary pod to test MySQL connection
kubectl run mysql-test --rm -i --image=mysql:8.0 --restart=Never -- /bin/bash << EOF
mysql -h mysql-service.database.svc.cluster.local -u porigins -p$MYSQL_PASSWORD << SQL
SELECT 'Connection successful!' as Status;
USE $MYSQL_DATABASE;
SELECT COUNT(*) as SampleDataCount FROM sample_data;
SHOW VARIABLES LIKE 'version%' LIMIT 3;
SQL
EOF

echo ""
echo "If you see connection successful and version info above, the privileges are working!"
echo "Otherwise, run: ./scripts/mysql/fix-mysql-privileges.sh"
