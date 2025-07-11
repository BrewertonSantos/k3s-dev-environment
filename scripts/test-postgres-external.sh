#!/bin/bash

# PostgreSQL External Access Test Script
# This script tests PostgreSQL external connectivity and provides setup guidance

set -e

echo "🔍 PostgreSQL External Access Test"
echo "=================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test 1: Check if PostgreSQL pod is running
echo -n "1. Checking PostgreSQL pod status... "
if kubectl get pods -n database -l app=postgres --no-headers | grep -q "Running"; then
    echo -e "${GREEN}✅ Running${NC}"
else
    echo -e "${RED}❌ Not running${NC}"
    echo "   Run: kubectl get pods -n database"
    exit 1
fi

# Test 2: Check TCP connectivity to localhost:5432
echo -n "2. Testing TCP connectivity to localhost:5432... "
if nc -z localhost 5432 2>/dev/null; then
    echo -e "${GREEN}✅ Connected${NC}"
    POSTGRES_ACCESSIBLE=true
else
    echo -e "${YELLOW}⚠️  Not accessible${NC}"
    POSTGRES_ACCESSIBLE=false
fi

# Test 3: Check if port-forwarding is active
echo -n "3. Checking for active port-forwarding... "
if pgrep -f "port-forward.*postgres" > /dev/null; then
    echo -e "${GREEN}✅ Active${NC}"
    PORT_FORWARD_ACTIVE=true
else
    echo -e "${YELLOW}⚠️  Not active${NC}"
    PORT_FORWARD_ACTIVE=false
fi

# Test 4: Test database connection if accessible
if [ "$POSTGRES_ACCESSIBLE" = true ]; then
    echo -n "4. Testing database connection... "
    if PGPASSWORD=1q2w3e4r@123 psql -h localhost -p 5432 -U admin -d {database} -c "SELECT 1;" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Connected${NC}"
    else
        echo -e "${RED}❌ Authentication failed${NC}"
    fi
else
    echo "4. Database connection test skipped (TCP not accessible)"
fi

echo ""
echo "📋 Results Summary"
echo "=================="

if [ "$POSTGRES_ACCESSIBLE" = true ]; then
    echo -e "${GREEN}✅ PostgreSQL is externally accessible at localhost:5432${NC}"
    echo "   You can connect using: PGPASSWORD=1q2w3e4r@123 psql -h localhost -p 5432 -U admin -d {database}"
else
    echo -e "${YELLOW}⚠️  PostgreSQL is not externally accessible${NC}"
    echo ""
    echo "🔧 Setup Options:"
    echo ""
    echo "Option 1: Port Forwarding (Quick)"
    echo "   kubectl port-forward -n database svc/postgres 5432:5432 &"
    echo ""
    echo "Option 2: Alternative Port"
    echo "   kubectl port-forward -n database svc/postgres 15432:5432 &"
    echo "   PGPASSWORD=1q2w3e4r@123 psql -h localhost -p 15432 -U admin -d {database}"
    echo ""
    echo "Option 3: K3d Cluster Recreation (Permanent)"
    echo "   k3d cluster delete k3s-dev"
    echo "   k3d cluster create k3s-dev --port \"5432:30432@loadbalancer\" [other ports...]"
    echo ""
    echo "📖 For detailed instructions, see: docs/DATABASE_EXTERNAL_ACCESS.md"
fi

echo ""
echo "🔍 Additional Diagnostics"
echo "========================"
echo "Traefik TCP Ingress Routes:"
kubectl get ingressroutetcp -A | grep postgres || echo "   No PostgreSQL TCP ingress found"

echo ""
echo "PostgreSQL Service:"
kubectl get svc postgres -n database 2>/dev/null || echo "   PostgreSQL service not found"

echo ""
echo "For more information:"
echo "   📖 CloudBeaver README: docs/cloudbeaver/README.md"
echo "   📖 External Access Guide: docs/DATABASE_EXTERNAL_ACCESS.md"
