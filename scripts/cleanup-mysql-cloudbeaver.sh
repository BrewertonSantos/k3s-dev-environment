#!/bin/bash

# This script cleans up MySQL and CloudBeaver resources in the database namespace

echo "Cleaning up MySQL and CloudBeaver in the database namespace..."

# Delete deployments
kubectl delete deployment mysql -n database --ignore-not-found=true
kubectl delete deployment cloudbeaver -n database --ignore-not-found=true

# Delete services
kubectl delete service mysql-service -n database --ignore-not-found=true 
kubectl delete service cloudbeaver-service -n database --ignore-not-found=true

# Delete ConfigMaps
kubectl delete configmap mysql-init-script -n database --ignore-not-found=true
kubectl delete configmap cloudbeaver-config -n database --ignore-not-found=true

# Delete Secrets
kubectl delete secret mysql-secret -n database --ignore-not-found=true

# Delete Ingresses
kubectl delete ingressroutetcp mysql-tcp-ingress -n database --ignore-not-found=true
kubectl delete ingress cloudbeaver-ingress -n database --ignore-not-found=true

# Delete PVCs (use with caution as this deletes data)
read -p "Delete persistent volume claims? This will DELETE ALL MYSQL DATA! (y/N): " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
  kubectl delete pvc mysql-pvc -n database --ignore-not-found=true
  echo "PVCs deleted."
else
  echo "Skipping PVC deletion."
fi

echo "Cleanup completed!"
echo "Run './deploy-mysql-cloudbeaver.sh' to redeploy MySQL and CloudBeaver."
