# OpenSearch Log Discovery Configuration Guide

## 🔍 Overview

This guide walks you through configuring OpenSearch Dashboards for log discovery and creating visualizations in Grafana to monitor your K3s cluster logs and metrics.

## 📋 Prerequisites

Ensure the observability stack is deployed:
```bash
# Verify all components are running
./scripts/observability.sh status all

# Access URLs should be available:
# - OpenSearch Dashboards: http://opensearch.localhost
# - Grafana: http://grafana.localhost
```

## 📖 Detailed Configuration Guides

This guide provides a quick overview. For detailed step-by-step instructions, see:

- **[🔍 OpenSearch Log Discovery & Index Management](./OPENSEARCH_SETUP.md)** - Complete OpenSearch configuration
- **[📊 Grafana Dashboard Templates & Configuration](./GRAFANA_DASHBOARDS.md)** - Ready-to-import dashboards

---

## 🔍 OpenSearch Log Discovery Setup

### Step 1: Access OpenSearch Dashboards

1. Open your browser and navigate to: http://opensearch.localhost
2. You should see the OpenSearch Dashboards welcome screen

### Step 2: Create Index Pattern

1. **Navigate to Management**:
   - Click the hamburger menu (☰) in the top left
   - Go to **Management** → **Stack Management**
   - Select **Index Patterns**

2. **Create Index Pattern**:
   - Click **Create index pattern**
   - Enter index pattern: `k3s-logs-*`
   - Click **Next step**

3. **Configure Time Field**:
   - Select **@timestamp** as the time field
   - Click **Create index pattern**

### Step 3: Explore Your Logs

1. **Navigate to Discover**:
   - Click the hamburger menu (☰)
   - Go to **Analytics** → **Discover**

2. **View Logs**:
   - You should now see logs from all your K3s pods
   - Use the time picker in the top right to adjust the time range

### Step 4: Create Useful Filters

#### Filter by Namespace
```
kubernetes.namespace_name:database
```

#### Filter by Pod
```
kubernetes.pod_name:mysql-*
```

#### Filter by Log Level
```
level:ERROR OR level:error OR log:*ERROR* OR log:*error*
```

#### Filter by Service
```
kubernetes.labels.app:cloudbeaver
```

#### Combined Filter Example
```
kubernetes.namespace_name:database AND (level:ERROR OR log:*error*)
```

### Step 5: Save Useful Searches

1. **Create and Save Search**:
   - Apply your desired filters
   - Click **Save** in the top menu
   - Give it a name like "Database Errors"
   - Click **Save**

2. **Common Saved Searches to Create**:
   - **Database Logs**: `kubernetes.namespace_name:database`
   - **Error Logs**: `level:ERROR OR log:*ERROR*`
   - **MySQL Logs**: `kubernetes.pod_name:mysql-*`
   - **CloudBeaver Logs**: `kubernetes.labels.app:cloudbeaver`
   - **Prometheus Logs**: `kubernetes.namespace_name:development AND kubernetes.labels.app:prometheus`

---

## 📊 OpenSearch Dashboards Visualization

### Creating Log Volume Dashboard

1. **Navigate to Dashboard**:
   - Go to **Analytics** → **Dashboard**
   - Click **Create new dashboard**

2. **Add Log Count Visualization**:
   - Click **Add an existing** or **Create new**
   - Select **Vertical Bar** chart
   - Configure:
     - **Index**: k3s-logs-*
     - **Time field**: @timestamp
     - **Metrics**: Count
     - **Buckets**: Date Histogram on @timestamp

3. **Add Namespace Breakdown**:
   - Create a **Pie Chart**
   - Configure:
     - **Metrics**: Count
     - **Buckets**: Terms aggregation on `kubernetes.namespace_name.keyword`

4. **Add Log Level Distribution**:
   - Create another **Pie Chart**
   - Configure:
     - **Metrics**: Count
     - **Buckets**: Terms aggregation on `level.keyword`

### Creating Application-Specific Dashboards

#### Database Dashboard
1. **Create new dashboard** named "Database Services"
2. **Add panels for**:
   - MySQL log count over time
   - PostgreSQL log count over time
   - CloudBeaver access logs
   - Database error rate

#### Infrastructure Dashboard
1. **Create new dashboard** named "K3s Infrastructure"
2. **Add panels for**:
   - Logs by namespace
   - Pod restart events
   - System errors
   - Resource utilization logs

---

## 📈 Grafana Visualization Configuration

### Step 1: Access Grafana

1. Open your browser and navigate to: http://grafana.localhost
2. Login with credentials: **admin** / **1q2w3e4r@123**

### Step 2: Configure Data Sources

#### Add Prometheus Data Source

1. **Navigate to Data Sources**:
   - Click **Configuration** (gear icon) → **Data Sources**
   - Click **Add data source**

2. **Configure Prometheus**:
   - Select **Prometheus**
   - Set URL: `http://prometheus.development.svc.cluster.local:9090`
   - Click **Save & Test**

#### Add OpenSearch Data Source

1. **Add OpenSearch Data Source**:
   - Click **Add data source** again
   - Select **Elasticsearch** (OpenSearch is compatible)
   - Configure:
     - **URL**: `http://opensearch.logging.svc.cluster.local:9200`
     - **Index name**: `k3s-logs-*`
     - **Time field name**: `@timestamp`
     - **Version**: `7.10+`
   - Click **Save & Test**

### Step 3: Create Metrics Dashboards

#### Kubernetes Cluster Overview Dashboard

1. **Create New Dashboard**:
   - Click **+** → **Dashboard**
   - Click **Add new panel**

2. **CPU Usage Panel**:
   - **Data Source**: Select **Prometheus**
   - **Query**:
   ```promql
   # Query for CPU usage
   100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
   ```
   - **Panel Type**: Time series
   - **Unit**: Percent (0-100)

3. **Memory Usage Panel**:
   - **Data Source**: Select **Prometheus**
   - **Query**:
   ```promql
   # Query for memory usage
   (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
   ```
   - **Panel Type**: Time series
   - **Unit**: Percent (0-100)

4. **Pod Count Panel**:
   - **Data Source**: Select **Prometheus**
   - **Query**:
   ```promql
   # Query for pod count by namespace
   sum(kube_pod_info) by (namespace)
   ```
   - **Panel Type**: Stat or Bar chart
   - **Unit**: Short

5. **Container Restart Panel**:
   - **Data Source**: Select **Prometheus**
   - **Query**:
   ```promql
   # Query for container restarts
   increase(kube_pod_container_status_restarts_total[1h])
   ```
   - **Panel Type**: Stat
   - **Unit**: Short

#### Database Performance Dashboard

1. **Create New Dashboard** named "Database Performance"

2. **Database Connection Panel**:
   - **Data Source**: Select **Prometheus**
   - **Query**:
   ```promql
   # MySQL connections (if mysql-exporter is deployed)
   mysql_global_status_threads_connected
   ```
   - **Panel Type**: Stat
   - **Note**: This requires MySQL exporter to be deployed

3. **Query Performance Panel**:
   - **Data Source**: Select **Prometheus**
   - **Query**:
   ```promql
   # MySQL slow queries (if mysql-exporter is deployed)
   rate(mysql_global_status_slow_queries[5m])
   ```
   - **Panel Type**: Time series

4. **Database Size Panel**:
   - **Data Source**: Select **Prometheus**
   - **Query**:
   ```promql
   # Database size monitoring
   mysql_info_schema_table_size_data_length
   ```
   - **Panel Type**: Stat
   - **Unit**: Bytes

### Step 4: Create Log-Based Dashboards

#### Log Volume Dashboard

1. **Create New Dashboard** named "Log Analysis"

2. **Add Log Count Panel**:
   - **Data Source**: Select **Elasticsearch** (OpenSearch)
   - **Query**: `kubernetes.namespace_name:*`
   - **Visualization**: Time series
   - Configure:
     - **Metrics**: Count
     - **Group by**: Date Histogram on `@timestamp`

3. **Error Rate Panel**:
   - **Data Source**: Select **Elasticsearch** (OpenSearch)
   - **Query**: `level:ERROR OR log:*ERROR*`
   - **Visualization**: Stat
   - Show error percentage over time

4. **Top Namespaces Panel**:
   - **Data Source**: Select **Elasticsearch** (OpenSearch)
   - **Query**: `*`
   - **Visualization**: Bar chart
   - **Group by**: `kubernetes.namespace_name.keyword`

#### Application Log Dashboard

1. **Create New Dashboard** named "Application Logs"

2. **Database Service Logs**:
   - **Data Source**: Select **Elasticsearch** (OpenSearch)
   - **Query**: `kubernetes.namespace_name:database`
   - **Group by**: `kubernetes.pod_name.keyword`

3. **Error Log Table**:
   - **Data Source**: Select **Elasticsearch** (OpenSearch)
   - **Query**: `level:ERROR`
   - **Visualization**: Table
   - **Show**: timestamp, namespace, pod, message

### Step 5: Create Alerts

#### Prometheus Alerts

1. **Navigate to Alerting** → **Alert Rules**
2. **Create Rule** for High Error Rate:
   ```promql
   # Alert when error rate is high
   increase(prometheus_notifications_errors_total[5m]) > 0
   ```

3. **Create Rule** for Pod Restarts:
   ```promql
   # Alert on pod restarts
   increase(kube_pod_container_status_restarts_total[10m]) > 0
   ```

#### Log-Based Alerts

1. **Create Alert** for Database Errors:
   - Use OpenSearch data source
   - Query: `kubernetes.namespace_name:database AND (level:ERROR OR log:*ERROR*)`
   - Condition: Count > 5 in 5 minutes

2. **Create Alert** for High Log Volume:
   - Query: `*`
   - Condition: Count > 1000 in 1 minute

---

## 🎯 Pre-Built Dashboard Templates

### Import Ready-Made Dashboards

#### Kubernetes Cluster Dashboard
```json
{
  "dashboard": {
    "title": "K3s Cluster Overview",
    "panels": [
      {
        "title": "Cluster CPU Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "100 - (avg(irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
          }
        ]
      }
    ]
  }
}
```

#### Log Analysis Dashboard Template
Save this configuration and import into Grafana:

```bash
# Export current dashboard
curl -H "Authorization: Bearer <your-api-key>" \
     http://grafana.localhost/api/dashboards/db/k3s-logs

# Import dashboard
curl -X POST \
     -H "Authorization: Bearer <your-api-key>" \
     -H "Content-Type: application/json" \
     -d @dashboard.json \
     http://grafana.localhost/api/dashboards/db
```

---

## 🔧 Advanced Configuration

### Custom Log Parsers in Fluent Bit

Add custom parsers to better structure your logs:

```yaml
# Additional parser configuration
[PARSER]
    Name        mysql_error
    Format      regex
    Regex       ^(?<time>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z) (?<level>[^\s]+) (?<message>.*)$
    Time_Key    time
    Time_Format %Y-%m-%dT%H:%M:%S.%fZ

[PARSER]
    Name        cloudbeaver_log
    Format      regex
    Regex       ^(?<timestamp>\d{2}-\d{2}-\d{4} \d{2}:\d{2}:\d{2}\.\d+) \[(?<thread>[^\]]+)\] (?<level>\w+) (?<logger>[^\s]+) - (?<message>.*)$
    Time_Key    timestamp
    Time_Format %d-%m-%Y %H:%M:%S.%f
```

### OpenSearch Index Templates

Create index templates for better log structure:

```bash
# Create index template
kubectl exec -n logging deployment/opensearch -- curl -X PUT "localhost:9200/_index_template/k3s-logs-template" -H 'Content-Type: application/json' -d'
{
  "index_patterns": ["k3s-logs-*"],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "index.lifecycle.name": "k3s-logs-policy"
    },
    "mappings": {
      "properties": {
        "@timestamp": {
          "type": "date"
        },
        "kubernetes.namespace_name": {
          "type": "keyword"
        },
        "kubernetes.pod_name": {
          "type": "keyword"
        },
        "level": {
          "type": "keyword"
        },
        "log": {
          "type": "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 256
            }
          }
        }
      }
    }
  }
}'
```

### Grafana Dashboard Provisioning

Create dashboard configuration files:

```yaml
# grafana-dashboard-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards
  namespace: development
data:
  k3s-overview.json: |
    {
      "dashboard": {
        "title": "K3s Cluster Overview",
        "panels": [
          {
            "title": "Pod Count by Namespace",
            "type": "piechart",
            "targets": [
              {
                "expr": "sum(kube_pod_info) by (namespace)"
              }
            ]
          }
        ]
      }
    }
```

---

## 📊 Monitoring Best Practices

### Log Retention Policies

Configure log retention to manage storage:

```bash
# Set up index lifecycle policy
kubectl exec -n logging deployment/opensearch -- curl -X PUT "localhost:9200/_plugins/_ism/policies/k3s-logs-policy" -H 'Content-Type: application/json' -d'
{
  "policy": {
    "description": "K3s logs lifecycle policy",
    "default_state": "hot",
    "states": [
      {
        "name": "hot",
        "actions": [],
        "transitions": [
          {
            "state_name": "delete",
            "conditions": {
              "min_index_age": "7d"
            }
          }
        ]
      },
      {
        "name": "delete",
        "actions": [
          {
            "delete": {}
          }
        ]
      }
    ]
  }
}
'
```

### Performance Optimization

1. **Adjust Log Collection**:
   - Filter unnecessary logs in Fluent Bit
   - Use log sampling for high-volume applications
   - Configure proper buffer sizes

2. **OpenSearch Optimization**:
   - Monitor shard sizes
   - Configure appropriate refresh intervals
   - Use hot/warm architecture for large deployments

3. **Grafana Performance**:
   - Use recording rules for complex queries
   - Configure appropriate refresh intervals
   - Limit dashboard time ranges

---

## 🔍 Troubleshooting

### Common Issues

#### No Data in OpenSearch Dashboards
```bash
# Check if logs are being received
kubectl exec -n logging deployment/opensearch -- curl -s "http://localhost:9200/_cat/indices?v"

# Check Fluent Bit logs
kubectl logs -n logging daemonset/fluent-bit
```

#### Grafana Data Source Connection Issues
```bash
# Test Prometheus connectivity
kubectl exec -n development deployment/grafana -- curl -s http://prometheus:9090/api/v1/query?query=up

# Test OpenSearch connectivity
kubectl exec -n development deployment/grafana -- curl -s http://opensearch.logging.svc.cluster.local:9200/_cluster/health
```

#### Missing Kubernetes Metadata
```bash
# Check Fluent Bit Kubernetes filter configuration
kubectl get configmap -n logging fluent-bit-config -o yaml
```

---

## 📚 Quick Reference

### Useful OpenSearch Queries
```bash
# All database logs
kubernetes.namespace_name:database

# Error logs only
level:ERROR OR log:*ERROR* OR log:*error*

# MySQL specific logs
kubernetes.pod_name:mysql-* AND kubernetes.namespace_name:database

# CloudBeaver access logs
kubernetes.labels.app:cloudbeaver AND log:*API*

# Recent pod restarts
kubernetes.container_name:* AND log:*started*
```

### Useful Prometheus Queries
```promql
# Pod count by namespace
sum(kube_pod_info) by (namespace)

# Container restarts in last hour
increase(kube_pod_container_status_restarts_total[1h])

# Memory usage by pod
sum(container_memory_usage_bytes) by (pod)

# CPU usage by namespace
sum(rate(container_cpu_usage_seconds_total[5m])) by (namespace)
```

### Service URLs
- **OpenSearch Dashboards**: http://opensearch.localhost
- **Grafana**: http://grafana.localhost (admin/1q2w3e4r@123)
- **Prometheus**: http://prometheus.localhost

Your observability stack is now fully configured for comprehensive log discovery and visualization!
