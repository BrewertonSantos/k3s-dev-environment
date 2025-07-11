# 📊 Métricas Completas do kube-prometheus-stack

## 🎯 Visão Geral das Métricas Disponíveis

O kube-prometheus-stack fornece mais de **1000 métricas diferentes** cobrindo todos os aspectos do cluster Kubernetes. Esta documentação detalha as principais categorias e métricas mais úteis.

## 📈 Categorias de Métricas

### 1. 🖥️ Sistema Operacional (Node Exporter)

#### CPU
| Métrica | Descrição | Unidade |
|---------|-----------|---------|
| `node_cpu_seconds_total` | Tempo acumulado de CPU por modo | seconds |
| `node_load1` | Load average 1 minuto | float |
| `node_load5` | Load average 5 minutos | float |
| `node_load15` | Load average 15 minutos | float |

**Queries Úteis:**
```promql
# CPU usage percentage por node
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Load average alto
node_load5 > 2
```

#### Memória
| Métrica | Descrição | Unidade |
|---------|-----------|---------|
| `node_memory_MemTotal_bytes` | Memória total | bytes |
| `node_memory_MemAvailable_bytes` | Memória disponível | bytes |
| `node_memory_MemFree_bytes` | Memória livre | bytes |
| `node_memory_Buffers_bytes` | Buffers | bytes |
| `node_memory_Cached_bytes` | Cache | bytes |
| `node_memory_SwapTotal_bytes` | Swap total | bytes |
| `node_memory_SwapFree_bytes` | Swap livre | bytes |

**Queries Úteis:**
```promql
# Memory usage percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Memory pressure
node_memory_MemAvailable_bytes < node_memory_MemTotal_bytes * 0.1
```

#### Disco
| Métrica | Descrição | Unidade |
|---------|-----------|---------|
| `node_filesystem_size_bytes` | Tamanho do filesystem | bytes |
| `node_filesystem_avail_bytes` | Espaço disponível | bytes |
| `node_filesystem_free_bytes` | Espaço livre | bytes |
| `node_disk_read_bytes_total` | Bytes lidos | bytes |
| `node_disk_written_bytes_total` | Bytes escritos | bytes |
| `node_disk_io_time_seconds_total` | Tempo em I/O | seconds |

**Queries Úteis:**
```promql
# Disk usage percentage
100 - ((node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes)

# Disk I/O rate
rate(node_disk_read_bytes_total[5m])
rate(node_disk_written_bytes_total[5m])
```

#### Rede
| Métrica | Descrição | Unidade |
|---------|-----------|---------|
| `node_network_receive_bytes_total` | Bytes recebidos | bytes |
| `node_network_transmit_bytes_total` | Bytes transmitidos | bytes |
| `node_network_receive_packets_total` | Pacotes recebidos | packets |
| `node_network_transmit_packets_total` | Pacotes transmitidos | packets |
| `node_network_receive_errs_total` | Erros de recebimento | errors |
| `node_network_transmit_errs_total` | Erros de transmissão | errors |

**Queries Úteis:**
```promql
# Network throughput
rate(node_network_receive_bytes_total[5m])
rate(node_network_transmit_bytes_total[5m])

# Network errors
rate(node_network_receive_errs_total[5m]) > 0
```

### 2. ☸️ Estado do Kubernetes (Kube State Metrics)

#### Pods
| Métrica | Descrição | Labels |
|---------|-----------|--------|
| `kube_pod_info` | Informações do pod | namespace, pod, node, created_by_kind |
| `kube_pod_status_phase` | Fase do pod | namespace, pod, phase |
| `kube_pod_status_ready` | Status ready do pod | namespace, pod, condition |
| `kube_pod_container_status_restarts_total` | Reinicializações | namespace, pod, container |
| `kube_pod_container_resource_requests` | Resource requests | namespace, pod, container, resource |
| `kube_pod_container_resource_limits` | Resource limits | namespace, pod, container, resource |

**Queries Úteis:**
```promql
# Pods por namespace
sum(kube_pod_info) by (namespace)

# Pods não Running
sum(kube_pod_status_phase{phase!="Running"}) by (namespace, phase)

# Containers com muitos restarts
increase(kube_pod_container_status_restarts_total[1h]) > 5

# Resource requests vs limits
kube_pod_container_resource_requests{resource="cpu"} / kube_pod_container_resource_limits{resource="cpu"}
```

#### Deployments
| Métrica | Descrição | Labels |
|---------|-----------|--------|
| `kube_deployment_status_replicas` | Réplicas atuais | namespace, deployment |
| `kube_deployment_spec_replicas` | Réplicas desejadas | namespace, deployment |
| `kube_deployment_status_replicas_available` | Réplicas disponíveis | namespace, deployment |
| `kube_deployment_status_replicas_unavailable` | Réplicas indisponíveis | namespace, deployment |

**Queries Úteis:**
```promql
# Deployment health
kube_deployment_status_replicas_available / kube_deployment_spec_replicas

# Deployments com réplicas insuficientes
(kube_deployment_spec_replicas - kube_deployment_status_replicas_available) > 0
```

#### Nodes
| Métrica | Descrição | Labels |
|---------|-----------|--------|
| `kube_node_info` | Informações do node | node, kernel_version, os_image |
| `kube_node_status_condition` | Condições do node | node, condition, status |
| `kube_node_status_capacity` | Capacidade do node | node, resource |
| `kube_node_status_allocatable` | Recursos alocáveis | node, resource |

**Queries Úteis:**
```promql
# Nodes ready
kube_node_status_condition{condition="Ready", status="true"}

# Node capacity vs allocatable
kube_node_status_capacity{resource="cpu"} - kube_node_status_allocatable{resource="cpu"}
```

#### Services
| Métrica | Descrição | Labels |
|---------|-----------|--------|
| `kube_service_info` | Informações do service | namespace, service, cluster_ip |
| `kube_service_spec_type` | Tipo do service | namespace, service, type |
| `kube_endpoint_info` | Informações do endpoint | namespace, endpoint |

### 3. 🐳 Containers (cAdvisor)

#### Recursos
| Métrica | Descrição | Labels |
|---------|-----------|--------|
| `container_cpu_usage_seconds_total` | Uso de CPU | namespace, pod, container |
| `container_memory_working_set_bytes` | Uso de memória | namespace, pod, container |
| `container_memory_usage_bytes` | Uso total de memória | namespace, pod, container |
| `container_memory_max_usage_bytes` | Pico de uso de memória | namespace, pod, container |
| `container_fs_usage_bytes` | Uso do filesystem | namespace, pod, container |
| `container_fs_limit_bytes` | Limite do filesystem | namespace, pod, container |

**Queries Úteis:**
```promql
# CPU usage por pod
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)

# Memory usage por pod
sum(container_memory_working_set_bytes) by (pod)

# Top consumers
topk(10, sum(rate(container_cpu_usage_seconds_total[5m])) by (pod))
topk(10, sum(container_memory_working_set_bytes) by (pod))
```

#### Rede
| Métrica | Descrição | Labels |
|---------|-----------|--------|
| `container_network_receive_bytes_total` | Bytes recebidos | namespace, pod, interface |
| `container_network_transmit_bytes_total` | Bytes transmitidos | namespace, pod, interface |
| `container_network_receive_packets_total` | Pacotes recebidos | namespace, pod, interface |
| `container_network_transmit_packets_total` | Pacotes transmitidos | namespace, pod, interface |

### 4. 🎯 Prometheus Server

#### Métricas do Prometheus
| Métrica | Descrição |
|---------|-----------|
| `prometheus_tsdb_symbol_table_size_bytes` | Tamanho da tabela de símbolos |
| `prometheus_tsdb_head_samples_appended_total` | Samples adicionados |
| `prometheus_config_last_reload_successful` | Status do último reload |
| `prometheus_notifications_total` | Notificações enviadas |
| `prometheus_rule_evaluation_duration_seconds` | Duração da avaliação de regras |

#### AlertManager
| Métrica | Descrição |
|---------|-----------|
| `alertmanager_alerts` | Alertas ativos |
| `alertmanager_notifications_total` | Notificações enviadas |
| `alertmanager_notification_latency_seconds` | Latência das notificações |

## 🔍 Queries por Cenário

### 🚨 Troubleshooting

#### Identificar Problemas de Performance
```promql
# Pods com alto uso de CPU (>80%)
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod) > 0.8

# Pods com alto uso de memória (>1GB)
sum(container_memory_working_set_bytes) by (pod) > 1073741824

# Nodes com pouco espaço em disco (<10%)
(node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 10
```

#### Health Check do Cluster
```promql
# Pods crashando
increase(kube_pod_container_status_restarts_total[5m]) > 0

# Pods em estado de erro
kube_pod_status_phase{phase=~"Failed|Unknown"} > 0

# Nodes com problemas
kube_node_status_condition{condition="Ready", status!="true"} > 0
```

### 📊 Capacity Planning

#### Utilização de Recursos por Namespace
```promql
# CPU por namespace
sum(rate(container_cpu_usage_seconds_total[5m])) by (namespace)

# Memória por namespace
sum(container_memory_working_set_bytes) by (namespace)

# Número de pods por namespace
sum(kube_pod_info) by (namespace)
```

#### Previsão de Crescimento
```promql
# Taxa de crescimento de pods (últimas 24h)
increase(sum(kube_pod_info) by (namespace)[24h])

# Trend de uso de memória
predict_linear(node_memory_MemAvailable_bytes[1h], 4*3600)
```

### 🏆 Top Consumers

#### Top 10 Resources
```promql
# Top pods por CPU
topk(10, sum(rate(container_cpu_usage_seconds_total[5m])) by (pod, namespace))

# Top pods por memória
topk(10, sum(container_memory_working_set_bytes) by (pod, namespace))

# Top namespaces por número de pods
topk(10, sum(kube_pod_info) by (namespace))

# Top nodes por carga
topk(5, node_load5)
```

### 🔄 Operational Metrics

#### Deployment Status
```promql
# Deployments com rollout em andamento
kube_deployment_status_replicas != kube_deployment_spec_replicas

# Deployments com zero réplicas
kube_deployment_spec_replicas == 0

# Success rate de deployments
sum(kube_deployment_status_replicas_available) / sum(kube_deployment_spec_replicas)
```

#### Service Discovery
```promql
# Services sem endpoints
kube_service_info unless on(namespace, service) kube_endpoint_info

# Endpoints por service
sum(kube_endpoint_address_available) by (namespace, endpoint)
```

## 📋 Dashboards Recomendados

### Importar via Grafana ID

| Dashboard | ID | Foco |
|-----------|-----|------|
| **Kubernetes Cluster Overview** | 7249 | Visão geral do cluster |
| **Node Exporter Full** | 1860 | Métricas detalhadas dos nodes |
| **Kubernetes Pod Monitoring** | 6417 | Monitoramento de pods |
| **Kubernetes Deployments** | 8588 | Status de deployments |
| **Kubernetes Persistent Volumes** | 13646 | Monitoramento de storage |
| **Prometheus Stats** | 3662 | Métricas do próprio Prometheus |

### Custom Dashboards

#### Performance Overview
```json
{
  "dashboard": {
    "title": "K3s Cluster Performance",
    "panels": [
      {
        "title": "CPU Usage by Node",
        "targets": [
          {
            "expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
          }
        ]
      }
    ]
  }
}
```

## 🎛️ Alerting

### Regras de Alerta Importantes

#### Recursos
```yaml
groups:
  - name: resource.rules
    rules:
    - alert: HighCPUUsage
      expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage on {{ $labels.instance }}"
        
    - alert: HighMemoryUsage
      expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage on {{ $labels.instance }}"
```

#### Kubernetes Health
```yaml
groups:
  - name: kubernetes.rules
    rules:
    - alert: PodCrashLooping
      expr: increase(kube_pod_container_status_restarts_total[1h]) > 5
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Pod {{ $labels.pod }} is crash looping"
        
    - alert: DeploymentReplicasMismatch
      expr: (kube_deployment_spec_replicas - kube_deployment_status_replicas_available) > 0
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "Deployment {{ $labels.deployment }} has insufficient replicas"
```

## 🔧 Otimização de Performance

### Reduzir Cardinalidade
```promql
# Evitar queries com muitas séries
sum by (job) (up) # ✅ Boa prática
sum by (instance) (up) # ❌ Muitas séries

# Usar agregações
avg_over_time(up[5m]) # ✅ Reduz pontos de dados
up # ❌ Todos os pontos
```

### Recording Rules
```yaml
groups:
  - name: cluster.rules
    interval: 30s
    rules:
    - record: cluster:cpu_usage_rate
      expr: sum(rate(container_cpu_usage_seconds_total[5m]))
      
    - record: cluster:memory_usage_bytes
      expr: sum(container_memory_working_set_bytes)
```

## 📚 Recursos Adicionais

- [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
- [Kubernetes Monitoring Guide](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/)

---

🎯 **Próximos Passos**: Use esta documentação como referência para criar dashboards personalizados e configurar alertas específicos para seu ambiente!
