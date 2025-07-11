#!/bin/bash

# Observability Management Script
# Manages the complete observability stack: Prometheus, Grafana, OpenSearch, and Fluent Bit

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
show_usage() {
    echo "Usage: $0 <action> [component]"
    echo ""
    echo "Actions:"
    echo "  deploy    - Deploy observability components"
    echo "  cleanup   - Remove observability components"
    echo "  status    - Show component status"
    echo "  logs      - Show component logs"
    echo "  restart   - Restart components"
    echo ""
    echo "Components:"
    echo "  prometheus           - kube-prometheus-stack (Prometheus, AlertManager, Node Exporter)"
    echo "  grafana              - Metrics visualization"
    echo "  opensearch           - Log storage and search"
    echo "  fluent-bit           - Log collection"
    echo "  database-monitoring  - PostgreSQL, MySQL and CloudBeaver monitoring"
    echo "  all                  - All components"
    echo ""
    echo "Examples:"
    echo "  $0 deploy all"
    echo "  $0 status prometheus"
    echo "  $0 deploy database-monitoring"
    echo "  $0 status database-monitoring"
    echo "  $0 logs opensearch"
    echo "  $0 restart grafana"
}

# Deploy functions
deploy_prometheus() {
    echo -e "${YELLOW}🚀 Deploying kube-prometheus-stack...${NC}"
    
    # Ensure Helm repo is added
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
    helm repo update >/dev/null 2>&1 || true
    
    # Deploy using Helm with our custom values
    helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
        --namespace development \
        --create-namespace \
        --values config/prometheus/kube-prometheus-stack-values.yaml \
        --wait --timeout=300s
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ kube-prometheus-stack deployed successfully${NC}"
        
        # Deploy database monitoring exporters
        echo -e "${YELLOW}🔄 Deploying database monitoring...${NC}"
        deploy_database_monitoring
        
        # Update Grafana data source to use new Prometheus
        echo -e "${YELLOW}🔄 Updating Grafana data source...${NC}"
        kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n development --timeout=120s
        
        # Wait a bit for Grafana to be fully ready
        sleep 10
        
        kubectl exec -n development deployment/grafana -- curl -s -X PUT \
            -H "Content-Type: application/json" \
            -u admin:1q2w3e4r@123 \
            "http://localhost:3000/api/datasources/1" \
            -d '{
                "id": 1,
                "uid": "derkpng9hoagwb",
                "orgId": 1,
                "name": "prometheus",
                "type": "prometheus",
                "access": "proxy",
                "url": "http://kube-prometheus-prometheus.development.svc.cluster.local:9090",
                "basicAuth": false,
                "isDefault": true,
                "jsonData": {
                    "httpMethod": "POST"
                }
            }' >/dev/null 2>&1
        
        echo -e "${GREEN}✅ Grafana data source updated${NC}"
    else
        echo -e "${RED}❌ Failed to deploy kube-prometheus-stack${NC}"
        exit 1
    fi
}

deploy_database_monitoring() {
    echo -e "${YELLOW}📊 Deploying database exporters and monitoring...${NC}"
    
    # Deploy PostgreSQL exporter
    echo -e "${YELLOW}🔄 Deploying PostgreSQL exporter...${NC}"
    kubectl apply -f k8s-manifests/postgres-exporter.yaml
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ PostgreSQL exporter deployed${NC}"
    else
        echo -e "${RED}❌ Failed to deploy PostgreSQL exporter${NC}"
    fi
    
    # Deploy MySQL exporter
    echo -e "${YELLOW}🔄 Deploying MySQL exporter...${NC}"
    kubectl apply -f k8s-manifests/mysql-exporter.yaml
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ MySQL exporter deployed${NC}"
    else
        echo -e "${RED}❌ Failed to deploy MySQL exporter${NC}"
    fi
    
    # Deploy ServiceMonitors and Alerts
    echo -e "${YELLOW}🔄 Deploying database monitoring and alerts...${NC}"
    kubectl apply -f k8s-manifests/database-monitoring.yaml
    kubectl apply -f k8s-manifests/database-alerts.yaml
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Database monitoring and alerts deployed${NC}"
    else
        echo -e "${RED}❌ Failed to deploy database monitoring${NC}"
    fi
    
    # Wait for exporters to be ready
    echo -e "${YELLOW}⏳ Waiting for database exporters to be ready...${NC}"
    kubectl wait --for=condition=ready pod -l app=postgres-exporter -n database --timeout=120s
    kubectl wait --for=condition=ready pod -l app=mysql-exporter -n database --timeout=120s
    
    echo -e "${GREEN}✅ Database monitoring setup complete${NC}"
}

deploy_grafana() {
    echo -e "${YELLOW}🚀 Deploying Grafana...${NC}"
    kubectl apply -f k8s-manifests/grafana.yaml
    echo -e "${GREEN}✅ Grafana deployed${NC}"
}

deploy_opensearch() {
    echo -e "${YELLOW}🚀 Deploying OpenSearch...${NC}"
    kubectl apply -f k8s-manifests/opensearch.yaml
    echo -e "${GREEN}✅ OpenSearch deployed${NC}"
}

deploy_fluent_bit() {
    echo -e "${YELLOW}🚀 Deploying Fluent Bit...${NC}"
    kubectl apply -f k8s-manifests/fluent-bit.yaml
    echo -e "${GREEN}✅ Fluent Bit deployed${NC}"
}

deploy_ingress() {
    echo -e "${YELLOW}🚀 Deploying Observability Ingress...${NC}"
    kubectl apply -f k8s-manifests/observability-ingress.yaml
    echo -e "${GREEN}✅ Ingress deployed${NC}"
}

deploy_all() {
    echo -e "${BLUE}🚀 DEPLOYING COMPLETE OBSERVABILITY STACK${NC}"
    echo "=========================================="
    
    deploy_prometheus
    deploy_database_monitoring
    deploy_grafana
    deploy_opensearch
    deploy_fluent_bit
    deploy_ingress
    
    echo ""
    echo -e "${YELLOW}⏳ Waiting for deployments to be ready...${NC}"
    kubectl wait --for=condition=available deployment --all -n development --timeout=300s
    kubectl wait --for=condition=available deployment --all -n logging --timeout=300s
    
    echo ""
    echo -e "${GREEN}🎉 OBSERVABILITY STACK DEPLOYED SUCCESSFULLY!${NC}"
    echo ""
    echo -e "${BLUE}📊 Access your observability tools:${NC}"
    echo "• Grafana:           http://grafana.localhost (admin/1q2w3e4r@123)"
    echo "• Prometheus:        http://prometheus.localhost"
    echo "• OpenSearch Logs:   http://opensearch.localhost"
    echo "• Log Viewer:        http://logs.localhost"
    echo ""
    echo -e "${YELLOW}💡 Wait a few minutes for logs to start appearing in OpenSearch${NC}"
}

# Cleanup functions
cleanup_prometheus() {
    echo -e "${YELLOW}🗑️ Cleaning up kube-prometheus-stack...${NC}"
    
    # Remove Helm release
    helm uninstall kube-prometheus-stack -n development 2>/dev/null || true
    
    # Remove any remaining Prometheus resources
    kubectl delete prometheus,alertmanager,servicemonitor,prometheusrule -n development --all --ignore-not-found=true
    
    # Remove CRDs if they exist (optional - comment out if you want to keep them)
    kubectl delete crd prometheuses.monitoring.coreos.com --ignore-not-found=true
    kubectl delete crd alertmanagers.monitoring.coreos.com --ignore-not-found=true
    kubectl delete crd servicemonitors.monitoring.coreos.com --ignore-not-found=true
    kubectl delete crd prometheusrules.monitoring.coreos.com --ignore-not-found=true
    kubectl delete crd podmonitors.monitoring.coreos.com --ignore-not-found=true
    kubectl delete crd thanosrulers.monitoring.coreos.com --ignore-not-found=true
    kubectl delete crd alertmanagerconfigs.monitoring.coreos.com --ignore-not-found=true
    kubectl delete crd probes.monitoring.coreos.com --ignore-not-found=true
    kubectl delete crd scrapeconfigs.monitoring.coreos.com --ignore-not-found=true
    
    echo -e "${GREEN}✅ kube-prometheus-stack cleaned up${NC}"
}

cleanup_database_monitoring() {
    echo -e "${YELLOW}🗑️ Cleaning up database monitoring...${NC}"
    
    # Remove database exporters
    kubectl delete -f k8s-manifests/postgres-exporter.yaml --ignore-not-found=true
    kubectl delete -f k8s-manifests/mysql-exporter.yaml --ignore-not-found=true
    
    # Remove ServiceMonitors and alerts
    kubectl delete -f k8s-manifests/database-monitoring.yaml --ignore-not-found=true
    kubectl delete -f k8s-manifests/database-alerts.yaml --ignore-not-found=true
    
    echo -e "${GREEN}✅ Database monitoring cleaned up${NC}"
}

cleanup_grafana() {
    echo -e "${YELLOW}🗑️ Cleaning up Grafana...${NC}"
    kubectl delete -f k8s-manifests/grafana.yaml --ignore-not-found=true
    echo -e "${GREEN}✅ Grafana cleaned up${NC}"
}

cleanup_opensearch() {
    echo -e "${YELLOW}🗑️ Cleaning up OpenSearch...${NC}"
    kubectl delete -f k8s-manifests/opensearch.yaml --ignore-not-found=true
    echo -e "${GREEN}✅ OpenSearch cleaned up${NC}"
}

cleanup_fluent_bit() {
    echo -e "${YELLOW}🗑️ Cleaning up Fluent Bit...${NC}"
    kubectl delete -f k8s-manifests/fluent-bit.yaml --ignore-not-found=true
    echo -e "${GREEN}✅ Fluent Bit cleaned up${NC}"
}

cleanup_ingress() {
    echo -e "${YELLOW}🗑️ Cleaning up Ingress...${NC}"
    kubectl delete -f k8s-manifests/observability-ingress.yaml --ignore-not-found=true
    echo -e "${GREEN}✅ Ingress cleaned up${NC}"
}

cleanup_all() {
    echo -e "${RED}🗑️ CLEANING UP OBSERVABILITY STACK${NC}"
    echo "===================================="
    
    cleanup_ingress
    cleanup_fluent_bit
    cleanup_opensearch
    cleanup_grafana
    cleanup_prometheus
    cleanup_database_monitoring
    
    echo ""
    echo -e "${GREEN}✅ Complete cleanup finished${NC}"
}

# Status functions
status_prometheus() {
    echo -e "${BLUE}📊 kube-prometheus-stack Status:${NC}"
    
    # Check Helm release
    echo "Helm Release:"
    helm status kube-prometheus-stack -n development 2>/dev/null || echo "❌ Helm release not found"
    echo
    
    # Check pods
    echo "Pods:"
    kubectl get pods -n development -l "release=kube-prometheus-stack"
    
    # Check Prometheus and AlertManager resources
    echo
    echo "Prometheus & AlertManager:"
    kubectl get prometheus,alertmanager -n development 2>/dev/null || echo "No Prometheus/AlertManager resources found"
    
    # Check services
    echo
    echo "Services:"
    kubectl get svc -n development | grep "kube-prometheus\|prometheus-operated" || echo "No Prometheus services found"
    echo
}

status_database_monitoring() {
    echo -e "${BLUE}📊 Database Monitoring Status:${NC}"
    
    # Check PostgreSQL exporter
    echo "PostgreSQL Exporter Pods:"
    kubectl get pods -n database -l app=postgres-exporter
    
    # Check MySQL exporter
    echo
    echo "MySQL Exporter Pods:"
    kubectl get pods -n database -l app=mysql-exporter
    
    # Check ServiceMonitors
    echo
    echo "ServiceMonitors:"
    kubectl get servicemonitor -n database -l app=postgres-exporter
    kubectl get servicemonitor -n development -l app=mysql-exporter
    kubectl get servicemonitor -n database -l app=cloudbeaver
    
    # Check PrometheusRules
    echo
    echo "Database Alerts (PrometheusRules):"
    kubectl get prometheusrule -n database -l app=database-monitoring
    
    # Check exporter endpoints
    echo
    echo "PostgreSQL Exporter Endpoint:"
    kubectl get endpoints -n database postgres-exporter
    echo
    echo "MySQL Exporter Endpoint:"
    kubectl get endpoints -n development mysql-exporter
}

status_grafana() {
    echo -e "${BLUE}📈 Grafana Status:${NC}"
    kubectl get pods -n development -l app=grafana
    echo
}

status_opensearch() {
    echo -e "${BLUE}🔍 OpenSearch Status:${NC}"
    kubectl get pods -n logging -l app=opensearch
    kubectl get pods -n logging -l app=opensearch-dashboards
    echo
}

status_fluent_bit() {
    echo -e "${BLUE}📝 Fluent Bit Status:${NC}"
    kubectl get pods -n logging -l name=fluent-bit
    echo
}

status_all() {
    echo -e "${BLUE}📊 OBSERVABILITY STACK STATUS${NC}"
    echo "=============================="
    echo
    
    status_prometheus
    status_database_monitoring
    status_grafana
    status_opensearch
    status_fluent_bit
    
    echo -e "${BLUE}🌐 Ingress Status:${NC}"
    kubectl get ingress -n development
    kubectl get ingress -n logging
    echo
    
    echo -e "${BLUE}💾 Storage Status:${NC}"
    kubectl get pvc -n development
    kubectl get pvc -n logging
}

# Logs functions
logs_prometheus() {
    echo -e "${BLUE}📊 Prometheus Logs:${NC}"
    kubectl logs -n development deployment/prometheus --tail=50 -f
}

logs_grafana() {
    echo -e "${BLUE}📈 Grafana Logs:${NC}"
    kubectl logs -n development deployment/grafana --tail=50 -f
}

logs_opensearch() {
    echo -e "${BLUE}🔍 OpenSearch Logs:${NC}"
    kubectl logs -n logging deployment/opensearch --tail=50 -f
}

logs_fluent_bit() {
    echo -e "${BLUE}📝 Fluent Bit Logs:${NC}"
    kubectl logs -n logging daemonset/fluent-bit --tail=50 -f
}

# Restart functions
restart_prometheus() {
    echo -e "${YELLOW}🔄 Restarting Prometheus...${NC}"
    kubectl rollout restart deployment/prometheus -n development
    kubectl rollout status deployment/prometheus -n development
    echo -e "${GREEN}✅ Prometheus restarted${NC}"
}

restart_grafana() {
    echo -e "${YELLOW}🔄 Restarting Grafana...${NC}"
    kubectl rollout restart deployment/grafana -n development
    kubectl rollout status deployment/grafana -n development
    echo -e "${GREEN}✅ Grafana restarted${NC}"
}

restart_opensearch() {
    echo -e "${YELLOW}🔄 Restarting OpenSearch...${NC}"
    kubectl rollout restart deployment/opensearch -n logging
    kubectl rollout restart deployment/opensearch-dashboards -n logging
    kubectl rollout status deployment/opensearch -n logging
    kubectl rollout status deployment/opensearch-dashboards -n logging
    echo -e "${GREEN}✅ OpenSearch restarted${NC}"
}

restart_fluent_bit() {
    echo -e "${YELLOW}🔄 Restarting Fluent Bit...${NC}"
    kubectl rollout restart daemonset/fluent-bit -n logging
    kubectl rollout status daemonset/fluent-bit -n logging
    echo -e "${GREEN}✅ Fluent Bit restarted${NC}"
}

restart_all() {
    echo -e "${YELLOW}🔄 RESTARTING ALL OBSERVABILITY COMPONENTS${NC}"
    echo "=========================================="
    
    restart_prometheus
    restart_grafana
    restart_opensearch
    restart_fluent_bit
    
    echo -e "${GREEN}✅ All components restarted${NC}"
}

# Main script logic
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

ACTION=$1
COMPONENT=${2:-all}

case $ACTION in
    deploy)
        case $COMPONENT in
            prometheus) deploy_prometheus ;;
            grafana) deploy_grafana ;;
            opensearch) deploy_opensearch ;;
            fluent-bit) deploy_fluent_bit ;;
            ingress) deploy_ingress ;;
            database-monitoring) deploy_database_monitoring ;;
            all) deploy_all ;;
            *) echo -e "${RED}❌ Unknown component: $COMPONENT${NC}"; show_usage; exit 1 ;;
        esac
        ;;
    cleanup)
        case $COMPONENT in
            prometheus) cleanup_prometheus ;;
            grafana) cleanup_grafana ;;
            opensearch) cleanup_opensearch ;;
            fluent-bit) cleanup_fluent_bit ;;
            ingress) cleanup_ingress ;;
            database-monitoring) cleanup_database_monitoring ;;
            all) cleanup_all ;;
            *) echo -e "${RED}❌ Unknown component: $COMPONENT${NC}"; show_usage; exit 1 ;;
        esac
        ;;
    status)
        case $COMPONENT in
            prometheus) status_prometheus ;;
            grafana) status_grafana ;;
            opensearch) status_opensearch ;;
            fluent-bit) status_fluent_bit ;;
            database-monitoring) status_database_monitoring ;;
            all) status_all ;;
            *) echo -e "${RED}❌ Unknown component: $COMPONENT${NC}"; show_usage; exit 1 ;;
        esac
        ;;
    logs)
        case $COMPONENT in
            prometheus) logs_prometheus ;;
            grafana) logs_grafana ;;
            opensearch) logs_opensearch ;;
            fluent-bit) logs_fluent_bit ;;
            *) echo -e "${RED}❌ Unknown component for logs: $COMPONENT${NC}"; show_usage; exit 1 ;;
        esac
        ;;
    restart)
        case $COMPONENT in
            prometheus) restart_prometheus ;;
            grafana) restart_grafana ;;
            opensearch) restart_opensearch ;;
            fluent-bit) restart_fluent_bit ;;
            all) restart_all ;;
            *) echo -e "${RED}❌ Unknown component: $COMPONENT${NC}"; show_usage; exit 1 ;;
        esac
        ;;
    *)
        echo -e "${RED}❌ Unknown action: $ACTION${NC}"
        show_usage
        exit 1
        ;;
esac
        ;;
esac
