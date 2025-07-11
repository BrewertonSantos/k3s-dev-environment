# Database Monitoring Infrastructure

## Overview

This document provides comprehensive details about the database monitoring infrastructure implemented in the K3s development environment. It covers PostgreSQL and MySQL monitoring using Prometheus exporters with detailed metrics collection.

## Architecture

### Monitoring Components

```mermaid
graph TB
    subgraph "Database Namespace"
        PG[PostgreSQL<br/>postgres:16]
        MySQL[MySQL<br/>mysql:8.0]
        CB[CloudBeaver<br/>cloudbeaver:24.0.0]
        
        PGExp[postgres-exporter<br/>v0.15.0]
        MySQLExp[mysqld-exporter<br/>v0.15.1]
    end
    
    subgraph "Development Namespace"
        Prom[Prometheus<br/>kube-prometheus-stack]
        Graf[Grafana<br/>9.x]
    end
    
    PGExp -->|metrics| PG
    MySQLExp -->|metrics| MySQL
    
    Prom -->|scrape 30s| PGExp
    Prom -->|scrape 30s| MySQLExp
    Prom -->|health check 60s| CB
    
    Graf -->|queries| Prom
    Graf -->|direct SQL| PG
    Graf -->|direct SQL| MySQL
    
    style PG fill:#336791
    style MySQL fill:#4479A1
    style CB fill:#FF6B6B
    style PGExp fill:#E74C3C
    style MySQLExp fill:#E74C3C
    style Prom fill:#E6522C
    style Graf fill:#F46800
```

## PostgreSQL Monitoring

### Exporter Configuration

The PostgreSQL exporter is configured with a simplified approach for reliability:

```yaml
# postgres-exporter-fixed.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-exporter
  namespace: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres-exporter
  template:
    metadata:
      labels:
        app: postgres-exporter
    spec:
      containers:
      - name: postgres-exporter
        image: prometheuscommunity/postgres-exporter:v0.15.0
        ports:
        - containerPort: 9187
          name: metrics
        env:
        - name: DATA_SOURCE_NAME
          valueFrom:
            secretKeyRef:
              name: postgres-exporter-secret
              key: connection-string
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
```

### Connection Configuration

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-exporter-secret
  namespace: database
type: Opaque
data:
  connection-string: cG9zdGdyZXNxbDovL2FkbWluOjFxMnczZTRyQDEyM0Bwb3N0Z3Jlcy5kYXRhYmFzZS5zdmMuY2x1c3Rlci5sb2NhbDo1NDMyL2RldmRiP3NzbG1vZGU9ZGlzYWJsZQ==
```

**Decoded Connection String:**
```
postgresql://admin:1q2w3e4r@123@postgres.database.svc.cluster.local:5432/{database}?sslmode=disable
```

### Available Metrics

#### Database Size Metrics
```promql
# Total database size in bytes
pg_database_size_bytes{datname="{database}"}

# Number of tables in database
pg_stat_user_tables_reltuples
```

#### Connection Metrics
```promql
# Active connections to database
pg_stat_database_numbackends{datname="{database}"}

# Maximum connections allowed
pg_settings_max_connections

# Connection usage percentage
(pg_stat_database_numbackends{datname="{database}"} / pg_settings_max_connections) * 100
```

#### Transaction Metrics
```promql
# Committed transactions rate
rate(pg_stat_database_xact_commit{datname="{database}"}[5m])

# Rolled back transactions rate
rate(pg_stat_database_xact_rollback{datname="{database}"}[5m])

# Transaction error rate
rate(pg_stat_database_xact_rollback{datname="{database}"}[5m]) / rate(pg_stat_database_xact_commit{datname="{database}"}[5m])
```

#### Lock Metrics
```promql
# Current locks count
pg_locks_count

# Lock types distribution
pg_locks_count by (mode)
```

### Dashboard Queries

#### PostgreSQL Overview Panel
```promql
# Database uptime
pg_postmaster_start_time_seconds

# Database size trend
pg_database_size_bytes{datname="{database}"}

# Active connections
pg_stat_database_numbackends{datname="{database}"}

# Transactions per second
rate(pg_stat_database_xact_commit{datname="{database}"}[1m])
```

## MySQL Monitoring

### Exporter Configuration

The MySQL exporter includes comprehensive collectors for detailed monitoring:

```yaml
# mysql-exporter-fixed.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql-exporter
  namespace: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql-exporter
  template:
    metadata:
      labels:
        app: mysql-exporter
    spec:
      containers:
      - name: mysql-exporter
        image: prom/mysqld-exporter:v0.15.1
        ports:
        - containerPort: 9104
          name: metrics
        env:
        - name: DATA_SOURCE_NAME
          value: "{user}:6DHq81M5PTFas0m2@(mysql-service.database.svc.cluster.local:3306)/{user}"
        args:
        - "--collect.global_status"
        - "--collect.global_variables"
        - "--collect.slave_status"
        - "--collect.info_schema.innodb_metrics"
        - "--collect.info_schema.innodb_tablespaces"
        - "--collect.info_schema.innodb_cmp"
        - "--collect.info_schema.innodb_cmpmem"
        - "--collect.info_schema.processlist"
        - "--collect.info_schema.tables"
        - "--collect.info_schema.tablestats"
        - "--collect.info_schema.userstats"
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
```

### Available Metrics

#### Connection Metrics
```promql
# Current connections
mysql_global_status_threads_connected

# Connection usage percentage
(mysql_global_status_threads_connected / mysql_global_variables_max_connections) * 100

# Connections per second
rate(mysql_global_status_connections[1m])
```

#### Performance Metrics
```promql
# Queries per second
rate(mysql_global_status_queries[1m])

# Uptime
mysql_global_status_uptime

# Query cache hit rate
mysql_global_status_qcache_hit_ratio
```

#### InnoDB Metrics
```promql
# Buffer pool hit ratio
mysql_global_status_innodb_buffer_pool_hit_ratio

# Buffer pool size
mysql_global_variables_innodb_buffer_pool_size

# InnoDB data read/written
rate(mysql_global_status_innodb_data_read[1m])
rate(mysql_global_status_innodb_data_written[1m])
```

#### Table Statistics
```promql
# Table sizes by schema
mysql_info_schema_table_size by (schema, table)

# Row counts by table
mysql_info_schema_table_rows by (schema, table)
```

### Dashboard Queries

#### MySQL Overview Panel
```promql
# Server uptime
mysql_global_status_uptime

# Query rate
rate(mysql_global_status_queries[5m])

# Connection count
mysql_global_status_threads_connected

# InnoDB buffer pool efficiency
mysql_global_status_innodb_buffer_pool_hit_ratio
```

## ServiceMonitor Configuration

### Prometheus Discovery

The ServiceMonitor CRDs enable automatic discovery by Prometheus:

```yaml
# database-servicemonitors.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: postgres-exporter
  namespace: database
  labels:
    app: postgres-exporter
spec:
  selector:
    matchLabels:
      app: postgres-exporter
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: mysql-exporter
  namespace: database
  labels:
    app: mysql-exporter
spec:
  selector:
    matchLabels:
      app: mysql-exporter
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: cloudbeaver-monitor
  namespace: database
  labels:
    app: cloudbeaver
spec:
  selector:
    matchLabels:
      app: cloudbeaver
  endpoints:
  - port: http
    interval: 60s
    path: /api/health
```

## Grafana Integration

### Data Source Configuration

Grafana is configured with multiple data sources for comprehensive monitoring:

```yaml
# grafana-datasources.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
  namespace: development
  labels:
    grafana_datasource: "1"
data:
  datasources.yaml: |
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      access: proxy
      url: http://kube-prometheus-prometheus.development.svc.cluster.local:9090
      isDefault: true
      
    - name: PostgreSQL
      type: postgres
      access: proxy
      url: postgres.database.svc.cluster.local:5432
      database: {database}
      user: admin
      secureJsonData:
        password: "1q2w3e4r@123"
      jsonData:
        sslmode: "disable"
        
    - name: MySQL
      type: mysql
      access: proxy
      url: mysql-service.database.svc.cluster.local:3306
      database: {user}
      user: {user}
      secureJsonData:
        password: "6DHq81M5PTFas0m2"
```

### Pre-built Dashboards

#### PostgreSQL Dashboard Panels

1. **Database Overview**
   - Database size over time
   - Active connections
   - Transaction rate
   - Lock count

2. **Performance Metrics**
   - Query execution time
   - Cache hit ratio
   - Disk I/O statistics
   - Table statistics

3. **Connection Analysis**
   - Connection distribution
   - Long-running queries
   - Idle connections

#### MySQL Dashboard Panels

1. **Server Overview**
   - Uptime and availability
   - Query rate and latency
   - Connection utilization
   - Error rate

2. **InnoDB Engine**
   - Buffer pool efficiency
   - Deadlock statistics
   - Transaction throughput
   - Lock contention

3. **Table Analytics**
   - Table sizes and growth
   - Index usage statistics
   - Row counts and changes

## Alerting Rules

### PostgreSQL Alerts

```yaml
groups:
- name: postgresql.rules
  rules:
  - alert: PostgreSQLDown
    expr: pg_up == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "PostgreSQL is down"
      description: "PostgreSQL database is down for more than 1 minute"

  - alert: PostgreSQLTooManyConnections
    expr: pg_stat_database_numbackends / pg_settings_max_connections > 0.8
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "PostgreSQL too many connections"
      description: "PostgreSQL has more than 80% of max connections used"

  - alert: PostgreSQLDatabaseSizeGrowth
    expr: increase(pg_database_size_bytes[1h]) > 1073741824  # 1GB
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "PostgreSQL database growing rapidly"
      description: "Database size increased by more than 1GB in the last hour"
```

### MySQL Alerts

```yaml
groups:
- name: mysql.rules
  rules:
  - alert: MySQLDown
    expr: mysql_up == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "MySQL is down"
      description: "MySQL database is down for more than 1 minute"

  - alert: MySQLSlowQueries
    expr: rate(mysql_global_status_slow_queries[5m]) > 0.1
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "MySQL slow queries detected"
      description: "MySQL is experiencing slow queries above threshold"

  - alert: MySQLInnoDBLockWaits
    expr: mysql_global_status_innodb_lock_time_avg > 1000
    for: 1m
    labels:
      severity: warning
    annotations:
      summary: "MySQL InnoDB lock waits high"
      description: "InnoDB lock wait time is above 1 second"
```

## Troubleshooting

### Common Issues

#### Exporter Connection Failures

**Symptoms:**
- Metrics not appearing in Prometheus
- Connection refused errors in exporter logs

**Resolution:**
```bash
# Check service connectivity
kubectl exec -n database deployment/postgres-exporter -- nslookup postgres.database.svc.cluster.local

# Verify secret configuration
kubectl get secret -n database postgres-exporter-secret -o yaml

# Test database connection manually
kubectl exec -n database deployment/postgres -- psql -U admin -d {database} -c "SELECT version();"
```

#### ServiceMonitor Not Discovered

**Symptoms:**
- Targets not appearing in Prometheus
- ServiceMonitor exists but not scraped

**Resolution:**
```bash
# Check ServiceMonitor labels
kubectl get servicemonitor -n database -o yaml

# Verify Prometheus configuration
kubectl get prometheus -n development -o yaml | grep serviceMonitorSelector

# Check service labels match ServiceMonitor selector
kubectl get service -n database --show-labels
```

#### Grafana Data Source Issues

**Symptoms:**
- Data source test fails
- No data in dashboards

**Resolution:**
```bash
# Test data source connectivity from Grafana pod
kubectl exec -n development deployment/grafana -- curl prometheus:9090/api/v1/status/config

# Check data source configuration
kubectl logs -n development deployment/grafana | grep datasource

# Verify database connectivity
kubectl exec -n development deployment/grafana -- nslookup postgres.database.svc.cluster.local
```

### Performance Tuning

#### Exporter Resource Optimization

```yaml
# Resource limits based on monitoring load
resources:
  requests:
    memory: "64Mi"    # Minimum for basic operation
    cpu: "50m"        # Low CPU usage for exporters
  limits:
    memory: "128Mi"   # Sufficient for metric caching
    cpu: "100m"       # Burst capacity for scraping
```

#### Scrape Interval Tuning

```yaml
# Balance between data freshness and load
endpoints:
- port: metrics
  interval: 30s       # Standard for most metrics
  scrapeTimeout: 10s  # Prevent hanging scrapes
```

### Maintenance Tasks

#### Metric Retention Management

```bash
# Check Prometheus storage usage
kubectl exec -n development prometheus-kube-prometheus-prometheus-0 -- df -h /prometheus

# Monitor metric cardinality
kubectl port-forward -n development service/kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090/tsdb-status
```

#### Exporter Updates

```bash
# Update PostgreSQL exporter
kubectl set image deployment/postgres-exporter -n database postgres-exporter=prometheuscommunity/postgres-exporter:v0.15.1

# Update MySQL exporter
kubectl set image deployment/mysql-exporter -n database mysql-exporter=prom/mysqld-exporter:v0.15.2

# Verify rollout
kubectl rollout status deployment/postgres-exporter -n database
```

#### Database Connection Monitoring

```bash
# Monitor exporter logs for connection issues
kubectl logs -n database deployment/postgres-exporter --tail=100 -f

# Check connection pool status
kubectl exec -n database deployment/postgres -- psql -U admin -d {database} -c "SELECT * FROM pg_stat_activity WHERE state = 'active';"
```

## Security Considerations

### Connection Security

- **SSL/TLS**: Disabled for development environment
- **Authentication**: Service-to-service within cluster
- **Network Policies**: Database namespace isolation
- **Secrets Management**: Kubernetes secrets for credentials

### Access Control

```yaml
# Role-based access for monitoring namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: database
  name: exporter-reader
rules:
- apiGroups: [""]
  resources: ["pods", "services", "endpoints"]
  verbs: ["get", "list", "watch"]
```

### Credential Rotation

```bash
# Update PostgreSQL exporter credentials
kubectl create secret generic postgres-exporter-secret \
  --from-literal=connection-string="postgresql://newuser:newpass@postgres.database.svc.cluster.local:5432/{database}?sslmode=disable" \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart exporter to use new credentials
kubectl rollout restart deployment/postgres-exporter -n database
```

## Integration Testing

### Automated Validation

```bash
#!/bin/bash
# validate-database-monitoring.sh

echo "Testing PostgreSQL Exporter..."
kubectl port-forward -n database service/postgres-exporter 9187:9187 &
PG_PID=$!
sleep 5

# Test metrics endpoint
if curl -s http://localhost:9187/metrics | grep -q "pg_database_size_bytes"; then
    echo "✅ PostgreSQL metrics available"
else
    echo "❌ PostgreSQL metrics missing"
fi

kill $PG_PID

echo "Testing MySQL Exporter..."
kubectl port-forward -n database service/mysql-exporter 9104:9104 &
MYSQL_PID=$!
sleep 5

# Test metrics endpoint
if curl -s http://localhost:9104/metrics | grep -q "mysql_global_status_uptime"; then
    echo "✅ MySQL metrics available"
else
    echo "❌ MySQL metrics missing"
fi

kill $MYSQL_PID

echo "Testing Prometheus Targets..."
kubectl port-forward -n development service/kube-prometheus-prometheus 9090:9090 &
PROM_PID=$!
sleep 5

# Check if targets are discovered
if curl -s http://localhost:9090/api/v1/targets | grep -q "postgres-exporter"; then
    echo "✅ PostgreSQL target discovered"
else
    echo "❌ PostgreSQL target not found"
fi

if curl -s http://localhost:9090/api/v1/targets | grep -q "mysql-exporter"; then
    echo "✅ MySQL target discovered"
else
    echo "❌ MySQL target not found"
fi

kill $PROM_PID
```

## Conclusion

The database monitoring infrastructure provides comprehensive observability for PostgreSQL and MySQL databases in the K3s development environment. With automated metric collection, pre-configured dashboards, and alerting rules, developers can monitor database performance, troubleshoot issues, and maintain system health effectively.

For additional support or enhancements, refer to the main [Observability Stack Documentation](OBSERVABILITY_STACK_COMPLETE.md) or open an issue in the repository.
