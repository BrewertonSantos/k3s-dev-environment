# Database External Access Guide

## 📝 Documentation Conventions

This guide uses the following placeholders for environment-specific values:
- `{database}` - Replace with your actual database name (e.g., `myapp_db`, `production_data`)
- `{user}` - Replace with your actual username (e.g., `myapp_user`, `api_service`)
- `admin`, `root` - Default system users (use as-is)

## 🌐 Overview

This guide provides comprehensive instructions for connecting to MySQL and PostgreSQL databases from **outside the Kubernetes cluster** using multiple connection methods.

## ✅ Quick Test Results

### MySQL External Access (Working)
```bash
# TCP Connection Test
nc -zv localhost 3306
# ✅ Result: Connection successful!

# MySQL Client (authentication configured for internal networks)
mysql -h localhost -P 3306 -u root -p45oV8arIokIAYgLqa9bQ
# ⚠️ Note: May require hostname allowlist configuration for external access
```

### PostgreSQL External Access (Configured)
```bash
# TCP Connection Test  
nc -zv localhost 5432
# ⚠️ Status: Traefik TCP ingress configured, requires K3d port mapping

# Alternative: Port Forwarding (immediate solution)
kubectl port-forward -n database svc/postgres 5432:5432 &
PGPASSWORD=1q2w3e4r@123 psql -h localhost -p 5432 -U admin -d {database}
```

### Current Implementation Status
- **MySQL TCP Ingress**: ✅ Configured and TCP connection working
- **PostgreSQL TCP Ingress**: ✅ Configured, needs K3d port mapping
- **CloudBeaver Web Interface**: ✅ Working for both databases
- **Database Authentication**: ✅ Working for internal connections

## 🔌 Available Connection Methods

### 1. **Traefik TCP Ingress** (Direct External Access)
- **MySQL**: `localhost:3306`
- **PostgreSQL**: `localhost:5432`
- ✅ **Advantages**: Native database ports, works with any SQL client
- ⚠️ **Requirements**: Traefik TCP entrypoints must be configured

### 2. **Port Forwarding** (Development Method)
- **MySQL**: `kubectl port-forward` to any local port
- **PostgreSQL**: `kubectl port-forward` to any local port
- ✅ **Advantages**: Always works, no special configuration needed
- ⚠️ **Limitations**: Requires kubectl access, temporary connection

### 3. **Web Interface** (CloudBeaver)
- **Access**: http://cloudbeaver.localhost
- ✅ **Advantages**: No client installation needed, visual interface
- ⚠️ **Limitations**: Web-based only, requires browser

## 🚀 Method 1: Traefik TCP Ingress (Recommended)

### Configuration Status
| Database | Status | External Port | Internal Service |
|----------|--------|---------------|------------------|
| **MySQL** | ✅ Configured | `localhost:3306` | `mysql-service:3306` |
| **PostgreSQL** | ✅ Configured | `localhost:5432` | `postgres:5432` |

### Connection Details

#### MySQL External Connection
```bash
# Connection Parameters
Host: localhost
Port: 3306
Database: {database}
Username: {user}
Password: 6DHq81M5PTFas0m2

# Command Line Connection
mysql -h localhost -P 3306 -u {user} -p6DHq81M5PTFas0m2 {database}

# Connection String
mysql://{user}:6DHq81M5PTFas0m2@localhost:3306/{database}
```

#### PostgreSQL External Connection
```bash
# Connection Parameters
Host: localhost
Port: 5432
Database: {database}
Username: admin
Password: 1q2w3e4r@123

# Command Line Connection
psql -h localhost -p 5432 -U admin -d {database}

# Connection String
postgresql://admin:1q2w3e4r@123@localhost:5432/{database}
```

### Client Configuration Examples

#### DBeaver Configuration
1. **Create New Connection** → Choose database type
2. **Server Settings**:
   - **Server Host**: `localhost`
   - **Port**: `3306` (MySQL) or `5432` (PostgreSQL)
   - **Database**: `{database}` (MySQL) or `{database}` (PostgreSQL)
   - **Username**: `{user}` (MySQL) or `admin` (PostgreSQL)
   - **Password**: Use credentials above

#### DataGrip/IntelliJ Configuration
1. **Database Tool Window** → **+** → **Data Source**
2. **General Tab**:
   - **Host**: `localhost`
   - **Port**: `3306` or `5432`
   - **Database**: `{database}` or `{database}`
   - **User**: `{user}` or `admin`
   - **Password**: Use credentials above

#### TablePlus Configuration
1. **Create Connection** → Choose database type
2. **Connection Details**:
   - **Host**: `localhost`
   - **Port**: `3306` or `5432`
   - **Database**: `{database}` or `{database}`
   - **User**: `{user}` or `admin`
   - **Password**: Use credentials above

## 🔧 Method 2: Port Forwarding

### MySQL Port Forward
```bash
# Forward MySQL to local port 3306
kubectl port-forward -n database service/mysql-service 3306:3306

# Forward to alternative port (if 3306 is busy)
kubectl port-forward -n database service/mysql-service 13306:3306

# Connection after port forward
mysql -h localhost -P 3306 -u {user} -p6DHq81M5PTFas0m2 {user}
```

### PostgreSQL Port Forward
```bash
# Forward PostgreSQL to local port 5432
kubectl port-forward -n database service/postgres 5432:5432

# Forward to alternative port (if 5432 is busy)
kubectl port-forward -n database service/postgres 15432:5432

# Connection after port forward
psql -h localhost -p 5432 -U admin -d {database}
```

### Background Port Forwarding
```bash
# Run port forward in background
kubectl port-forward -n database service/mysql-service 3306:3306 &
kubectl port-forward -n database service/postgres 5432:5432 &

# List background jobs
jobs

# Stop background port forwards
pkill -f "kubectl port-forward.*mysql"
pkill -f "kubectl port-forward.*postgres"
```

## 🌐 Method 3: CloudBeaver Web Interface

### Access Information
- **URL**: http://cloudbeaver.localhost
- **Initial Setup**: Admin user creation required on first visit
- **Features**: Visual query builder, data export, schema browser

### Advantages
- No client software installation required
- Cross-platform compatibility
- Built-in data visualization
- Multiple database support in single interface

## 🔍 Connection Testing & Troubleshooting

### Test Traefik TCP Access
```bash
# Test MySQL TCP connectivity
telnet localhost 3306
# Should connect successfully

# Test PostgreSQL TCP connectivity
telnet localhost 5432
# Should connect successfully

# Test with netcat
nc -zv localhost 3306  # MySQL
nc -zv localhost 5432  # PostgreSQL
```

### Verify Service Status
```bash
# Check database pods are running
kubectl get pods -n database

# Check services are accessible
kubectl get svc -n database

# Check Traefik ingress routes
kubectl get ingressroutetcp -n database

# Check Traefik pod logs
kubectl logs -n traefik-system deployment/traefik
```

### Common Issues & Solutions

#### Issue: "Connection Refused"
**Symptoms**: Cannot connect to localhost:3306 or localhost:5432
**Solutions**:
```bash
# 1. Verify Traefik is running
kubectl get pods -n traefik-system

# 2. Check Traefik configuration
kubectl get configmap traefik-config -n traefik-system -o yaml

# 3. Restart Traefik
kubectl rollout restart deployment/traefik -n traefik-system

# 4. Apply TCP ingress configurations
kubectl apply -f k8s-manifests/database-mysql.yaml
kubectl apply -f k8s-manifests/postgres.yaml
```

#### Issue: "Access Denied" / Authentication Errors
**Symptoms**: Connection successful but login fails
**Solutions**:
```bash
# 1. Verify MySQL credentials
kubectl logs -n database deployment/mysql

# 2. Check PostgreSQL credentials
kubectl exec -n database deployment/postgres -- psql -U admin -d {database} -c "SELECT version();"

# 3. Get fresh credentials (if using dynamic passwords)
kubectl get secret -n database mysql-secret -o yaml
```

#### Issue: Port Already in Use
**Symptoms**: "Port 3306/5432 already in use" when port forwarding
**Solutions**:
```bash
# 1. Check what's using the port
lsof -i :3306
lsof -i :5432

# 2. Stop conflicting services
sudo systemctl stop mysql     # If local MySQL is running
sudo systemctl stop postgresql # If local PostgreSQL is running

# 3. Use alternative ports
kubectl port-forward -n database service/mysql-service 13306:3306
kubectl port-forward -n database service/postgres 15432:5432
```

## 🛡️ Security Considerations

### Development Environment
- **Passwords**: Static passwords for convenience
- **Network**: No encryption for internal traffic
- **Access**: Direct database access without additional authentication

### Production Recommendations
1. **Use Strong Passwords**: Generate unique, complex passwords
2. **Enable SSL/TLS**: Configure encrypted connections
3. **Network Policies**: Restrict database access to authorized services
4. **Authentication**: Implement additional authentication layers
5. **Monitoring**: Log and monitor database connections
6. **Firewall Rules**: Limit external access to specific IP ranges

## 📋 Connection Scripts

### MySQL Connection Script
```bash
#!/bin/bash
# mysql-connect.sh

DB_HOST="localhost"
DB_PORT="3306"
DB_NAME="{user}"
DB_USER="{user}"
DB_PASS="6DHq81M5PTFas0m2"

echo "Connecting to MySQL database..."
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME"
```

### PostgreSQL Connection Script
```bash
#!/bin/bash
# postgres-connect.sh

export PGHOST="localhost"
export PGPORT="5432"
export PGDATABASE="{database}"
export PGUSER="admin"
export PGPASSWORD="1q2w3e4r@123"

echo "Connecting to PostgreSQL database..."
psql
```

### Environment Variables Setup
```bash
# Add to ~/.bashrc or ~/.zshrc

# MySQL Environment
export MYSQL_HOST="localhost"
export MYSQL_PORT="3306"
export MYSQL_DATABASE="{user}"
export MYSQL_USER="{user}"
export MYSQL_PASSWORD="6DHq81M5PTFas0m2"

# PostgreSQL Environment
export PGHOST="localhost"
export PGPORT="5432"
export PGDATABASE="{database}"
export PGUSER="admin"
export PGPASSWORD="1q2w3e4r@123"
```

## 🔄 Deployment Commands

### Apply TCP Ingress Configuration
```bash
# Apply Traefik configuration with TCP entrypoints
kubectl apply -f k8s-manifests/traefik.yaml

# Apply MySQL TCP ingress
kubectl apply -f k8s-manifests/database-mysql.yaml

# Apply PostgreSQL TCP ingress
kubectl apply -f k8s-manifests/postgres.yaml

# Verify TCP routes are created
kubectl get ingressroutetcp -n database
```

### Restart Services
```bash
# Restart Traefik to apply new configuration
kubectl rollout restart deployment/traefik -n traefik-system

# Restart databases if needed
kubectl rollout restart deployment/mysql -n database
kubectl rollout restart deployment/postgres -n database

# Check service status
kubectl get pods -n database
kubectl get pods -n traefik-system
```

## 🔧 PostgreSQL External Access Configuration

### Current Status
- ✅ **Traefik TCP Ingress**: Configured and ready
- ✅ **PostgreSQL Service**: Running in database namespace  
- ⚠️ **K3d Port Mapping**: Required for `localhost:5432` access

### Solution Options

#### Option 1: Port Forwarding (Immediate Access)
```bash
# Start port forwarding (runs in background)
kubectl port-forward -n database svc/postgres 5432:5432 &

# Test connection
PGPASSWORD=1q2w3e4r@123 psql -h localhost -p 5432 -U admin -d {database}

# Stop port forwarding when done
pkill -f "port-forward.*postgres"
```

#### Option 2: Alternative Local Port
```bash
# Use different port if 5432 is occupied
kubectl port-forward -n database svc/postgres 15432:5432 &

# Connect using alternative port
PGPASSWORD=1q2w3e4r@123 psql -h localhost -p 15432 -U admin -d {database}
```

#### Option 3: K3d Cluster Recreation (Permanent Solution)
```bash
# Save current cluster state (optional)
kubectl get all --all-namespaces -o yaml > cluster-backup.yaml

# Delete and recreate cluster with PostgreSQL port mapping
k3d cluster delete k3s-dev

k3d cluster create k3s-dev \
  --port "80:80@loadbalancer" \
  --port "443:443@loadbalancer" \
  --port "3000:3000@loadbalancer" \
  --port "3306:30306@loadbalancer" \
  --port "5432:30432@loadbalancer" \
  --port "8080:8080@loadbalancer" \
  --port "9000-9001:9000-9001@loadbalancer" \
  --port "9090:9090@loadbalancer" \
  --port "16686:16686@loadbalancer"

# Redeploy services
kubectl apply -f k8s-manifests/
```

### Verification Steps
```bash
# Test TCP connectivity
nc -zv localhost 5432

# Test database connection
PGPASSWORD=1q2w3e4r@123 psql -h localhost -p 5432 -U admin -d {database} -c "SELECT version();"

# Test from external tools
psql postgresql://admin:1q2w3e4r@123@localhost:5432/{database}
```

### K3d Port Mapping Explanation
K3d (K3s in Docker) requires explicit port mapping to expose services on localhost. The current cluster was created without PostgreSQL port mapping:

- **Current**: MySQL mapped (`3306:30306`), PostgreSQL not mapped
- **Solution**: Add `5432:30432` mapping to expose PostgreSQL
- **Alternative**: Use port-forwarding for temporary access

## 📚 Integration Examples

### Application Connection Strings

#### Node.js (MySQL)
```javascript
const mysql = require('mysql2');

const connection = mysql.createConnection({
  host: 'localhost',
  port: 3306,
  user: '{user}',
  password: '6DHq81M5PTFas0m2',
  database: '{user}'
});
```

#### Python (PostgreSQL)
```python
import psycopg2

connection = psycopg2.connect(
    host='localhost',
    port=5432,
    database='{database}',
    user='admin',
    password='1q2w3e4r@123'
)
```

#### Java (JDBC)
```java
// MySQL
String url = "jdbc:mysql://localhost:3306/{user}";
String username = "{user}";
String password = "6DHq81M5PTFas0m2";

// PostgreSQL
String url = "jdbc:postgresql://localhost:5432/{database}";
String username = "admin";
String password = "1q2w3e4r@123";
```

### Docker Compose Integration
```yaml
# External service connecting to K3s databases
version: '3.8'
services:
  app:
    image: myapp:latest
    environment:
      - DATABASE_URL=mysql://{user}:6DHq81M5PTFas0m2@host.docker.internal:3306/{user}
      - POSTGRES_URL=postgresql://admin:1q2w3e4r@123@host.docker.internal:5432/{database}
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

## 🔍 Monitoring & Maintenance

### Connection Monitoring
```bash
# Monitor active connections
kubectl exec -n database deployment/mysql -- mysql -u {user} -p6DHq81M5PTFas0m2 -e "SHOW PROCESSLIST;"
kubectl exec -n database deployment/postgres -- psql -U admin -d {database} -c "SELECT * FROM pg_stat_activity;"

# Check connection metrics in Grafana
# Visit: http://grafana.localhost
# Look for "Database Connections" dashboard
```

### Health Checks
```bash
# Automated health check script
#!/bin/bash
echo "Testing database connectivity..."

# Test MySQL
if mysql -h localhost -P 3306 -u {user} -p6DHq81M5PTFas0m2 -e "SELECT 1;" 2>/dev/null; then
    echo "✅ MySQL: Connected successfully"
else
    echo "❌ MySQL: Connection failed"
fi

# Test PostgreSQL
if PGPASSWORD=1q2w3e4r@123 psql -h localhost -p 5432 -U admin -d {database} -c "SELECT 1;" 2>/dev/null; then
    echo "✅ PostgreSQL: Connected successfully"
else
    echo "❌ PostgreSQL: Connection failed"
fi
```

## 📖 Related Documentation

- [CloudBeaver Database Management](cloudbeaver/README.md)
- [Database Monitoring Infrastructure](../docs/DATABASE_MONITORING_INFRASTRUCTURE.md)
- [DNS & Ingress Configuration](../docs/DNS_INGRESS_CONFIGURATION.md)
- [Traefik Configuration](../docs/traefik/README.md)

---

**Note**: This configuration is optimized for development environments. Production deployments should implement additional security measures including SSL/TLS encryption, network policies, and proper authentication mechanisms.
