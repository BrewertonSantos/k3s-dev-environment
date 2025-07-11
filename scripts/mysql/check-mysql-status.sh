#!/bin/bash

# This script checks the status of MySQL in the database namespace and helps with troubleshooting

echo "Checking MySQL status in the database namespace..."

# Check if the MySQL pod is running
MYSQL_POD=$(kubectl get pods -n database -l app=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$MYSQL_POD" ]; then
  echo "ERROR: MySQL pod not found in namespace 'database'"
  echo "Deployment status:"
  kubectl get deployments -n database -l app=mysql
  exit 1
fi

# Check MySQL pod status
echo "MySQL Pod: $MYSQL_POD"
kubectl get pods -n database $MYSQL_POD -o wide

# Check pod description for any issues
echo -e "\nPod Description:"
kubectl describe pod -n database $MYSQL_POD | grep -E "State:|Reason:|Message:|Exit Code:|Restart|Error|Warning"

# Check pod logs
echo -e "\nRecent MySQL Pod Logs:"
kubectl logs -n database $MYSQL_POD --tail=50

# Get MySQL service details
echo -e "\nMySQL Service Details:"
kubectl get service mysql-service -n database -o wide

# Test MySQL connection from inside the cluster
echo -e "\nTesting MySQL connection from inside the cluster..."
echo "This will run a test pod to try connecting to MySQL."
read -p "Would you like to run the connection test? (y/N): " confirm

if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
  # Get the current credentials
  if [ -f ~/.kube/database-credentials/mysql.txt ]; then
    echo "Using credentials from ~/.kube/database-credentials/mysql.txt"
    DB=$(grep "Database:" ~/.kube/database-credentials/mysql.txt | awk '{print $2}')
    USER=$(grep "User:" ~/.kube/database-credentials/mysql.txt | awk '{print $2}')
    echo -n "Please enter MySQL password for $USER: "
    read -s PASS
    echo ""
    
    echo "Running test pod to connect to MySQL..."
    kubectl run mysql-test --rm -i --tty --restart=Never --namespace database --image=mysql:8.0 -- mysql -h mysql-service -u "$USER" -p"$PASS" "$DB" -e "SHOW TABLES; SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$DB';"
  else
    echo "Credentials file not found at ~/.kube/database-credentials/mysql.txt"
    echo "Please enter MySQL connection details manually:"
    echo -n "Database name: "
    read DB
    echo -n "Username: "
    read USER
    echo -n "Password: "
    read -s PASS
    echo ""
    
    echo "Running test pod to connect to MySQL..."
    kubectl run mysql-test --rm -i --tty --restart=Never --namespace database --image=mysql:8.0 -- mysql -h mysql-service -u "$USER" -p"$PASS" "$DB" -e "SHOW TABLES; SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$DB';"
  fi
else
  echo "Skipping connection test."
fi

# Check MySQL resource usage
echo -e "\nMySQL Resource Usage:"
kubectl top pod -n database $MYSQL_POD 2>/dev/null || echo "Resource metrics not available. Ensure metrics server is running."

echo -e "\nMySQL Status Check Complete!"
echo "If you're experiencing issues, you can try:"
echo "1. Check events: kubectl get events -n database --sort-by='.lastTimestamp'"
echo "2. Restart MySQL: kubectl rollout restart deployment/mysql -n database"
echo "3. Clean up and redeploy: ./scripts/cleanup-mysql-cloudbeaver.sh && ./scripts/deploy-mysql-cloudbeaver.sh"
