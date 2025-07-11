#!/bin/bash

# Script para validar se o Prometheus e Grafana estão recebendo métricas do PostgreSQL
# Autor: Desenvolvido para k3s-dev-environment

echo "🔍 Validando Monitoramento PostgreSQL..."
echo "=========================================="

# Verificar se os pods estão rodando
echo ""
echo "📊 1. Verificando status dos pods:"
kubectl get pods -n database | grep -E "(postgres|exporter)"

# Verificar ServiceMonitors
echo ""
echo "📊 2. Verificando ServiceMonitors:"
kubectl get servicemonitors -n database

# Verificar se o postgres-exporter está expondo métricas
echo ""
echo "📊 3. Testando postgres-exporter diretamente:"
if kubectl get pod -n database postgres-exporter-simple-* &>/dev/null; then
    POD_NAME=$(kubectl get pods -n database -l app=postgres-exporter-simple -o jsonpath='{.items[0].metadata.name}')
    echo "Pod encontrado: $POD_NAME"
    
    # Port-forward em background
    kubectl port-forward -n database pod/$POD_NAME 9187:9187 &
    PORT_FORWARD_PID=$!
    sleep 3
    
    echo "Testando endpoint /metrics:"
    METRICS_COUNT=$(curl -s http://localhost:9187/metrics | grep -c "^pg_")
    echo "Métricas PostgreSQL encontradas: $METRICS_COUNT"
    
    if [ $METRICS_COUNT -gt 0 ]; then
        echo "✅ postgres-exporter funcionando corretamente"
        echo "Exemplos de métricas:"
        curl -s http://localhost:9187/metrics | grep "^pg_" | head -5
    else
        echo "❌ postgres-exporter não está expondo métricas PostgreSQL"
    fi
    
    # Limpar port-forward
    kill $PORT_FORWARD_PID 2>/dev/null
else
    echo "❌ Pod postgres-exporter-simple não encontrado"
fi

# Verificar se o Prometheus está coletando as métricas
echo ""
echo "📊 4. Verificando coleta no Prometheus:"
kubectl port-forward -n development service/kube-prometheus-prometheus 9090:9090 &
PROM_PID=$!
sleep 3

echo "Testando query no Prometheus:"
PG_METRICS=$(curl -s "http://localhost:9090/api/v1/query?query=pg_database_size_bytes" | jq -r '.data.result | length')
echo "Métricas pg_database_size_bytes encontradas: $PG_METRICS"

if [ $PG_METRICS -gt 0 ]; then
    echo "✅ Prometheus coletando métricas PostgreSQL"
    echo "Exemplo de dados:"
    curl -s "http://localhost:9090/api/v1/query?query=pg_database_size_bytes" | jq -r '.data.result[0] | "Database: " + .metric.datname + ", Size: " + .value[1] + " bytes"'
else
    echo "❌ Prometheus não está coletando métricas PostgreSQL"
fi

# Limpar port-forward
kill $PROM_PID 2>/dev/null

# Verificar targets no Prometheus
echo ""
echo "📊 5. Verificando targets PostgreSQL no Prometheus:"
kubectl port-forward -n development service/kube-prometheus-prometheus 9090:9090 &
PROM_PID=$!
sleep 3

POSTGRES_TARGETS=$(curl -s "http://localhost:9090/api/v1/targets" | jq -r '.data.activeTargets[] | select(.labels.job | contains("postgres") or contains("kubernetes-services")) | select(.labels.kubernetes_service_name | contains("postgres")) | .health' | wc -l)
echo "Targets PostgreSQL encontrados: $POSTGRES_TARGETS"

if [ $POSTGRES_TARGETS -gt 0 ]; then
    echo "✅ Targets PostgreSQL configurados no Prometheus"
    curl -s "http://localhost:9090/api/v1/targets" | jq -r '.data.activeTargets[] | select(.labels.kubernetes_service_name | contains("postgres")) | "Target: " + .scrapeUrl + " - Status: " + .health'
else
    echo "❌ Nenhum target PostgreSQL encontrado no Prometheus"
fi

# Limpar port-forward
kill $PROM_PID 2>/dev/null

echo ""
echo "📊 6. Verificando logs do postgres-exporter:"
if kubectl get pod -n database postgres-exporter-simple-* &>/dev/null; then
    POD_NAME=$(kubectl get pods -n database -l app=postgres-exporter-simple -o jsonpath='{.items[0].metadata.name}')
    echo "Últimas linhas do log:"
    kubectl logs -n database $POD_NAME --tail=5
else
    echo "❌ Pod postgres-exporter-simple não encontrado"
fi

echo ""
echo "📊 7. Como acessar as interfaces:"
echo "🔗 Prometheus: kubectl port-forward -n development service/kube-prometheus-prometheus 9090:9090"
echo "🔗 Grafana: kubectl port-forward -n development service/grafana 3000:80"
echo "   - Usuário padrão: admin / senha pode ser obtida com:"
echo "     kubectl get secret -n development grafana -o jsonpath='{.data.admin-password}' | base64 -d"

echo ""
echo "📊 8. Queries úteis no Prometheus:"
echo "   - pg_database_size_bytes: Tamanho dos databases"
echo "   - pg_stat_database_numbackends: Conexões ativas"
echo "   - pg_stat_database_xact_commit: Transações commitadas"
echo "   - pg_stat_database_xact_rollback: Transações com rollback"
echo "   - pg_locks_count: Locks ativos"

echo ""
echo "=========================================="
echo "✅ Validação concluída!"
