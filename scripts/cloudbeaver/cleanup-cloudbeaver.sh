#!/bin/bash

# This script completely removes CloudBeaver from the database namespace
# It removes deployment, service, ingress, configmaps, and all related resources

echo "🗑️  CLOUDBEAVER REMOVAL SCRIPT"
echo "================================"
echo ""

# Function to check if resource exists
resource_exists() {
    kubectl get $1 $2 -n database &>/dev/null
    return $?
}

# Function to delete resource with confirmation
delete_resource() {
    local resource_type=$1
    local resource_name=$2
    
    if resource_exists $resource_type $resource_name; then
        echo "🔄 Deleting $resource_type: $resource_name"
        kubectl delete $resource_type $resource_name -n database
        if [ $? -eq 0 ]; then
            echo "✅ Successfully deleted $resource_type: $resource_name"
        else
            echo "❌ Failed to delete $resource_type: $resource_name"
        fi
    else
        echo "ℹ️  $resource_type $resource_name not found (already deleted or never existed)"
    fi
    echo ""
}

echo "Starting CloudBeaver cleanup..."
echo ""

# Delete CloudBeaver Deployment
delete_resource "deployment" "cloudbeaver"

# Delete CloudBeaver Service
delete_resource "service" "cloudbeaver-service"

# Delete old CloudBeaver Service (if exists)
delete_resource "service" "cloudbeaver"

# Delete CloudBeaver Ingress
delete_resource "ingress" "cloudbeaver-ingress"

# Delete CloudBeaver ConfigMaps
delete_resource "configmap" "cloudbeaver-config"
delete_resource "configmap" "cloudbeaver-connections"

# Delete any CloudBeaver Secrets (if they exist)
delete_resource "secret" "cloudbeaver-secret"

# Wait for pods to terminate
echo "🔄 Waiting for CloudBeaver pods to terminate..."
kubectl wait --for=delete pod -l app=cloudbeaver -n database --timeout=60s 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ All CloudBeaver pods terminated"
else
    echo "ℹ️  No CloudBeaver pods found or timeout reached"
fi
echo ""

# Show remaining resources in database namespace
echo "📋 REMAINING RESOURCES IN DATABASE NAMESPACE:"
echo "=============================================="
echo ""

echo "Deployments:"
kubectl get deployments -n database 2>/dev/null || echo "  No deployments found"
echo ""

echo "Services:"
kubectl get services -n database 2>/dev/null || echo "  No services found"
echo ""

echo "Ingresses:"
kubectl get ingresses -n database 2>/dev/null || echo "  No ingresses found"
echo ""

echo "ConfigMaps:"
kubectl get configmaps -n database | grep -v kube-root-ca.crt 2>/dev/null || echo "  No custom configmaps found"
echo ""

echo "Pods:"
kubectl get pods -n database 2>/dev/null || echo "  No pods found"
echo ""

# Check if database namespace is empty (except for system resources)
resource_count=$(kubectl get all -n database 2>/dev/null | grep -v "NAME" | grep -v "service/kubernetes" | wc -l)

if [ "$resource_count" -eq 0 ]; then
    echo "🎉 CLOUDBEAVER COMPLETELY REMOVED!"
    echo "================================="
    echo "✅ All CloudBeaver resources have been successfully deleted"
    echo "✅ Database namespace is clean (no CloudBeaver resources remaining)"
    echo ""
    echo "Note: Other database services (MySQL, PostgreSQL) remain untouched"
    echo ""
    echo "To redeploy CloudBeaver, run:"
    echo "  ./scripts/deploy-cloudbeaver.sh"
else
    echo "✅ CLOUDBEAVER REMOVAL COMPLETED"
    echo "==============================="
    echo "CloudBeaver has been removed from the cluster"
    echo "Other database services remain running as expected"
    echo ""
    echo "To redeploy CloudBeaver, run:"
    echo "  ./scripts/deploy-cloudbeaver.sh"
fi

echo ""
echo "🔗 USEFUL COMMANDS:"
echo "=================="
echo "Check database namespace status: kubectl get all -n database"
echo "Redeploy CloudBeaver: ./scripts/deploy-cloudbeaver.sh"
echo "Configure connections: ./scripts/configure-cloudbeaver-connections.sh"
echo "Run './scripts/deploy-cloudbeaver.sh' to redeploy CloudBeaver."
