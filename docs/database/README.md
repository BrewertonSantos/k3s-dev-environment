# Database Management System

This document provides comprehensive documentation for the database management system deployed in the k3s development environment.

## Overview

The database management system consists of:
- **MySQL 8.0**: Primary database server with dynamic credential generation
- **PostgreSQL 16**: Secondary database server for multi-database projects  
- **CloudBeaver**: Web-based database management interface accessible at `database.localhost`

## Quick Start

### Deploy All Database Components

```bash
# Deploy all database components
./scripts/database.sh deploy all

# Or deploy individually
./scripts/database.sh deploy mysql
./scripts/database.sh deploy postgres
./scripts/database.sh deploy cloudbeaver
```

### Access CloudBeaver Interface

1. Open your browser and navigate to: http://database.localhost
2. Use the pre-configured database connections
3. For MySQL: Credentials are in `~/.kube/database-credentials/mysql.txt`
4. For PostgreSQL: Default credentials are `postgres` / `postgres123`

## Architecture

### Components

#### MySQL 8.0
- **Namespace**: `database`
- **Service**: `mysql-service.database.svc.cluster.local:3306`
- **Storage**: Persistent volume for data persistence
- **Security**: Dynamic credential generation with comprehensive privileges

#### PostgreSQL 16
- **Namespace**: `database` 
- **Service**: `postgres-service.database.svc.cluster.local:5432`
- **Storage**: Persistent volume for data persistence
- **Security**: Default credentials (changeable)

#### CloudBeaver
- **Namespace**: `database`
- **URL**: http://database.localhost
- **Ingress**: Traefik-based routing
- **Features**: Pre-configured database connections, web-based management

### Network Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   CloudBeaver   │    │      MySQL       │    │   PostgreSQL    │
│  database.      │    │      8.0         │    │       16        │
│  localhost      │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌──────────────────┐
                    │   Traefik Proxy  │
                    │   Port 80/443    │
                    └──────────────────┘
```

## Database Scripts

### Organization Structure

```
scripts/
├── database.sh                 # Main management script
├── mysql/                     # MySQL-specific scripts
│   ├── deploy-mysql.sh        # Deploy MySQL with dynamic credentials
│   ├── cleanup-mysql.sh       # Remove MySQL deployment
│   ├── fix-mysql-privileges.sh # Fix privilege issues (SQL Error 1227)
│   └── test-mysql-privileges.sh # Test MySQL privilege functionality
├── postgres/                  # PostgreSQL-specific scripts
│   ├── deploy-postgres.sh     # Deploy PostgreSQL
│   └── cleanup-postgres.sh    # Remove PostgreSQL deployment
└── cloudbeaver/              # CloudBeaver-specific scripts
    ├── deploy-cloudbeaver.sh  # Deploy CloudBeaver with ingress
    ├── cleanup-cloudbeaver.sh # Remove CloudBeaver deployment
    └── configure-cloudbeaver-connections.sh # Setup database connections
```

### Main Management Script

The `database.sh` script provides a unified interface for all database operations:

```bash
# Syntax
./scripts/database.sh <action> <component>

# Actions
deploy    # Deploy component(s)
cleanup   # Remove component(s) 
status    # Show component status
fix       # Fix component issues
configure # Configure component connections

# Components
mysql      # MySQL database
postgres   # PostgreSQL database  
cloudbeaver # CloudBeaver interface
all        # All components
```

### Examples

```bash
# Deploy all components
./scripts/database.sh deploy all

# Deploy only MySQL
./scripts/database.sh deploy mysql

# Check status of all components
./scripts/database.sh status all

# Fix MySQL privileges (resolves SQL Error 1227)
./scripts/database.sh fix mysql

# Configure CloudBeaver connections
./scripts/database.sh configure cloudbeaver

# Clean up all components
./scripts/database.sh cleanup all
```

## MySQL Configuration

### Dynamic Credential Generation

MySQL deployment automatically generates secure credentials:

```bash
# Generated credentials saved to:
~/.kube/database-credentials/mysql.txt

# File format:
Database: porigins_db
User: porigins
Password: <16-character-random>
Root Password: <20-character-random>
Service: mysql-service.database.svc.cluster.local:3306
```

### Privilege Management

The MySQL user is granted comprehensive privileges to prevent SQL Error 1227:

- `ALL PRIVILEGES` on the application database
- `SUPER` administrative privileges
- `SYSTEM_VARIABLES_ADMIN` for system variable access
- `RELOAD`, `PROCESS`, `SHOW DATABASES`
- `REPLICATION CLIENT`, `REPLICATION SLAVE`
- `SELECT` on system databases (mysql, information_schema, performance_schema, sys)

### Troubleshooting MySQL

#### SQL Error 1227 (Access Denied)

If you encounter "Access denied; you need (at least one of) the SUPER privilege(s) for this operation":

```bash
# Fix privileges automatically
./scripts/database.sh fix mysql

# Or run manually
./scripts/mysql/fix-mysql-privileges.sh

# Test privileges
./scripts/mysql/test-mysql-privileges.sh
```

## PostgreSQL Configuration

### Default Configuration

PostgreSQL uses default credentials for development:
- **User**: `postgres`
- **Password**: `postgres123`
- **Database**: `postgres`

### Changing PostgreSQL Credentials

To use custom credentials, modify the PostgreSQL deployment script:

```bash
# Edit deployment script
vim scripts/postgres/deploy-postgres.sh

# Update environment variables
POSTGRES_PASSWORD="your-secure-password"
```

## CloudBeaver Configuration

### Access Methods

1. **Web Interface**: http://database.localhost
2. **Direct Connection**: Use database service endpoints

### Pre-configured Connections

CloudBeaver comes with pre-configured connections:

#### MySQL Connection
- **Host**: `mysql-service.database.svc.cluster.local`
- **Port**: `3306`
- **Database**: `porigins_db`
- **User**: `porigins`
- **Password**: *(from credentials file)*

#### PostgreSQL Connection  
- **Host**: `postgres-service.database.svc.cluster.local`
- **Port**: `5432`
- **Database**: `postgres`
- **User**: `postgres`
- **Password**: `postgres123`

### Initial Setup

1. Navigate to http://database.localhost
2. Create CloudBeaver admin account (first time only)
3. Use pre-configured connections or create new ones
4. Start managing your databases

## Security Considerations

### Development vs Production

⚠️ **Important**: This configuration is designed for development environments.

#### Development Defaults
- PostgreSQL uses default credentials for convenience
- CloudBeaver admin interface allows credential saving
- Ingress provides HTTP access (not HTTPS)

#### Production Recommendations
1. **Change Default Credentials**: Immediately change all default passwords
2. **Enable HTTPS**: Configure TLS certificates for ingress
3. **Restrict Access**: Implement proper authentication and authorization
4. **Secrets Management**: Use Kubernetes secrets for all credentials
5. **Network Security**: Implement network policies for database access

### Credential Storage

- MySQL credentials: Generated dynamically, stored in `~/.kube/database-credentials/`
- PostgreSQL credentials: Default values, changeable in deployment scripts
- CloudBeaver credentials: Configured during first setup

## Monitoring and Maintenance

### Health Checks

```bash
# Check all database pods
kubectl get pods -n database

# Check specific deployments
kubectl get deployment -n database mysql
kubectl get deployment -n database postgres
kubectl get deployment -n database cloudbeaver

# View logs
kubectl logs -n database deployment/mysql
kubectl logs -n database deployment/postgres
kubectl logs -n database deployment/cloudbeaver
```

### Storage Management

```bash
# Check persistent volumes
kubectl get pv | grep database

# Check persistent volume claims
kubectl get pvc -n database

# Storage usage
kubectl exec -n database deployment/mysql -- df -h
kubectl exec -n database deployment/postgres -- df -h
```

### Backup Considerations

- Persistent volumes provide data persistence across pod restarts
- For production, implement proper backup strategies
- Consider database-specific backup tools (mysqldump, pg_dump)

## Troubleshooting

### Common Issues

#### CloudBeaver 404 Error
```bash
# Clean workspace and redeploy
./scripts/database.sh cleanup cloudbeaver
./scripts/database.sh deploy cloudbeaver
```

#### MySQL Connection Errors
```bash
# Check MySQL pod status
kubectl get pods -n database -l app=mysql

# Fix privileges if needed
./scripts/database.sh fix mysql
```

#### PostgreSQL Connection Issues
```bash
# Check PostgreSQL pod status
kubectl get pods -n database -l app=postgres

# View logs for errors
kubectl logs -n database deployment/postgres
```

### Debug Commands

```bash
# Port forward for direct database access
kubectl port-forward -n database service/mysql-service 3306:3306
kubectl port-forward -n database service/postgres-service 5432:5432

# Execute commands inside containers
kubectl exec -it -n database deployment/mysql -- mysql -u root -p
kubectl exec -it -n database deployment/postgres -- psql -U postgres

# Check service endpoints
kubectl get endpoints -n database
```

## Integration Examples

### Application Configuration

#### Spring Boot (MySQL)
```yaml
spring:
  datasource:
    url: jdbc:mysql://mysql-service.database.svc.cluster.local:3306/porigins_db
    username: porigins
    password: ${MYSQL_PASSWORD}  # From environment or config
```

#### Node.js (PostgreSQL)
```javascript
const { Pool } = require('pg');

const pool = new Pool({
  host: 'postgres-service.database.svc.cluster.local',
  port: 5432,
  database: 'postgres',
  user: 'postgres',
  password: 'postgres123'
});
```

### Environment Variables

```bash
# MySQL connection
export MYSQL_HOST=mysql-service.database.svc.cluster.local
export MYSQL_PORT=3306
export MYSQL_DATABASE=porigins_db
export MYSQL_USER=porigins
export MYSQL_PASSWORD=$(grep "Password:" ~/.kube/database-credentials/mysql.txt | awk '{print $2}')

# PostgreSQL connection
export POSTGRES_HOST=postgres-service.database.svc.cluster.local
export POSTGRES_PORT=5432
export POSTGRES_DATABASE=postgres
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres123
```

## Contributing

### Adding New Database Types

1. Create component directory under `scripts/`
2. Implement deploy and cleanup scripts
3. Add component to main `database.sh` script
4. Update documentation
5. Test integration with CloudBeaver

### Script Development Guidelines

- Use consistent error handling and logging
- Implement proper cleanup procedures  
- Generate secure credentials dynamically
- Document configuration options
- Test with various deployment scenarios

---

## Quick Reference

| Component | URL/Endpoint | Default Credentials |
|-----------|--------------|-------------------|
| CloudBeaver | http://database.localhost | *Setup during first visit* |
| MySQL | mysql-service.database.svc.cluster.local:3306 | *Generated dynamically* |
| PostgreSQL | postgres-service.database.svc.cluster.local:5432 | postgres / postgres123 |

| Script | Purpose |
|--------|---------|
| `./scripts/database.sh deploy all` | Deploy complete database system |
| `./scripts/database.sh status all` | Check all component status |
| `./scripts/database.sh fix mysql` | Fix MySQL privileges |
| `./scripts/database.sh cleanup all` | Remove all database components |
