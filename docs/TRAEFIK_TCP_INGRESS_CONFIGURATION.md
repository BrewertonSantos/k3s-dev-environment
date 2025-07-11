# Traefik TCP Ingress Configuration

## 📝 Overview

This document describes the Traefik TCP ingress configuration for direct external database access. This enables native database clients to connect to MySQL and PostgreSQL using standard ports (3306, 5432) without port forwarding.

## 🎯 Architecture

### TCP Entrypoints
Traefik is configured with specialized TCP entrypoints for database connections:

```yaml
# Traefik Configuration
entryPoints:
  mysql:
    address: ":3306"
  postgres:
    address: ":5432"
  web:
    address: ":80"
  websecure:
    address: ":443"
```

### Routing Logic
```
External Client → localhost:3306 → Traefik → mysql-service:3306
External Client → localhost:5432 → Traefik → postgres:5432
```

## 🚀 Implementation

### 1. Traefik Service Configuration
Enhanced Traefik with TCP ports:

```yaml
# k8s-manifests/traefik.yaml
apiVersion: v1
kind: Service
metadata:
  name: traefik
  namespace: kube-system
spec:
  ports:
  - name: web
    port: 80
    protocol: TCP
  - name: websecure
    port: 443
    protocol: TCP
  - name: mysql-tcp     # New TCP port
    port: 3306
    protocol: TCP
    targetPort: 3306
  - name: postgres-tcp  # New TCP port
    port: 5432
    protocol: TCP
    targetPort: 5432
```

### 2. MySQL TCP Ingress Route
```yaml
# Direct MySQL access configuration
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: mysql-tcp-ingress
  namespace: database
spec:
  entryPoints:
    - mysql
  routes:
  - match: HostSNI(`*`)
    services:
    - name: mysql-service
      port: 3306
```

### 3. PostgreSQL TCP Ingress Route
```yaml
# Direct PostgreSQL access configuration
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: postgres-tcp-ingress
  namespace: database
spec:
  entryPoints:
    - postgres
  routes:
  - match: HostSNI(`*`)
    services:
    - name: postgres
      port: 5432
```

## 🔧 Configuration Details

### IngressClass Setup
```yaml
# k8s-manifests/traefik-ingressclass.yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: traefik
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"
spec:
  controller: traefik.io/ingress-controller
```

### DNS Resolution
For HTTP ingress routes, we use `.localhost` domains:
- `grafana.localhost`
- `prometheus.localhost`
- `cloudbeaver.localhost`
- `opensearch.localhost`

### Port Mapping Requirements
For K3d clusters, external access requires port mapping:

```bash
# K3d cluster creation with database ports
k3d cluster create k3s-dev \
  --port "80:80@loadbalancer" \
  --port "443:443@loadbalancer" \
  --port "3306:3306@loadbalancer" \
  --port "5432:5432@loadbalancer"
```

## 📋 Connection Examples

### MySQL External Connection
```bash
# Command line
mysql -h localhost -P 3306 -u {user} -p{password} {database}

# Connection string
mysql://{user}:{password}@localhost:3306/{database}

# Test connectivity
nc -zv localhost 3306
```

### PostgreSQL External Connection
```bash
# Command line
psql -h localhost -p 5432 -U admin -d {database}

# Connection string
postgresql://admin:{password}@localhost:5432/{database}

# Test connectivity
nc -zv localhost 5432
```

## 🧪 Testing and Validation

### Connectivity Tests
```bash
# Test MySQL TCP connection
telnet localhost 3306

# Test PostgreSQL TCP connection
telnet localhost 5432

# Verify Traefik routing
kubectl logs -n kube-system deployment/traefik | grep -i tcp
```

### Client Configuration Tests
```bash
# Test with database clients
mysql -h localhost -P 3306 --protocol=TCP -u {user} -p
psql -h localhost -p 5432 -U admin -d {database}

# Test with GUI tools (DBeaver, DataGrip, etc.)
# Use localhost:3306 or localhost:5432 as connection details
```

## 🛡️ Security Considerations

### Development Environment
- **Direct Access**: No encryption for TCP connections
- **Authentication**: Standard database authentication only
- **Network**: Exposed on all interfaces via localhost

### Production Recommendations
1. **TLS Termination**: Configure SSL/TLS for database connections
2. **Network Policies**: Restrict access to specific IP ranges
3. **Authentication**: Use strong passwords and certificate authentication
4. **Monitoring**: Log and monitor TCP connections
5. **Firewall**: Configure firewall rules for database ports

## 📊 Monitoring and Troubleshooting

### Traefik Dashboard
Access Traefik dashboard to monitor TCP routes:
```bash
kubectl port-forward -n kube-system deployment/traefik 8080:8080
# Visit: http://localhost:8080/dashboard/
```

### TCP Route Status
```bash
# Check IngressRouteTCP resources
kubectl get ingressroutetcp -A

# Describe specific routes
kubectl describe ingressroutetcp mysql-tcp-ingress -n database
kubectl describe ingressroutetcp postgres-tcp-ingress -n database
```

### Connection Debugging
```bash
# Check service endpoints
kubectl get endpoints -n database mysql-service
kubectl get endpoints -n database postgres

# Test internal connectivity
kubectl run test-pod --rm -i --tty --restart=Never --image=busybox -- nc -zv mysql-service.database.svc.cluster.local 3306
```

## 🔄 Alternative Connection Methods

### 1. Port Forwarding (Temporary)
```bash
# MySQL port forward
kubectl port-forward -n database service/mysql-service 3306:3306 &

# PostgreSQL port forward
kubectl port-forward -n database service/postgres 5432:5432 &
```

### 2. CloudBeaver Web Interface
- **URL**: http://cloudbeaver.localhost
- **Advantages**: No client installation required
- **Features**: Visual query builder, data export

### 3. NodePort Services (Alternative)
```yaml
# Alternative: NodePort service
apiVersion: v1
kind: Service
metadata:
  name: mysql-nodeport
spec:
  type: NodePort
  ports:
  - port: 3306
    nodePort: 30306
  selector:
    app: mysql
```

## 🔗 Integration Examples

### Application Configuration
```yaml
# Application ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-database-config
data:
  MYSQL_HOST: "mysql-service.database.svc.cluster.local"
  MYSQL_PORT: "3306"
  POSTGRES_HOST: "postgres.database.svc.cluster.local"
  POSTGRES_PORT: "5432"
```

### External Application Configuration
```bash
# Environment variables for external apps
export MYSQL_HOST="localhost"
export MYSQL_PORT="3306"
export POSTGRES_HOST="localhost"
export POSTGRES_PORT="5432"
```

## 🔗 Related Documentation

- [Database External Access Guide](./DATABASE_EXTERNAL_ACCESS.md)
- [DNS Ingress Configuration](./DNS_INGRESS_CONFIGURATION.md)
- [MySQL Deployment Strategy Fix](./MYSQL_DEPLOYMENT_STRATEGY_FIX.md)

## 📅 Change History

| Date | Change | Author |
|------|--------|---------|
| 2025-07-11 | Initial TCP ingress implementation | System |
| 2025-07-11 | Documentation created | System |

---

> **Note**: TCP ingress provides native database access but requires proper K3d port mapping for external connectivity.
