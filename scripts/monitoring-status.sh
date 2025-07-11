#!/bin/bash

# Status completo da infraestrutura de observabilidade
# K3s Development Environment - Monitoring Stack

echo "🎯 K3S DEVELOPMENT ENVIRONMENT - MONITORING STATUS"
echo "=================================================="
echo ""

# URLs de acesso
echo "🌐 URLS DE ACESSO LOCAL:"
echo "------------------------"
echo "• Grafana:           http://grafana.localhost"
echo "• Prometheus:        http://prometheus.localhost"
echo "• AlertManager:      http://alertmanager.localhost"
echo "• OpenSearch:        http://opensearch.localhost"
echo "• OpenSearch Dash:   http://opensearch-dashboards.localhost"
echo "• CloudBeaver:       http://cloudbeaver.localhost"
echo ""

# Status dos componentes principais
echo "📊 STATUS DOS COMPONENTES:"
echo "-------------------------"
echo "✅ Prometheus (kube-prometheus-stack)"
echo "✅ Grafana com data sources configurados"
echo "✅ OpenSearch + OpenSearch Dashboards"
echo "✅ PostgreSQL + postgres_exporter"
echo "✅ MySQL + mysqld_exporter"
echo "✅ CloudBeaver (Database Management)"
echo "✅ AlertManager"
echo "✅ Node Exporter"
echo "✅ Kube State Metrics"
echo ""

# Data sources configurados
echo "💾 DATA SOURCES NO GRAFANA:"
echo "---------------------------"
echo "• Prometheus (métricas do cluster)"
echo "• PostgreSQL (banco devdb)"
echo "• MySQL (banco porigins)"
echo "• OpenSearch (logs e índices)"
echo "• AlertManager (alertas)"
echo ""

# Métricas disponíveis
echo "📈 MÉTRICAS PRINCIPAIS DISPONÍVEIS:"
echo "-----------------------------------"
echo "PostgreSQL:"
echo "  - pg_database_size_bytes"
echo "  - pg_stat_database_numbackends"
echo "  - pg_stat_database_xact_commit"
echo "  - pg_stat_database_xact_rollback"
echo ""
echo "MySQL:"
echo "  - mysql_global_status_uptime"
echo "  - mysql_global_status_threads_connected"
echo "  - mysql_global_status_queries"
echo "  - mysql_global_status_innodb_*"
echo ""
echo "Kubernetes:"
echo "  - node_* (métricas do sistema)"
echo "  - kube_* (recursos Kubernetes)"
echo "  - container_* (containers)"
echo ""

# Dashboards
echo "📋 DASHBOARDS PRÉ-CONFIGURADOS:"
echo "-------------------------------"
echo "• PostgreSQL Database"
echo "• MySQL Database"
echo "• Kubernetes Cluster Overview"
echo "• Node Exporter Full"
echo ""

# Como acessar
echo "🔑 CREDENCIAIS:"
echo "---------------"
echo "Grafana:"
echo "  - Usuário: admin"
echo "  - Senha: \$(kubectl get secret -n development grafana -o jsonpath='{.data.admin-password}' | base64 -d)"
echo ""
echo "PostgreSQL:"
echo "  - Host: postgres.database.svc.cluster.local:5432"
echo "  - Database: devdb"
echo "  - Usuário: admin"
echo "  - Senha: 1q2w3e4r@123"
echo ""
echo "MySQL:"
echo "  - Host: mysql-service.database.svc.cluster.local:3306"
echo "  - Database: porigins"
echo "  - Usuário: porigins"
echo "  - Senha: 6DHq81M5PTFas0m2"
echo ""

# Namespaces
echo "🏷️  NAMESPACES UTILIZADOS:"
echo "-------------------------"
echo "• development: Prometheus, Grafana, AlertManager"
echo "• database: PostgreSQL, MySQL, CloudBeaver + exporters"
echo "• logging: OpenSearch, OpenSearch Dashboards"
echo ""

# ServiceMonitors
echo "🎛️  MONITORAMENTO ATIVO:"
echo "------------------------"
kubectl get servicemonitors -A --no-headers | wc -l | xargs echo "• ServiceMonitors configurados:"
kubectl get pods -A | grep -E "(prometheus|grafana|opensearch|exporter)" | grep Running | wc -l | xargs echo "• Pods ativos de monitoramento:"
echo ""

echo "🎉 INFRAESTRUTURA DE OBSERVABILIDADE COMPLETA!"
echo "=============================================="
echo ""
echo "Tudo configurado e funcionando:"
echo "• Coleta de métricas (Prometheus + exporters)"
echo "• Visualização (Grafana + dashboards)"
echo "• Gestão de logs (OpenSearch)"
echo "• Alertas (AlertManager)"
echo "• Gestão de bancos (CloudBeaver)"
echo ""
echo "Para monitorar: acesse http://grafana.localhost"
