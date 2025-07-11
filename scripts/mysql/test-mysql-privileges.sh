#!/bin/bash

# This script tests MySQL privileges to verify they are working correctly

echo "🧪 MYSQL PRIVILEGE TEST"
echo "======================="
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

echo "📋 Testing privileges for user: $MYSQL_USER"
echo ""

# Check if MySQL pod is running
if ! kubectl get pod -n database -l app=mysql | grep -q Running; then
    echo "❌ MySQL pod is not running. Please check deployment status:"
    echo "kubectl get pods -n database"
    exit 1
fi

echo "🔍 Running privilege tests..."
echo ""

# Test various operations that require different privileges
kubectl exec -n database deployment/mysql -- mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" << EOF
-- Test 1: Basic database operations
SELECT 'Test 1: Basic SELECT' as Test;
USE ${MYSQL_DATABASE};
SELECT COUNT(*) as sample_data_count FROM sample_data;

-- Test 2: System variables (requires SYSTEM_VARIABLES_ADMIN)
SELECT 'Test 2: System Variables' as Test;
SHOW VARIABLES LIKE 'version%';

-- Test 3: Process list (requires PROCESS privilege)
SELECT 'Test 3: Process List' as Test;
SHOW PROCESSLIST;

-- Test 4: Database list (requires SHOW DATABASES)
SELECT 'Test 4: Database List' as Test;
SHOW DATABASES;

-- Test 5: System database access
SELECT 'Test 5: System Database Access' as Test;
SELECT COUNT(*) as user_count FROM mysql.user;

-- Test 6: Performance schema access
SELECT 'Test 6: Performance Schema' as Test;
SELECT COUNT(*) as session_count FROM performance_schema.session_variables LIMIT 1;

-- Test 7: Information schema access
SELECT 'Test 7: Information Schema' as Test;
SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = '${MYSQL_DATABASE}';

SELECT 'All privilege tests completed!' as Final_Result;
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ ALL PRIVILEGE TESTS PASSED!"
    echo ""
    echo "🎉 Your MySQL user '$MYSQL_USER' has all the necessary privileges!"
    echo "🔧 You should be able to execute any query in CloudBeaver without privilege errors."
    echo ""
    echo "💡 Connection details for CloudBeaver:"
    echo "   Host: mysql-service.database.svc.cluster.local"
    echo "   Port: 3306"
    echo "   Database: $MYSQL_DATABASE"
    echo "   User: $MYSQL_USER"
    echo "   Password: $MYSQL_PASSWORD"
    echo ""
    echo "🌐 Access CloudBeaver at: http://database.localhost"
else
    echo ""
    echo "❌ SOME PRIVILEGE TESTS FAILED"
    echo "Run the privilege fix script to resolve issues:"
    echo "   ./scripts/mysql/fix-mysql-privileges.sh"
    echo ""
    echo "🔍 For detailed debugging:"
    echo "   kubectl logs -n database deployment/mysql"
fi
