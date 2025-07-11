# 🔍 Observability Quick Reference

Quick access guide for your K3s observability stack.

## 🔗 Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://grafana.localhost | admin / 1q2w3e4r@123 |
| **Prometheus** | http://prometheus.localhost | No auth |
| **OpenSearch** | http://opensearch.localhost | No auth |
| **OpenSearch API** | http://opensearch.localhost:9200 | No auth |

## ⚡ Quick Commands

```bash
# Check all services status
./scripts/observability.sh status all

# Deploy everything (includes kube-prometheus-stack)
./scripts/observability.sh deploy all

# Deploy only kube-prometheus-stack
./scripts/observability.sh deploy prometheus

# View logs
./scripts/observability.sh logs grafana
./scripts/observability.sh logs opensearch
./scripts/observability.sh logs fluent-bit

# Restart services
./scripts/observability.sh restart all

# Check Helm releases
helm list -n development
```

## 🔍 Common OpenSearch Queries

```bash
# Database logs only
kubernetes.namespace_name:database

# Error logs
level:ERROR OR log:*ERROR*

# MySQL logs
kubernetes.pod_name:mysql-*

# CloudBeaver logs
kubernetes.labels.app:cloudbeaver

# Last hour errors
level:ERROR AND @timestamp:>now-1h

# Connection issues
log:*connection* AND (log:*refused* OR log:*timeout*)
```

## 📊 Common Prometheus Queries

### System Metrics (from kube-prometheus-stack)
```promql
# CPU usage by node
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage by node
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Pod count by namespace
sum(kube_pod_info) by (namespace)

# Container restarts in last hour
increase(kube_pod_container_status_restarts_total[1h])

# Container CPU usage by pod
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)

# Container memory usage by pod
sum(container_memory_working_set_bytes) by (pod)

# Disk usage by node
100 - ((node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes)

# Network I/O by node
rate(node_network_receive_bytes_total[5m])
rate(node_network_transmit_bytes_total[5m])
```

### Kubernetes State Metrics
```promql
# Deployment status
kube_deployment_status_replicas_available / kube_deployment_spec_replicas

# Pod status by phase
sum(kube_pod_status_phase) by (phase)

# Node status
kube_node_status_condition{condition="Ready"}

# Persistent Volume usage
(kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes) * 100

# Service availability
up{job="kubernetes-services"}
```

## 🎯 First-Time Setup Checklist

### OpenSearch Dashboards
- [ ] Access http://opensearch.localhost
- [ ] Create index pattern: `k3s-logs-*`
- [ ] Set time field: `@timestamp`
- [ ] Save useful searches
- [ ] Create dashboards

### Grafana Setup
- [ ] Login to http://grafana.localhost
- [ ] Add Prometheus data source: `http://prometheus.development.svc.cluster.local:9090`
- [ ] Add OpenSearch data source: `http://opensearch.logging.svc.cluster.local:9200`
- [ ] Import dashboard templates
- [ ] Configure alerts

## 📚 Documentation Links

- [Complete Configuration Guide](./CONFIGURATION_GUIDE.md)
- [OpenSearch Setup Guide](./OPENSEARCH_SETUP.md)
- [Grafana Dashboard Templates](./GRAFANA_DASHBOARDS.md)
- [Main Observability README](./README.md)

## 🆘 Troubleshooting

### No logs in OpenSearch?
```bash
kubectl logs -n logging daemonset/fluent-bit
kubectl get pods -n logging
```

### Grafana won't connect to data sources?
```bash
# Test from inside Grafana pod
kubectl exec -n development deployment/grafana -- curl http://prometheus:9090/api/v1/query?query=up
kubectl exec -n development deployment/grafana -- curl http://opensearch.logging.svc.cluster.local:9200/_cluster/health
```

### Services not accessible?
```bash
# Check ingress
kubectl get ingress -A

# Check services
kubectl get svc -n development
kubectl get svc -n logging
```

## 📊 Sample Dashboard Import

Ready-to-use dashboard JSON available in [GRAFANA_DASHBOARDS.md](./GRAFANA_DASHBOARDS.md):

1. **K3s Cluster Overview** - General cluster monitoring
2. **Database Performance** - Database-specific metrics and logs  
3. **Application Log Analysis** - Comprehensive log analysis
4. **Infrastructure Monitoring** - System-level monitoring

Copy JSON → Grafana → Import → Paste → Import

## 🎯 Key Metrics to Monitor

### System Health
- CPU/Memory usage > 80%
- Disk usage > 90%
- Pod restart count > 0

### Application Health  
- Error rate > 5%
- Response time > 5s
- Failed connections > 0

### Log Patterns
- Error logs increasing
- Repeated error messages
- Authentication failures

---

**💡 Tip**: Bookmark this page for quick access to your observability stack!
