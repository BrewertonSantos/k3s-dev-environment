# Observability Stack Documentation

## 🔍 Overview

The K3s development environment now includes a complete observability stack for monitoring, metrics, and log analysis:

- **Prometheus**: Metrics collection and alerting
- **Grafana**: Metrics visualization and dashboards  
- **OpenSearch**: Log aggregation, search, and analysis
- **Fluent Bit**: Log collection from all cluster pods
- **OpenSearch Dashboards**: Log visualization and analysis

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Observability Stack                         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Fluent Bit    │    │    Prometheus    │    │     Grafana     │
│   (Log Collect) │    │   (Metrics)      │    │ (Visualization) │
│   DaemonSet     │    │   development    │    │   development   │
│   logging       │    │   namespace      │    │   namespace     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Traefik Ingress                           │
│   grafana.localhost | prometheus.localhost | opensearch.localhost │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐
│   OpenSearch    │    │  OpenSearch      │
│   (Log Storage) │◄───┤  Dashboards      │
│   logging       │    │  (Log Analysis)  │
│   namespace     │    │  logging         │
└─────────────────┘    └──────────────────┘
```

## 🚀 Quick Start

### Deploy Complete Observability Stack

```bash
# Deploy all components
./scripts/observability.sh deploy all

# Check status
./scripts/observability.sh status all

# Update hosts file (if not done already)
./scripts/setup-hosts.sh
```

### Access Observability Tools

| Tool | URL | Credentials |
|------|-----|-------------|
| **Grafana** | http://grafana.localhost | admin / 1q2w3e4r@123 |
| **Prometheus** | http://prometheus.localhost | No auth required |
| **OpenSearch Logs** | http://opensearch.localhost | No auth required |
| **Log Viewer** | http://logs.localhost | No auth required |

### 📖 Configuration Guides

> **⭐ Complete Monitoring Setup**: [Kube-Prometheus-Stack Complete Guide](./KUBE_PROMETHEUS_STACK.md)  
> Comprehensive documentation for the complete Kubernetes monitoring stack with kube-prometheus-stack.

> **📊 Metrics Reference**: [Complete Metrics Catalog](./METRICS_CATALOG.md)  
> Detailed catalog of all available metrics, queries, and dashboards for comprehensive monitoring.

> **🔍 Log Management**: [OpenSearch Log Discovery & Grafana Visualization Configuration](./CONFIGURATION_GUIDE.md)  
> Step-by-step instructions for configuring log discovery, creating dashboards, and setting up alerts.

### Additional Documentation
- [Prometheus Monitoring Setup](../prometheus/README.md)
- [Grafana Dashboard Creation](../grafana/README.md)
- [OpenSearch Log Management](../opensearch/README.md)

## 📊 Components

### Prometheus (Metrics Collection)
- **Namespace**: `development`
- **Type**: kube-prometheus-stack (Helm chart)
- **Components**: Prometheus Operator, Prometheus Server, AlertManager, Node Exporter, Kube State Metrics
- **Purpose**: Complete Kubernetes monitoring solution
- **Storage**: 10Gi persistent volume for Prometheus data
- **Scrape Interval**: 15 seconds
- **Retention**: 30 days
- **Access**: http://prometheus.localhost (Prometheus), http://alertmanager.localhost (AlertManager)
- **Documentation**: [Complete Guide](./KUBE_PROMETHEUS_STACK.md)

#### Comprehensive Metrics Coverage
- **System Metrics**: CPU, memory, disk, network from all nodes (Node Exporter)
- **Kubernetes State**: Pod status, deployment health, resource usage (Kube State Metrics)
- **Container Metrics**: Per-container resource usage (cAdvisor)
- **Cluster Health**: API server, scheduler, controller manager metrics
- **Custom Application Metrics**: Via prometheus.io/scrape annotations

### Grafana (Visualization)
- **Namespace**: `development`
- **Purpose**: Creates dashboards and visualizes metrics
- **Storage**: 2Gi persistent volume
- **Default Admin**: admin / 1q2w3e4r@123

#### Pre-configured Data Sources
- **Prometheus**: http://kube-prometheus-stack-prometheus.development.svc.cluster.local:9090 (kube-prometheus-stack metrics)
- **OpenSearch**: Connected for log analysis and correlation

### OpenSearch (Log Storage)
- **Namespace**: `logging`
- **Purpose**: Stores, indexes, and searches logs
- **Storage**: 10Gi persistent volume
- **Security**: Disabled for development (no authentication)

#### Index Pattern
- **Format**: `k3s-logs-YYYY.MM.DD`
- **Fields**: timestamp, kubernetes metadata, log content
- **Retention**: Based on storage capacity

### OpenSearch Dashboards (Log Analysis)
- **Namespace**: `logging`
- **Purpose**: Log visualization and analysis interface
- **Integration**: Connected to OpenSearch cluster

### Fluent Bit (Log Collection)
- **Deployment**: DaemonSet (runs on all nodes)
- **Purpose**: Collects logs from all containers
- **Namespace**: `logging`
- **Log Sources**: `/var/log/containers/*.log`

#### Log Processing Pipeline
1. **Input**: Tail container logs
2. **Filter**: Add Kubernetes metadata
3. **Filter**: Add cluster and environment tags
4. **Output**: Send to OpenSearch

## 📊 Available Metrics Overview

### Sistema e Infraestrutura (Node Exporter)
- **CPU**: Utilização por core, load average, idle time
- **Memória**: Total, disponível, buffers, cache, swap
- **Disco**: Uso por filesystem, I/O operations, latência
- **Rede**: Bytes transmitidos/recebidos, packets, erros
- **Sistema**: Uptime, processos, file descriptors

### Estado do Kubernetes (Kube State Metrics)
- **Pods**: Status, fase, reinicializações, resources requests/limits
- **Deployments**: Réplicas disponíveis vs desejadas, status de rollout
- **Services**: Endpoints, tipos, seletores
- **Nodes**: Status Ready, recursos alocáveis vs capacity
- **Persistent Volumes**: Status, fases, capacity

### Containers (cAdvisor)
- **Resources**: CPU, memória, rede, filesystem por container
- **Performance**: Throttling, OOM kills, limits vs usage
- **Network**: Traffic por container e pod

### Métricas de Aplicação
- **Custom Metrics**: Via anotações prometheus.io/scrape
- **Health Checks**: Endpoints /metrics expostos pelas aplicações
- **Business Metrics**: Métricas específicas do domínio da aplicação

### Queries Populares

#### Performance
```promql
# Top pods por CPU
topk(10, sum(rate(container_cpu_usage_seconds_total[5m])) by (pod))

# Top pods por memória  
topk(10, sum(container_memory_working_set_bytes) by (pod))

# Uso de CPU por node
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

#### Health Check
```promql
# Pods não Ready
sum(kube_pod_status_phase{phase!="Running"}) by (namespace, phase)

# Containers com restart loop
increase(kube_pod_container_status_restarts_total[1h]) > 5

# Nodes não Ready
sum(kube_node_status_condition{condition="Ready", status!="true"})
```

## 🔧 Management Script

The `observability.sh` script provides comprehensive management:

### Available Actions

```bash
# Deploy components
./scripts/observability.sh deploy all
./scripts/observability.sh deploy prometheus
./scripts/observability.sh deploy grafana
./scripts/observability.sh deploy opensearch
./scripts/observability.sh deploy fluent-bit

# Check status
./scripts/observability.sh status all
./scripts/observability.sh status prometheus

# View logs
./scripts/observability.sh logs grafana
./scripts/observability.sh logs opensearch

# Restart components
./scripts/observability.sh restart all
./scripts/observability.sh restart fluent-bit

# Clean up
./scripts/observability.sh cleanup all
./scripts/observability.sh cleanup opensearch
```

## 📈 Monitoring Setup

### Prometheus Configuration

Default scrape targets include:
- `prometheus:9090` - Prometheus itself
- `kubernetes-pods` - All pods with `prometheus.io/scrape: "true"` annotation

### Adding Custom Metrics

To expose metrics from your applications:

1. **Add annotations to your pod**:
```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
```

2. **Expose metrics endpoint** in your application
3. **Prometheus will automatically discover** and scrape your metrics

### Database Metrics

The database components (MySQL, PostgreSQL) can be monitored by:

1. **Adding exporters** (mysql-exporter, postgres-exporter)
2. **Configuring scrape targets** in Prometheus
3. **Creating Grafana dashboards** for database metrics

## 📝 Log Analysis

### OpenSearch Index Management

```bash
# View all indices
kubectl exec -n logging deployment/opensearch -- curl -s "http://localhost:9200/_cat/indices?v"

# Check index stats
kubectl exec -n logging deployment/opensearch -- curl -s "http://localhost:9200/k3s-logs-*/_stats"

# Search logs (example)
kubectl exec -n logging deployment/opensearch -- curl -s -X GET "http://localhost:9200/k3s-logs-*/_search?pretty&q=kubernetes.namespace_name:database"
```

### Log Query Examples

In OpenSearch Dashboards (http://opensearch.localhost):

1. **Filter by namespace**: `kubernetes.namespace_name:database`
2. **Filter by pod**: `kubernetes.pod_name:mysql-*`
3. **Filter by log level**: `level:ERROR`
4. **Time range**: Last 1 hour, 24 hours, etc.

### Creating Log Dashboards

1. Access OpenSearch Dashboards
2. Go to "Management" → "Index Patterns"
3. Create pattern: `k3s-logs-*`
4. Set time field: `@timestamp`
5. Go to "Discover" to explore logs
6. Create visualizations and dashboards

## 🔍 Troubleshooting

### Common Issues

#### Prometheus Not Scraping Metrics
```bash
# Check Prometheus targets
curl http://prometheus.localhost/targets

# Check pod annotations
kubectl get pod <pod-name> -o yaml | grep annotations -A 5
```

#### Grafana Login Issues
```bash
# Reset Grafana admin password
kubectl exec -n development deployment/grafana -- grafana-cli admin reset-admin-password newpassword
```

#### OpenSearch Not Receiving Logs
```bash
# Check Fluent Bit logs
./scripts/observability.sh logs fluent-bit

# Check OpenSearch connectivity
kubectl exec -n logging deployment/opensearch -- curl -s "http://localhost:9200/_cluster/health"

# Verify log indices
kubectl exec -n logging deployment/opensearch -- curl -s "http://localhost:9200/_cat/indices?v"
```

#### Storage Issues
```bash
# Check persistent volumes
kubectl get pv,pvc -A

# Check storage usage
kubectl exec -n development deployment/prometheus -- df -h /prometheus
kubectl exec -n logging deployment/opensearch -- df -h /usr/share/opensearch/data
```

### Debug Commands

```bash
# View component logs
kubectl logs -n development deployment/prometheus --tail=50
kubectl logs -n development deployment/grafana --tail=50
kubectl logs -n logging deployment/opensearch --tail=50
kubectl logs -n logging daemonset/fluent-bit --tail=50

# Check service connectivity
kubectl get svc -n development
kubectl get svc -n logging

# Test internal connectivity
kubectl exec -n development deployment/grafana -- curl -s http://prometheus:9090/api/v1/label/__name__/values
kubectl exec -n logging deployment/opensearch-dashboards -- curl -s http://opensearch:9200/_cluster/health
```

## 📊 Dashboard Templates

### Grafana Dashboard Ideas

1. **Kubernetes Cluster Overview**
   - Node CPU/Memory usage
   - Pod count by namespace
   - Storage usage

2. **Application Performance**
   - Request rate
   - Response time
   - Error rate

3. **Database Monitoring**
   - Connection count
   - Query performance
   - Replication lag

4. **Infrastructure Health**
   - Disk I/O
   - Network traffic
   - System load

### OpenSearch Dashboard Ideas

1. **Log Volume Analysis**
   - Logs per hour/day
   - Logs by namespace
   - Error rate trends

2. **Application Logs**
   - Error log dashboard
   - Access log analysis
   - Security events

3. **Infrastructure Logs**
   - System events
   - Kubernetes events
   - Container lifecycle

## 🔒 Security Considerations

### Development Environment
⚠️ **Current configuration is for development only**

- OpenSearch security is disabled
- Grafana uses default credentials
- No authentication on Prometheus
- HTTP-only ingress

### Production Recommendations

1. **Enable OpenSearch Security**
   - Configure authentication
   - Set up role-based access
   - Enable TLS

2. **Secure Grafana**
   - Change default credentials
   - Configure LDAP/OAuth
   - Enable HTTPS

3. **Prometheus Security**
   - Enable authentication
   - Configure TLS
   - Implement network policies

4. **Network Security**
   - Use network policies
   - Implement service mesh
   - Enable pod security standards

## 📋 Maintenance

### Regular Tasks

```bash
# Check system health
./scripts/observability.sh status all

# Monitor storage usage
kubectl exec -n logging deployment/opensearch -- du -sh /usr/share/opensearch/data

# Cleanup old logs (manual)
kubectl exec -n logging deployment/opensearch -- curl -X DELETE "http://localhost:9200/k3s-logs-$(date -d '7 days ago' '+%Y.%m.%d')"

# Backup Grafana dashboards
kubectl get configmap -n development grafana-dashboard-config -o yaml > grafana-dashboards-backup.yaml
```

### Performance Tuning

1. **OpenSearch**
   - Adjust JVM heap size
   - Configure index lifecycle policies
   - Optimize mapping templates

2. **Prometheus**
   - Tune scrape intervals
   - Configure recording rules
   - Adjust retention policies

3. **Fluent Bit**
   - Configure buffer sizes
   - Adjust flush intervals
   - Filter unnecessary logs

---

## 🎯 Quick Reference

### Essential URLs
- **Grafana**: http://grafana.localhost (admin/1q2w3e4r@123)
- **Prometheus**: http://prometheus.localhost
- **OpenSearch**: http://opensearch.localhost
- **Logs**: http://logs.localhost

### Essential Commands
```bash
# Deploy everything
./scripts/observability.sh deploy all

# Check status
./scripts/observability.sh status all

# View logs
./scripts/observability.sh logs fluent-bit

# Restart if needed
./scripts/observability.sh restart all
```

### Log Search Tips
- Namespace filter: `kubernetes.namespace_name:database`
- Pod filter: `kubernetes.pod_name:mysql-*`
- Error logs: `level:ERROR OR level:error`
- Time range: Use the time picker in OpenSearch Dashboards

The observability stack is now collecting metrics and logs from all services in your K3s cluster!
