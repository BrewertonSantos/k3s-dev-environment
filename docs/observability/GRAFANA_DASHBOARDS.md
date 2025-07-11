# Grafana Dashboard Configuration Guide

## 🎯 Dashboard Creation Instructions

This document provides information about host IPs and step-by-step instructions for creating dashboards in your K3s observability stack.

## 🌐 Host IP Configuration

### Service Access Information

| Service | Host IP | Port | URL | Status |
|---------|---------|------|-----|--------|
| **Grafana** | 127.0.0.1 | 80 | http://grafana.localhost | ✅ Ready for dashboards |
| **Prometheus** | 127.0.0.1 | 80 | http://prometheus.localhost | ✅ Metrics source |
| **AlertManager** | 127.0.0.1 | 80 | http://alertmanager.localhost | ✅ Alert management |
| **OpenSearch** | 127.0.0.1 | 80 | http://opensearch.localhost | ✅ Log source |
| **CloudBeaver** | 127.0.0.1 | 80 | http://cloudbeaver.localhost | ✅ Database admin |

### Internal Service IPs (Kubernetes DNS)

| Service | Internal DNS | Port | Purpose |
|---------|--------------|------|---------|
| **Prometheus** | kube-prometheus-prometheus.development.svc.cluster.local | 9090 | Metrics API |
| **PostgreSQL** | postgres.database.svc.cluster.local | 5432 | Database queries |
| **MySQL** | mysql-service.database.svc.cluster.local | 3306 | Database queries |
| **OpenSearch** | opensearch.logging.svc.cluster.local | 9200 | Log queries |
| **Postgres Exporter** | postgres-exporter.database.svc.cluster.local | 9187 | DB metrics |
| **MySQL Exporter** | mysql-exporter.database.svc.cluster.local | 9104 | DB metrics |

## 📋 Dashboard Creation Steps

### Step 1: Access Grafana
```bash
# Open Grafana in your browser
open http://grafana.localhost

# Or get admin password if needed
kubectl get secret -n development grafana -o jsonpath='{.data.admin-password}' | base64 -d
```

### Step 2: Create New Dashboard
1. Click **+** (plus icon) in left sidebar
2. Select **Dashboard**
3. Click **Add new panel**
4. Configure your panel settings

### Step 3: Configure Data Sources
Before creating dashboards, verify these data sources are configured:

#### Prometheus Data Source
- **Name**: Prometheus
- **URL**: `http://kube-prometheus-prometheus.development.svc.cluster.local:9090`
- **Access**: Server (default)

#### PostgreSQL Data Source  
- **Name**: PostgreSQL
- **Host**: `postgres.database.svc.cluster.local:5432`
- **Database**: `{database}`
- **User**: `admin`
- **Password**: `1q2w3e4r@123`

#### MySQL Data Source
- **Name**: MySQL  
- **Host**: `mysql-service.database.svc.cluster.local`
- **Port**: `3306`
- **Database**: `{user}`
- **User**: `{user}`
- **Password**: `6DHq81M5PTFas0m2`

> **Important**: In Grafana's MySQL data source configuration:
> - **Host** field: Only put the hostname (no port number)
> - **Port** field: Enter the port number separately

### Step 3a: MySQL Data Source Configuration Details

When configuring the MySQL data source in Grafana:

1. **Go to**: Configuration → Data Sources → Add data source → MySQL
2. **Fill in these fields**:
   - **Name**: `MySQL`
   - **Host**: `mysql-service.database.svc.cluster.local` (hostname only)
   - **Port**: `3306` (separate field)
   - **Database**: `{user}`
   - **User**: `{user}`
   - **Password**: `6DHq81M5PTFas0m2`
   - **SSL Mode**: `disable` (for development)

3. **Click "Save & Test"** to verify the connection

> **⚠️ Common Mistake**: Don't include the port number in the Host field. Grafana has separate fields for Host and Port.

#### OpenSearch Data Source
- **Name**: OpenSearch
- **URL**: `http://opensearch.logging.svc.cluster.local:9200`
- **Index**: `k3s-logs-*`
- **Time field**: `@timestamp`

## 🔧 Dashboard Creation Guide

### Database Monitoring Dashboard

1. **Create PostgreSQL Panel**:
   - Panel Type: Stat or Time series
   - Query: `pg_database_size_bytes{datname="{database}"}`
   - Title: "PostgreSQL Database Size"

2. **Create MySQL Panel**:
   - Panel Type: Stat or Time series  
   - Query: `mysql_global_status_uptime`
   - Title: "MySQL Uptime"

3. **Create Connection Panel**:
   - Panel Type: Time series
   - Query: `pg_stat_database_numbackends{datname="{database}"}`
   - Title: "PostgreSQL Active Connections"

### Kubernetes Monitoring Dashboard

1. **Create Pod Status Panel**:
   - Panel Type: Stat
   - Query: `sum(kube_pod_info) by (namespace)`
   - Title: "Pods by Namespace"

2. **Create CPU Usage Panel**:
   - Panel Type: Time series
   - Query: `100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
   - Title: "CPU Usage %"

3. **Create Memory Usage Panel**:
   - Panel Type: Time series
   - Query: `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100`
   - Title: "Memory Usage %"

### Log Analysis Dashboard

1. **Create Error Count Panel**:
   - Panel Type: Stat
   - Data Source: OpenSearch
   - Query: `level:ERROR OR log:*ERROR*`
   - Title: "Error Count"

2. **Create Log Volume Panel**:
   - Panel Type: Time series
   - Data Source: OpenSearch
   - Query: `*`
   - Title: "Log Volume Over Time"

3. **Create Recent Logs Panel**:
   - Panel Type: Logs
   - Data Source: OpenSearch
   - Query: `kubernetes.namespace_name:database`
   - Title: "Database Logs"

## 📊 Available Metrics

### PostgreSQL Metrics (from postgres-exporter)
```promql
# Database size in bytes
pg_database_size_bytes{datname="{database}"}

# Active connections
pg_stat_database_numbackends{datname="{database}"}

# Transaction rate
rate(pg_stat_database_xact_commit{datname="{database}"}[5m])

# Database uptime
pg_postmaster_start_time_seconds
```

### MySQL Metrics (from mysql-exporter)
```promql
# Server uptime
mysql_global_status_uptime

# Connected threads
mysql_global_status_threads_connected

# Query rate
rate(mysql_global_status_queries[5m])

# InnoDB buffer pool hit ratio
mysql_global_status_innodb_buffer_pool_hit_ratio
```

### Kubernetes Metrics (from kube-state-metrics)
```promql
# Pod count by namespace
sum(kube_pod_info) by (namespace)

# Node status
kube_node_status_condition{condition="Ready",status="true"}

# Container restarts
rate(kube_pod_container_status_restarts_total[5m])

# Resource requests
kube_pod_container_resource_requests{resource="cpu"}
```

### System Metrics (from node-exporter)
```promql
# CPU usage
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk usage
100 - ((node_filesystem_avail_bytes{mountpoint="/"} * 100) / node_filesystem_size_bytes{mountpoint="/"})

# Network I/O
rate(node_network_receive_bytes_total[5m])
```

## 🔍 Log Queries for OpenSearch

### Database Error Logs
```
kubernetes.namespace_name:database AND (level:ERROR OR log:*ERROR*)
```

### Application Logs by Service
```
kubernetes.labels.app:cloudbeaver
kubernetes.labels.app:postgres-exporter
kubernetes.labels.app:mysql-exporter
```

### Recent Error Analysis
```
level:ERROR AND @timestamp:[now-1h TO now]
```

### Log Volume by Namespace
```
kubernetes.namespace_name:(development OR database OR logging)
```

## 🚨 Alert Configuration

### Database Alerts
1. **PostgreSQL Down**: `pg_up == 0`
2. **High Connections**: `pg_stat_database_numbackends / pg_settings_max_connections > 0.8`
3. **MySQL Down**: `mysql_up == 0`
4. **Slow Queries**: `rate(mysql_global_status_slow_queries[5m]) > 0.1`

### System Alerts  
1. **High CPU**: `100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80`
2. **High Memory**: `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90`
3. **Disk Space**: `100 - ((node_filesystem_avail_bytes{mountpoint="/"} * 100) / node_filesystem_size_bytes{mountpoint="/"}) > 85`

## 🔧 Troubleshooting Dashboard Creation

### Common Issues

#### Data Source Connection Failed
```bash
# Test Prometheus connectivity
kubectl port-forward -n development service/kube-prometheus-prometheus 9090:9090
curl http://localhost:9090/api/v1/status/config

# Test database connectivity  
kubectl port-forward -n database service/postgres 5432:5432
psql -h localhost -U admin -d {database}
```

#### No Metrics Available
```bash
# Check exporter status
kubectl get pods -n database
kubectl logs -n database deployment/postgres-exporter
kubectl logs -n database deployment/mysql-exporter

# Verify ServiceMonitor
kubectl get servicemonitor -n database
```

#### OpenSearch Logs Not Showing
```bash
# Check OpenSearch status
kubectl get pods -n logging
kubectl logs -n logging deployment/opensearch

# Test log ingestion
kubectl logs -n database deployment/postgres --tail=10
```

## ✅ **MySQL Metrics Fix Applied**

If MySQL metrics are not appearing in Grafana, this is usually due to authentication issues with the MySQL exporter. The fix has been applied with the following changes:

### Fixed MySQL Exporter Configuration
- **Authentication Method**: Uses `.my.cnf` configuration file instead of DATA_SOURCE_NAME
- **Connection String**: Properly formatted with credentials
- **Collectors**: Enabled essential metric collectors

### Verification Steps
```bash
# Check MySQL exporter pod is running
kubectl get pods -n database | grep mysql-exporter

# Check logs for any errors
kubectl logs -n database deployment/mysql-exporter

# Test metrics endpoint
kubectl port-forward -n database service/mysql-exporter 9104:9104 &
curl http://localhost:9104/metrics | grep mysql_global_status_uptime
```

### Available MySQL Metrics After Fix
- `mysql_global_status_uptime` - Server uptime
- `mysql_global_status_threads_connected` - Active connections  
- `mysql_global_status_queries` - Total queries executed
- `mysql_global_variables_max_connections` - Maximum connections allowed
- And many more database performance metrics

## Dashboard Best Practices

1. **Use appropriate time ranges** (1h, 6h, 24h)
2. **Set refresh intervals** (30s for real-time, 5m for historical)
3. **Add panel descriptions** for clarity
4. **Use consistent colors** across related metrics
5. **Group related panels** together
6. **Set appropriate thresholds** for alerts

### Manual Dashboard Creation Steps

1. **Open Grafana**: http://grafana.localhost
2. **Login**: admin / [get password from secret]
3. **Add Panel**: Click + → Dashboard → Add Panel
4. **Select Data Source**: Choose Prometheus, PostgreSQL, MySQL, or OpenSearch
5. **Enter Query**: Use the metrics listed above
6. **Configure Visualization**: Choose appropriate panel type
7. **Set Title and Description**: Make it clear and descriptive
8. **Save Dashboard**: Give it a meaningful name and tags

Your dashboards will now display real-time monitoring data from your K3s environment!
