# 📊 Kube-Prometheus-Stack - Guia Completo

## 📋 Visão Geral

O **kube-prometheus-stack** é uma coleção abrangente de componentes de monitoramento Kubernetes que fornece observabilidade completa para clusters. Este guia detalha a implementação e uso no ambiente k3s.

### Componentes Incluídos

| Componente | Função | Namespace |
|------------|--------|-----------|
| **Prometheus Operator** | Gerencia instâncias Prometheus via CRDs | development |
| **Prometheus Server** | Coleta e armazena métricas | development |
| **AlertManager** | Gerencia alertas e notificações | development |
| **Node Exporter** | Exporta métricas do sistema operacional | development |
| **Kube State Metrics** | Métricas de objetos Kubernetes | development |
| **Grafana** | Dashboard de visualização (existente) | development |

## 🚀 Instalação

### 1. Adicionar Repositório Helm

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### 2. Configuração

O arquivo de configuração está localizado em `config/prometheus/kube-prometheus-stack-values.yaml`:

```yaml
# Configurações principais
global:
  imageRegistry: ""
  imagePullSecrets: []

# Prometheus Operator
prometheusOperator:
  enabled: true
  resources:
    limits:
      cpu: 200m
      memory: 200Mi
    requests:
      cpu: 100m
      memory: 100Mi

# Prometheus
prometheus:
  enabled: true
  ingress:
    enabled: true
    hosts:
      - prometheus.local
  prometheusSpec:
    retention: 30d
    resources:
      limits:
        cpu: 2000m
        memory: 8Gi
      requests:
        cpu: 200m
        memory: 400Mi

# AlertManager
alertmanager:
  enabled: true
  ingress:
    enabled: true
    hosts:
      - alertmanager.local
  config:
    global:
      smtp_smarthost: 'localhost:587'
    route:
      group_by: ['alertname']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'webhook'
    receivers:
    - name: 'webhook'
      webhook_configs:
      - url: 'http://webhook-service:8080/alerts'

# Node Exporter (habilitado)
nodeExporter:
  enabled: true

# Kube State Metrics (habilitado)
kubeStateMetrics:
  enabled: true

# Grafana (desabilitado - usamos instância existente)
grafana:
  enabled: false
```

### 3. Deploy via Script

```bash
# Deploy completo
./scripts/observability.sh deploy prometheus

# Verificar status
./scripts/observability.sh status prometheus
```

### 4. Deploy Manual (alternativo)

```bash
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace development \
  --create-namespace \
  --values config/prometheus/kube-prometheus-stack-values.yaml
```

## 📊 Métricas Disponíveis

### Métricas do Sistema (Node Exporter)

| Métrica | Descrição | Exemplo de Query |
|---------|-----------|------------------|
| `node_cpu_seconds_total` | Tempo de CPU por modo | `100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)` |
| `node_memory_MemTotal_bytes` | Memória total | `node_memory_MemTotal_bytes` |
| `node_memory_MemAvailable_bytes` | Memória disponível | `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100` |
| `node_filesystem_size_bytes` | Tamanho do filesystem | `100 - ((node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes)` |
| `node_network_receive_bytes_total` | Bytes recebidos por interface | `rate(node_network_receive_bytes_total[5m])` |
| `node_network_transmit_bytes_total` | Bytes transmitidos por interface | `rate(node_network_transmit_bytes_total[5m])` |
| `node_load1` | Load average 1 minuto | `node_load1` |
| `node_load5` | Load average 5 minutos | `node_load5` |
| `node_load15` | Load average 15 minutos | `node_load15` |

### Métricas do Kubernetes (Kube State Metrics)

| Métrica | Descrição | Exemplo de Query |
|---------|-----------|------------------|
| `kube_pod_info` | Informações dos pods | `sum(kube_pod_info) by (namespace)` |
| `kube_pod_status_phase` | Status dos pods | `sum(kube_pod_status_phase) by (phase)` |
| `kube_pod_container_status_restarts_total` | Reinicializações de containers | `increase(kube_pod_container_status_restarts_total[1h])` |
| `kube_deployment_status_replicas_available` | Réplicas disponíveis | `kube_deployment_status_replicas_available / kube_deployment_spec_replicas` |
| `kube_deployment_spec_replicas` | Réplicas desejadas | `kube_deployment_spec_replicas` |
| `kube_node_status_condition` | Status dos nós | `kube_node_status_condition{condition="Ready"}` |
| `kube_service_info` | Informações dos serviços | `kube_service_info` |
| `kube_ingress_info` | Informações dos ingresses | `kube_ingress_info` |
| `kube_configmap_info` | Informações dos ConfigMaps | `kube_configmap_info` |
| `kube_secret_info` | Informações dos Secrets | `kube_secret_info` |

### Métricas de Containers (cAdvisor)

| Métrica | Descrição | Exemplo de Query |
|---------|-----------|------------------|
| `container_cpu_usage_seconds_total` | Uso de CPU por container | `sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)` |
| `container_memory_working_set_bytes` | Uso de memória por container | `sum(container_memory_working_set_bytes) by (pod)` |
| `container_network_receive_bytes_total` | Bytes recebidos por container | `rate(container_network_receive_bytes_total[5m])` |
| `container_network_transmit_bytes_total` | Bytes transmitidos por container | `rate(container_network_transmit_bytes_total[5m])` |
| `container_fs_usage_bytes` | Uso do filesystem por container | `container_fs_usage_bytes` |

### Métricas do Prometheus

| Métrica | Descrição | Exemplo de Query |
|---------|-----------|------------------|
| `prometheus_tsdb_symbol_table_size_bytes` | Tamanho da tabela de símbolos | `prometheus_tsdb_symbol_table_size_bytes` |
| `prometheus_config_last_reload_successful` | Status do último reload | `prometheus_config_last_reload_successful` |
| `prometheus_notifications_total` | Total de notificações enviadas | `rate(prometheus_notifications_total[5m])` |

## 🔧 Configuração do Grafana

### 1. Data Source

O Grafana precisa ser configurado para usar o novo serviço Prometheus:

- **URL**: `http://kube-prometheus-stack-prometheus.development.svc.cluster.local:9090`
- **Access**: Server (default)
- **Scrape interval**: 15s

### 2. Dashboards Recomendados

| Dashboard | ID | Descrição |
|-----------|-----|-----------|
| **Kubernetes Cluster Overview** | 7249 | Visão geral do cluster |
| **Node Exporter Full** | 1860 | Métricas detalhadas dos nós |
| **Kubernetes Pod Monitoring** | 6417 | Monitoramento de pods |
| **Kubernetes Deployment Statefulset Daemonset metrics** | 8588 | Métricas de workloads |
| **Kubernetes Persistent Volumes** | 13646 | Monitoramento de volumes |

### 3. Importar Dashboards

```bash
# Via Grafana UI: + → Import → Digite o ID do dashboard
# Ou acesse: http://grafana.local/dashboard/import
```

## 📈 Queries Úteis

### Performance do Cluster

```promql
# Top 10 pods por uso de CPU
topk(10, sum(rate(container_cpu_usage_seconds_total[5m])) by (pod))

# Top 10 pods por uso de memória
topk(10, sum(container_memory_working_set_bytes) by (pod))

# Nodes com maior uso de CPU
topk(5, 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100))

# Nodes com maior uso de memória
topk(5, (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100)
```

### Health Check do Cluster

```promql
# Pods em estado não Ready
sum(kube_pod_status_phase{phase!="Running"}) by (namespace, phase)

# Nodes não Ready
sum(kube_node_status_condition{condition="Ready", status!="true"})

# Deployments com réplicas insuficientes
(kube_deployment_spec_replicas - kube_deployment_status_replicas_available) > 0

# Containers com muitas reinicializações (>5 na última hora)
increase(kube_pod_container_status_restarts_total[1h]) > 5
```

### Capacidade e Recursos

```promql
# Utilização de CPU por namespace
sum(rate(container_cpu_usage_seconds_total[5m])) by (namespace)

# Utilização de memória por namespace
sum(container_memory_working_set_bytes) by (namespace)

# Pods por namespace
sum(kube_pod_info) by (namespace)

# Persistent Volumes por status
sum(kube_persistentvolume_status_phase) by (phase)
```

## 🚨 Alerting

### Regras de Alerta Padrão

O kube-prometheus-stack inclui regras de alerta pré-configuradas:

- **KubernetesMemoryPressure**: Pressão de memória nos nós
- **KubernetesDiskPressure**: Pressão de disco nos nós
- **KubernetesNetworkUnavailable**: Problemas de rede
- **KubernetesNodeNotReady**: Nós não disponíveis
- **KubernetesPodCrashLooping**: Pods em crash loop
- **KubernetesContainerOOMKilled**: Containers mortos por OOM

### Configuração de Alertas Customizados

Criar arquivo `custom-alerts.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: custom-alerts
  namespace: development
spec:
  groups:
  - name: custom.rules
    rules:
    - alert: HighMemoryUsage
      expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage on {{ $labels.instance }}"
        description: "Memory usage is above 80% on {{ $labels.instance }}"
```

Aplicar:
```bash
kubectl apply -f custom-alerts.yaml
```

## 🔍 Troubleshooting

### Verificar Status dos Componentes

```bash
# Status do Helm release
helm status kube-prometheus-stack -n development

# Pods do stack
kubectl get pods -n development -l "release=kube-prometheus-stack"

# Services
kubectl get svc -n development -l "release=kube-prometheus-stack"

# CRDs do Prometheus Operator
kubectl get crd | grep monitoring.coreos.com
```

### Logs dos Componentes

```bash
# Logs do Prometheus Operator
kubectl logs -n development -l app.kubernetes.io/name=prometheus-operator

# Logs do Prometheus
kubectl logs -n development -l app.kubernetes.io/name=prometheus

# Logs do AlertManager
kubectl logs -n development -l app.kubernetes.io/name=alertmanager
```

### Problemas Comuns

#### 1. Métricas não aparecem no Grafana
```bash
# Verificar se o data source está correto
curl http://kube-prometheus-stack-prometheus.development.svc.cluster.local:9090/metrics

# Verificar configuração do Prometheus
kubectl get prometheus -n development -o yaml
```

#### 2. Node Exporter não coletando métricas
```bash
# Verificar DaemonSet
kubectl get ds -n development

# Verificar pods do Node Exporter
kubectl get pods -n development -l app.kubernetes.io/name=node-exporter
```

#### 3. AlertManager não enviando alertas
```bash
# Verificar configuração
kubectl get secret alertmanager-kube-prometheus-stack-alertmanager -n development -o yaml

# Testar conectividade
kubectl exec -n development deploy/alertmanager-kube-prometheus-stack-alertmanager -- wget -O- http://webhook-service:8080/test
```

## 🔄 Manutenção

### Backup da Configuração

```bash
# Backup dos valores Helm
helm get values kube-prometheus-stack -n development > backup-values.yaml

# Backup das regras de alerta customizadas
kubectl get prometheusrule -n development -o yaml > backup-rules.yaml
```

### Atualização do Stack

```bash
# Atualizar repositório
helm repo update

# Verificar nova versão
helm search repo prometheus-community/kube-prometheus-stack

# Atualizar (mantenha os valores)
helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace development \
  --values config/prometheus/kube-prometheus-stack-values.yaml
```

### Limpeza

```bash
# Remover via script
./scripts/observability.sh cleanup prometheus

# Ou manualmente
helm uninstall kube-prometheus-stack -n development
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd probes.monitoring.coreos.com
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com
```

## 📚 Recursos Adicionais

- [Documentação Oficial](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [PromQL Guide](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)

## 🎯 Conclusão

O kube-prometheus-stack fornece uma solução completa de monitoramento para Kubernetes, oferecendo:

- ✅ **Métricas abrangentes** de todos os componentes do cluster
- ✅ **Alerting configurável** com regras pré-definidas
- ✅ **Integração nativa** com Grafana
- ✅ **Escalabilidade** para clusters de qualquer tamanho
- ✅ **Facilidade de manutenção** via Helm e Operator

Com esta implementação, você tem visibilidade completa do seu ambiente Kubernetes e pode criar dashboards personalizados para suas necessidades específicas.
