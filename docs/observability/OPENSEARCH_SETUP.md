# OpenSearch Log Discovery & Index Management

## 🔍 OpenSearch Setup Guide

This guide covers complete OpenSearch configuration for log discovery, index management, and search optimization in your K3s environment.

## 📋 Prerequisites

Ensure OpenSearch is deployed and accessible:
```bash
# Check OpenSearch status
./scripts/observability.sh status opensearch

# Verify OpenSearch is accessible
curl -s http://opensearch.localhost/_cluster/health
```

---

## 🗂️ Index Pattern Configuration

### Step 1: Access OpenSearch Dashboards

1. Open http://opensearch.localhost in your browser
2. You should see the OpenSearch Dashboards interface

### Step 2: Create Index Patterns

#### Primary Log Index Pattern

1. **Navigate to Index Patterns**:
   - Click **☰ Menu** → **Management** → **Stack Management**
   - Select **Index Patterns** under Kibana

2. **Create k3s-logs Pattern**:
   - Click **Create index pattern**
   - Enter: `k3s-logs-*`
   - Click **Next step**
   - Select **@timestamp** as time field
   - Click **Create index pattern**

#### Application-Specific Patterns

Create focused patterns for better performance:

```bash
# Database logs pattern
k3s-logs-database-*

# Development logs pattern  
k3s-logs-development-*

# System logs pattern
k3s-logs-system-*
```

### Step 3: Verify Index Creation

Check that logs are being indexed:

```bash
# List all indices
curl -s http://opensearch.localhost/_cat/indices?v

# Check specific index
curl -s http://opensearch.localhost/_cat/indices/k3s-logs-*?v

# Get index statistics
curl -s http://opensearch.localhost/k3s-logs-*/_stats?pretty
```

---

## 🔍 Log Discovery & Search

### Basic Search Queries

#### Discover Interface

1. **Access Discover**:
   - Click **☰ Menu** → **Discover**
   - Select your index pattern: `k3s-logs-*`

2. **Time Range Selection**:
   - Use the time picker (top right)
   - Common ranges: Last 15 minutes, 1 hour, 24 hours
   - Custom ranges available

### Search Query Examples

#### Namespace Filtering
```bash
# Database namespace only
kubernetes.namespace_name:database

# Multiple namespaces
kubernetes.namespace_name:(database OR development)

# Exclude system namespaces
NOT kubernetes.namespace_name:(kube-system OR kube-public)
```

#### Application Filtering
```bash
# MySQL logs
kubernetes.pod_name:mysql-*

# CloudBeaver logs
kubernetes.labels.app:cloudbeaver

# Prometheus logs
kubernetes.labels.app:prometheus AND kubernetes.namespace_name:development
```

#### Log Level Filtering
```bash
# Error logs only
level:ERROR

# Multiple log levels
level:(ERROR OR WARN OR WARNING)

# Case-insensitive error search
log:*error* OR log:*ERROR* OR level:error OR level:ERROR
```

#### Content-Based Search
```bash
# Connection errors
log:*connection* AND log:*error*

# Authentication issues
log:*auth* OR log:*login* OR log:*credential*

# Database queries
log:*SELECT* OR log:*INSERT* OR log:*UPDATE*

# HTTP status codes
log:*500* OR log:*404* OR log:*503*
```

#### Time-Based Queries
```bash
# Last 5 minutes
@timestamp:>now-5m

# Specific time range
@timestamp:[2024-01-01 TO 2024-01-02]

# Business hours only
@timestamp:[now/d+8h TO now/d+18h]
```

### Advanced Search Techniques

#### Wildcards and Regex
```bash
# Wildcard search
kubernetes.pod_name:mysql-*

# Regex patterns (use with caution)
log:/.*connection.*timeout.*/

# Field existence
_exists_:kubernetes.container_name
```

#### Boolean Logic
```bash
# AND operator
kubernetes.namespace_name:database AND level:ERROR

# OR operator  
level:ERROR OR level:FATAL

# NOT operator
kubernetes.namespace_name:database AND NOT kubernetes.pod_name:mysql-*

# Grouping
(level:ERROR OR level:WARN) AND kubernetes.namespace_name:database
```

#### Range Queries
```bash
# Numeric ranges
response_time:[100 TO 500]

# Date ranges
@timestamp:[now-1h TO now]

# Greater than
response_time:>1000
```

---

## 💾 Saved Searches & Dashboards

### Create Saved Searches

#### Database Error Monitoring
1. **Apply Filter**: `kubernetes.namespace_name:database AND level:ERROR`
2. **Save Search**:
   - Click **Save** in top menu
   - Name: "Database Errors"
   - Description: "Error logs from database namespace"
   - Click **Save**

#### Application Performance
1. **Apply Filter**: `log:*slow* OR log:*timeout* OR response_time:>5000`
2. **Save as**: "Performance Issues"

#### Security Events
1. **Apply Filter**: `log:*auth* OR log:*login* OR log:*failed* OR log:*unauthorized*`
2. **Save as**: "Security Events"

### Common Saved Search Templates

```bash
# High-Priority Issues
(level:ERROR OR level:FATAL OR level:CRITICAL) AND NOT log:*test*

# Database Performance
kubernetes.namespace_name:database AND (log:*slow* OR log:*timeout* OR log:*deadlock*)

# CloudBeaver Activity
kubernetes.labels.app:cloudbeaver AND (log:*login* OR log:*session* OR log:*API*)

# Pod Lifecycle Events
log:*started* OR log:*stopped* OR log:*restarted* OR log:*terminated*

# Network Issues
log:*connection* AND (log:*refused* OR log:*timeout* OR log:*reset*)
```

---

## 📊 Visualization Creation

### Basic Visualizations

#### 1. Log Volume Over Time

1. **Create Visualization**:
   - Go to **Visualize** → **Create visualization**
   - Select **Line** chart
   - Choose index pattern: `k3s-logs-*`

2. **Configure Metrics**:
   - Y-axis: Count
   - X-axis: Date Histogram on `@timestamp`
   - Interval: Auto

3. **Add Filters**:
   - Optional: Filter by namespace or application

#### 2. Error Rate by Application

1. **Create Pie Chart**:
   - Select **Pie** chart
   - Index pattern: `k3s-logs-*`

2. **Configure**:
   - Filter: `level:ERROR`
   - Buckets: Terms on `kubernetes.labels.app.keyword`
   - Size: 10

#### 3. Log Levels Distribution

1. **Create Bar Chart**:
   - Select **Vertical bar** chart
   - Filter: None (all logs)

2. **Configure**:
   - X-axis: Terms on `level.keyword`
   - Y-axis: Count
   - Order: Descending

### Advanced Visualizations

#### Heatmap: Errors by Hour and Service

1. **Create Heatmap**:
   - Select **Heat map**
   - Filter: `level:ERROR`

2. **Configure Buckets**:
   - X-axis: Date Histogram on `@timestamp` (hourly)
   - Y-axis: Terms on `kubernetes.labels.app.keyword`

#### Data Table: Top Error Messages

1. **Create Data Table**:
   - Select **Data table**
   - Filter: `level:ERROR`

2. **Configure**:
   - Buckets: Terms on `log.keyword`
   - Size: 20
   - Order by: Count (descending)

---

## 📈 Dashboard Creation

### Application Monitoring Dashboard

1. **Create Dashboard**:
   - Go to **Dashboard** → **Create new dashboard**
   - Name: "Application Monitoring"

2. **Add Panels**:
   - Log volume over time
   - Error rate by namespace
   - Top error messages
   - Recent application logs

### Infrastructure Dashboard

1. **Create Dashboard**:
   - Name: "Infrastructure Logs"

2. **Add Panels**:
   - System events
   - Pod lifecycle events
   - Network errors
   - Storage issues

### Database-Specific Dashboard

1. **Create Dashboard**:
   - Name: "Database Operations"

2. **Add Panels**:
   - MySQL query logs
   - PostgreSQL connection logs
   - CloudBeaver access logs
   - Database error summary

---

## ⚙️ Index Management

### Index Lifecycle Policies

#### Create Retention Policy

```bash
# Create index policy for automatic cleanup
curl -X PUT "http://opensearch.localhost/_plugins/_ism/policies/k3s-logs-policy" \
-H 'Content-Type: application/json' -d'
{
  "policy": {
    "description": "K3s logs lifecycle management",
    "default_state": "hot",
    "states": [
      {
        "name": "hot",
        "actions": [
          {
            "rollover": {
              "min_index_age": "1d",
              "min_doc_count": 100000
            }
          }
        ],
        "transitions": [
          {
            "state_name": "warm",
            "conditions": {
              "min_index_age": "3d"
            }
          }
        ]
      },
      {
        "name": "warm",
        "actions": [
          {
            "replica_count": {
              "number_of_replicas": 0
            }
          }
        ],
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
}'
```

#### Apply Policy to Indices

```bash
# Apply policy to existing indices
curl -X POST "http://opensearch.localhost/_plugins/_ism/add/k3s-logs-*" \
-H 'Content-Type: application/json' -d'
{
  "policy_id": "k3s-logs-policy"
}'
```

### Index Templates

#### Create Index Template

```bash
# Create template for better mapping
curl -X PUT "http://opensearch.localhost/_index_template/k3s-logs-template" \
-H 'Content-Type: application/json' -d'
{
  "index_patterns": ["k3s-logs-*"],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "index.lifecycle.name": "k3s-logs-policy",
      "index.refresh_interval": "10s"
    },
    "mappings": {
      "properties": {
        "@timestamp": {
          "type": "date"
        },
        "kubernetes": {
          "properties": {
            "namespace_name": {
              "type": "keyword"
            },
            "pod_name": {
              "type": "keyword"  
            },
            "container_name": {
              "type": "keyword"
            },
            "labels": {
              "properties": {
                "app": {
                  "type": "keyword"
                }
              }
            }
          }
        },
        "level": {
          "type": "keyword"
        },
        "log": {
          "type": "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 2048
            }
          }
        }
      }
    }
  }
}'
```

---

## 🔍 Search Optimization

### Performance Tips

#### Query Optimization
1. **Use field filters** instead of full-text search when possible
2. **Limit time ranges** to improve performance
3. **Use specific index patterns** instead of wildcards
4. **Cache frequently used queries**

#### Index Optimization
```bash
# Force index refresh
curl -X POST "http://opensearch.localhost/k3s-logs-*/_refresh"

# Optimize indices
curl -X POST "http://opensearch.localhost/k3s-logs-*/_forcemerge?max_num_segments=1"

# Check index health
curl -s "http://opensearch.localhost/_cluster/health?level=indices&pretty"
```

### Monitoring Queries

#### Cluster Health
```bash
# Overall cluster status
curl -s "http://opensearch.localhost/_cluster/health?pretty"

# Index-level health
curl -s "http://opensearch.localhost/_cluster/health?level=indices&pretty"

# Node information
curl -s "http://opensearch.localhost/_nodes/stats?pretty"
```

#### Performance Metrics
```bash
# Index statistics
curl -s "http://opensearch.localhost/_stats/indexing,search?pretty"

# Cache statistics
curl -s "http://opensearch.localhost/_nodes/stats/indices/query_cache,request_cache?pretty"

# Thread pool information
curl -s "http://opensearch.localhost/_nodes/stats/thread_pool?pretty"
```

---

## 🚨 Alerting Configuration

### Create Alert Monitors

#### High Error Rate Alert

```bash
# Create error rate monitor
curl -X POST "http://opensearch.localhost/_plugins/_alerting/monitors" \
-H 'Content-Type: application/json' -d'
{
  "type": "monitor",
  "name": "High Error Rate",
  "enabled": true,
  "schedule": {
    "period": {
      "interval": 5,
      "unit": "MINUTES"
    }
  },
  "inputs": [{
    "search": {
      "indices": ["k3s-logs-*"],
      "query": {
        "size": 0,
        "query": {
          "bool": {
            "filter": [
              {
                "range": {
                  "@timestamp": {
                    "gte": "now-5m"
                  }
                }
              },
              {
                "term": {
                  "level": "ERROR"
                }
              }
            ]
          }
        },
        "aggs": {
          "error_count": {
            "cardinality": {
              "field": "@timestamp"
            }
          }
        }
      }
    }
  }],
  "triggers": [{
    "name": "Error threshold exceeded",
    "severity": "2",
    "condition": {
      "script": {
        "source": "ctx.results[0].aggregations.error_count.value > 50"
      }
    },
    "actions": [{
      "name": "Log notification",
      "destination_id": "",
      "message_template": {
        "source": "High error rate detected: {{ctx.results.0.aggregations.error_count.value}} errors in the last 5 minutes"
      }
    }]
  }]
}'
```

#### Database Connection Issues

```bash
# Monitor database connection problems
curl -X POST "http://opensearch.localhost/_plugins/_alerting/monitors" \
-H 'Content-Type: application/json' -d'
{
  "type": "monitor",
  "name": "Database Connection Issues",
  "enabled": true,
  "schedule": {
    "period": {
      "interval": 2,
      "unit": "MINUTES"
    }
  },
  "inputs": [{
    "search": {
      "indices": ["k3s-logs-*"],
      "query": {
        "size": 0,
        "query": {
          "bool": {
            "filter": [
              {
                "range": {
                  "@timestamp": {
                    "gte": "now-2m"
                  }
                }
              },
              {
                "term": {
                  "kubernetes.namespace_name": "database"
                }
              },
              {
                "query_string": {
                  "query": "log:*connection* AND (log:*refused* OR log:*timeout* OR log:*failed*)"
                }
              }
            ]
          }
        }
      }
    }
  }],
  "triggers": [{
    "name": "Connection issues detected",
    "severity": "1",
    "condition": {
      "script": {
        "source": "ctx.results[0].hits.total.value > 0"
      }
    },
    "actions": [{
      "name": "Database alert",
      "message_template": {
        "source": "Database connection issues detected in the last 2 minutes"
      }
    }]
  }]
}'
```

---

## 🔧 Troubleshooting

### Common Issues

#### No Logs Appearing
```bash
# Check Fluent Bit is running
kubectl get pods -n logging -l app=fluent-bit

# Check Fluent Bit logs
kubectl logs -n logging daemonset/fluent-bit

# Test OpenSearch connectivity
kubectl exec -n logging deployment/opensearch -- curl -s "localhost:9200/_cluster/health"

# Check indices
kubectl exec -n logging deployment/opensearch -- curl -s "localhost:9200/_cat/indices?v"
```

#### Search Performance Issues
```bash
# Check cluster health
curl -s "http://opensearch.localhost/_cluster/health?pretty"

# Monitor query performance
curl -s "http://opensearch.localhost/_nodes/stats/indices/search?pretty"

# Check for field data circuit breaker
curl -s "http://opensearch.localhost/_nodes/stats/breaker?pretty"
```

#### Index Pattern Not Working
1. **Verify index exists**: Check `_cat/indices` output
2. **Check timestamp field**: Ensure `@timestamp` is properly formatted
3. **Refresh index pattern**: Go to Management → Index Patterns → Refresh
4. **Check field mappings**: Verify field types in index mapping

### Diagnostic Queries

```bash
# Check index mapping
curl -s "http://opensearch.localhost/k3s-logs-*/_mapping?pretty"

# Sample documents
curl -s "http://opensearch.localhost/k3s-logs-*/_search?size=5&pretty"

# Field statistics
curl -s "http://opensearch.localhost/k3s-logs-*/_field_caps?fields=*&pretty"

# Index settings
curl -s "http://opensearch.localhost/k3s-logs-*/_settings?pretty"
```

---

## 📚 Quick Reference

### Essential Queries
```bash
# All database logs
kubernetes.namespace_name:database

# Errors only
level:ERROR OR log:*ERROR*

# Last hour errors
level:ERROR AND @timestamp:>now-1h

# Application errors
kubernetes.labels.app:cloudbeaver AND level:ERROR

# Connection issues
log:*connection* AND (log:*refused* OR log:*timeout*)
```

### Field Reference
- `@timestamp` - Log timestamp
- `kubernetes.namespace_name` - K8s namespace
- `kubernetes.pod_name` - Pod name
- `kubernetes.container_name` - Container name
- `kubernetes.labels.app` - Application label
- `level` - Log level (ERROR, WARN, INFO, etc.)
- `log` - Actual log message

### Management URLs
- **OpenSearch Dashboards**: http://opensearch.localhost
- **Cluster Health**: http://opensearch.localhost/_cluster/health
- **Index Management**: http://opensearch.localhost/_cat/indices?v

Your OpenSearch log discovery system is now fully configured for comprehensive log analysis!
