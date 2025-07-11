#!/bin/bash

# This script cleans up MySQL resources in the database namespace

echo "Cleaning up MySQL in the database namespace..."

# Delete MySQL deployment
kubectl delete deployment mysql -n database --ignore-not-found=true

# Delete MySQL service
kubectl delete service mysql-service -n database --ignore-not-found=true

# Delete MySQL ConfigMap
kubectl delete configmap mysql-init-script -n database --ignore-not-found=true

# Delete MySQL Secret
kubectl delete secret mysql-secret -n database --ignore-not-found=true

# Delete MySQL TCP Ingress
kubectl delete ingressroutetcp mysql-tcp-ingress -n database --ignore-not-found=true

# Delete PVCs (use with caution as this deletes data)
read -p "Delete MySQL persistent volume claim? This will DELETE ALL MYSQL DATA! (y/N): " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
  kubectl delete pvc mysql-pvc -n database --ignore-not-found=true
  echo "MySQL PVC deleted."
else
  echo "Skipping MySQL PVC deletion."
fi

# Remove credentials file
if [ -f ~/.kube/database-credentials/mysql.txt ]; then
    read -p "Remove saved MySQL credentials file? (y/N): " remove_creds
    if [[ $remove_creds == [yY] || $remove_creds == [yY][eE][sS] ]]; then
        rm ~/.kube/database-credentials/mysql.txt
        echo "MySQL credentials file removed."
    fi
fi

echo "MySQL cleanup completed!"
echo "Run './scripts/deploy-mysql.sh' to redeploy MySQL."
