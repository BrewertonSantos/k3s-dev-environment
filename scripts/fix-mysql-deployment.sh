#!/bin/bash

# This script fixes the MySQL deployment in the database namespace

# Delete the existing MySQL deployment if it exists (to clear any stuck pods)
kubectl delete deployment mysql -n database --ignore-not-found=true

# Apply the updated MySQL deployment
kubectl apply -f k8s-manifests/database-mysql.yaml

# Wait for the deployment to be ready
echo "Waiting for MySQL deployment..."
kubectl -n database wait --for=condition=Available deployment/mysql --timeout=120s || true

# Check the status
echo "MySQL Pod Status:"
kubectl get pods -n database -l app=mysql

echo "MySQL Logs:"
kubectl logs -n database -l app=mysql
