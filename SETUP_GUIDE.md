# K3s Development Environment Setup Guide

This guide provides step-by-step instructions for setting up the complete k3s development environment with database management capabilities.

## Prerequisites

### System Requirements
- macOS (tested on macOS 12+)
- Docker Desktop installed and running
- Homebrew package manager
- At least 8GB RAM available for containers
- 20GB free disk space

### Network Requirements
- Ports 80, 443 available for ingress
- No conflicting services on standard database ports
- Internet access for downloading container images

## Quick Start

### 1. Initial Environment Setup

```bash
# Clone or navigate to the k3s-dev-environment directory
cd k3s-dev-environment

# Run the main setup script
./scripts/k3s-dev-env.sh

# Setup local DNS (adds entries to /etc/hosts)
./scripts/setup-hosts.sh
```

### 2. Deploy Database System

```bash
# Deploy all database components (MySQL + PostgreSQL + CloudBeaver)
./scripts/database.sh deploy all

# Or deploy components individually
./scripts/database.sh deploy mysql      # MySQL only
./scripts/database.sh deploy postgres   # PostgreSQL only  
./scripts/database.sh deploy cloudbeaver # CloudBeaver only
```

### 3. Access Database Interface

1. Open browser: http://database.localhost
2. Setup CloudBeaver admin account (first time)
3. Use pre-configured database connections

## Components Overview

### Core Infrastructure
- **K3s**: Lightweight Kubernetes distribution
- **Traefik**: Ingress controller and load balancer
- **Local Registry**: Container image registry

### Database Stack
- **MySQL 8.0**: Primary database with dynamic credentials
- **PostgreSQL 16**: Secondary database for multi-DB projects
- **CloudBeaver**: Web-based database management

### Monitoring (Optional)
- **Prometheus**: Metrics collection
- **Grafana**: Metrics visualization
- **ArgoCD**: GitOps deployment management

## Essential Scripts

### Main Management Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `k3s-dev-env.sh` | Complete environment setup | `./scripts/k3s-dev-env.sh` |
| `database.sh` | Database management | `./scripts/database.sh <action> <component>` |
| `setup-hosts.sh` | Configure local DNS | `./scripts/setup-hosts.sh` |
| `show-services.sh` | Display service status | `./scripts/show-services.sh` |

### Database Component Scripts

#### MySQL Scripts (`scripts/mysql/`)
- `deploy-mysql.sh` - Deploy MySQL with dynamic credentials
- `cleanup-mysql.sh` - Remove MySQL deployment
- `fix-mysql-privileges.sh` - Fix privilege issues (SQL Error 1227)
- `test-mysql-privileges.sh` - Test MySQL functionality

#### PostgreSQL Scripts (`scripts/postgres/`)
- `deploy-postgres.sh` - Deploy PostgreSQL
- `cleanup-postgres.sh` - Remove PostgreSQL deployment

#### CloudBeaver Scripts (`scripts/cloudbeaver/`)
- `deploy-cloudbeaver.sh` - Deploy CloudBeaver with ingress
- `cleanup-cloudbeaver.sh` - Remove CloudBeaver deployment
- `configure-cloudbeaver-connections.sh` - Setup database connections

### Utility Scripts

| Script | Purpose |
|--------|---------|
| `health-check.sh` | Check system health |
| `setup-access.sh` | Configure access credentials |
| `setup-port-forwards.sh` | Setup port forwarding |
| `test-ingress.sh` | Test ingress functionality |
| `verify-urls.sh` | Verify all URLs are accessible |

## Step-by-Step Setup

### 1. Environment Preparation

```bash
# Ensure Docker is running
docker info

# Install required tools (if not already installed)
brew install kubectl helm

# Verify system requirements
./scripts/health-check.sh
```

### 2. K3s Cluster Setup

```bash
# Start k3s cluster with required configuration
./scripts/k3s-dev-env.sh

# Verify cluster is ready
kubectl get nodes
kubectl get pods -A
```

### 3. Network Configuration

```bash
# Configure local DNS for development URLs
sudo ./scripts/setup-hosts.sh

# Verify ingress is working
./scripts/test-ingress.sh
```

### 4. Database Deployment

```bash
# Deploy MySQL (with dynamic credentials)
./scripts/database.sh deploy mysql

# Deploy PostgreSQL (with default credentials)
./scripts/database.sh deploy postgres

# Deploy CloudBeaver (web interface)
./scripts/database.sh deploy cloudbeaver

# Verify all components are running
./scripts/database.sh status all
```

### 5. CloudBeaver Initial Setup

1. Navigate to http://database.localhost
2. Create admin account:
   - Username: `admin`
   - Password: `<your-secure-password>`
3. Access pre-configured connections:
   - **MySQL**: Uses generated credentials
   - **PostgreSQL**: Uses default credentials

### 6. Test Database Connectivity

```bash
# Test MySQL privileges (should resolve SQL Error 1227)
./scripts/mysql/test-mysql-privileges.sh

# Test PostgreSQL connection
kubectl exec -n database deployment/postgres -- psql -U postgres -c "SELECT version();"

# Test CloudBeaver interface
curl -I http://database.localhost
```

## Configuration Details

### MySQL Configuration
- **Dynamic Credentials**: Generated during deployment
- **Storage**: 10Gi persistent volume
- **Privileges**: Comprehensive privileges to prevent SQL errors
- **Network**: Internal cluster DNS + external access via CloudBeaver

### PostgreSQL Configuration
- **Default Credentials**: postgres/postgres123 (changeable)
- **Storage**: 10Gi persistent volume
- **Network**: Internal cluster DNS + external access via CloudBeaver

### CloudBeaver Configuration
- **Admin Interface**: http://database.localhost
- **Pre-configured Connections**: MySQL and PostgreSQL
- **Workspace**: Persistent configuration storage

## Troubleshooting

### Common Issues

#### K3s Cluster Issues
```bash
# Check cluster status
kubectl get nodes
kubectl get pods -A

# Restart k3s if needed
sudo systemctl restart k3s

# Check logs
sudo journalctl -u k3s -f
```

#### Database Connection Issues
```bash
# Check database pods
kubectl get pods -n database

# Check MySQL logs
kubectl logs -n database deployment/mysql

# Check PostgreSQL logs  
kubectl logs -n database deployment/postgres

# Fix MySQL privileges
./scripts/database.sh fix mysql
```

#### Ingress/DNS Issues
```bash
# Verify hosts file entries
cat /etc/hosts | grep localhost

# Test ingress
./scripts/test-ingress.sh

# Check Traefik logs
kubectl logs -n kube-system deployment/traefik
```

#### CloudBeaver Issues
```bash
# Check CloudBeaver logs
kubectl logs -n database deployment/cloudbeaver

# Clean and redeploy if needed
./scripts/database.sh cleanup cloudbeaver
./scripts/database.sh deploy cloudbeaver
```

### Debug Commands

```bash
# Get all resource status
kubectl get all -A

# Check persistent volumes
kubectl get pv,pvc -A

# Port forward for direct access
kubectl port-forward -n database svc/mysql-service 3306:3306
kubectl port-forward -n database svc/postgres-service 5432:5432

# Execute commands in containers
kubectl exec -it -n database deployment/mysql -- mysql -u root -p
kubectl exec -it -n database deployment/postgres -- psql -U postgres
```

## Security Notes

### Development Environment
⚠️ **This configuration is optimized for development, not production**

#### Default Security Settings
- PostgreSQL uses default password (`postgres123`)
- CloudBeaver allows credential saving
- HTTP ingress (no TLS)
- Permissive network policies

#### Production Recommendations
1. **Change all default passwords**
2. **Enable TLS for all ingress**
3. **Implement proper RBAC**
4. **Use secrets management**
5. **Enable network policies**
6. **Regular security updates**

### Credential Management

#### MySQL Credentials
- **Location**: `~/.kube/database-credentials/mysql.txt`
- **Generation**: Dynamic during deployment
- **Access**: Root and application user credentials

#### PostgreSQL Credentials
- **Default**: postgres/postgres123
- **Change**: Edit deployment script before running
- **Production**: Use Kubernetes secrets

## Maintenance

### Regular Maintenance Tasks

```bash
# Check system health
./scripts/health-check.sh

# Verify all services
./scripts/show-services.sh

# Update container images (when needed)
kubectl rollout restart deployment -n database

# Backup important data (production)
kubectl exec -n database deployment/mysql -- mysqldump -u root -p<password> porigins_db > backup.sql
kubectl exec -n database deployment/postgres -- pg_dump -U postgres postgres > backup.sql
```

### Cleanup

```bash
# Remove specific components
./scripts/database.sh cleanup mysql
./scripts/database.sh cleanup postgres
./scripts/database.sh cleanup cloudbeaver

# Remove all database components
./scripts/database.sh cleanup all

# Complete environment cleanup
./scripts/k3s-dev-env.sh cleanup  # If available
```

## Next Steps

### Development Usage
1. **Connect Applications**: Use internal DNS names for database connections
2. **Database Management**: Use CloudBeaver for GUI operations
3. **Monitoring**: Access Grafana and Prometheus if deployed
4. **Scaling**: Add more database instances as needed

### Production Migration
1. **Security Hardening**: Implement production security measures
2. **TLS Configuration**: Enable HTTPS for all services
3. **Backup Strategy**: Implement automated backups
4. **Monitoring**: Setup comprehensive monitoring and alerting
5. **High Availability**: Configure clustering and replication

---

## Quick Reference

### URLs
- **CloudBeaver**: http://database.localhost
- **Grafana**: http://grafana.localhost (if deployed)
- **Prometheus**: http://prometheus.localhost (if deployed)

### Database Connections
```bash
# MySQL
Host: mysql-service.database.svc.cluster.local
Port: 3306
Database: porigins_db
User: porigins
Password: <see ~/.kube/database-credentials/mysql.txt>

# PostgreSQL  
Host: postgres-service.database.svc.cluster.local
Port: 5432
Database: postgres
User: postgres
Password: postgres123
```

### Essential Commands
```bash
# Deploy everything
./scripts/k3s-dev-env.sh && ./scripts/database.sh deploy all

# Check status
./scripts/show-services.sh

# Access databases
./scripts/database.sh status all

# Fix issues
./scripts/database.sh fix mysql
```
