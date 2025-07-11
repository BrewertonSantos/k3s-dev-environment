# CloudBeaver - Universal Database Management Tool

> **📝 Documentation Note**: This guide uses `{database}` and `{user}` as placeholders for your actual database names and usernames. Default system users like `admin` and `root` are shown as-is.

CloudBeaver is a cloud database manager that provides a web-based interface for working with various databases. In our k3s development environment, CloudBeaver serves as the universal database management tool, replacing database-specific tools like phpMyAdmin and pgAdmin.

## Overview

CloudBeaver supports multiple database types and provides a unified interface for database administration, query execution, and data visualization.

### Supported Databases
- PostgreSQL
- MySQL/MariaDB
- SQLite
- Oracle
- SQL Server
- MongoDB
- Redis
- And many more...

## Deployment Architecture

CloudBeaver is deployed in the `database` namespace alongside our database services:

```
database namespace:
├── PostgreSQL (postgres-service:5432)
├── MySQL (mysql-service:3306)
└── CloudBeaver (cloudbeaver-service:8978)
```

## Access Information

### Web Interface
- **Local Access**: http://localhost:8978
- **Cluster Access**: http://cloudbeaver-service.database.svc.cluster.local:8978
- **External Access**: Configure ingress for external access

### Service Details
```yaml
Service: cloudbeaver-service
Namespace: database
Port: 8978
Target Port: 8978
```

## Database Connections

CloudBeaver can connect to all databases in our environment using internal cluster addresses:

### PostgreSQL Connection
```
Host: postgres-service.database.svc.cluster.local
Port: 5432
Database: postgres
Username: postgres
Password: postgres123
```

### MySQL Connection
```
Host: mysql-service.database.svc.cluster.local
Port: 3306
Database: porigins_db
Username: porigins
Password: <generated at deployment>
```

> Note: MySQL credentials are generated dynamically during deployment and saved to `~/.kube/database-credentials/mysql.txt`

## Initial Setup

### First-Time Configuration

1. **Access CloudBeaver**:
   ```bash
   # Port forward to access locally
   kubectl port-forward -n database service/cloudbeaver-service 8978:8978
   ```

2. **Open in Browser**: http://localhost:8978

3. **Complete Initial Setup**:
   - Create admin user (first visit only)
   - Configure global settings
   - Add database connections

### Adding Database Connections

#### PostgreSQL Connection Setup
1. Click "New Connection"
2. Select "PostgreSQL"
3. Configure connection:
   - **Host**: `postgres-service.database.svc.cluster.local`
   - **Port**: `5432`
   - **Database**: `postgres`
   - **Username**: `postgres`
   - **Password**: `postgres123`
4. Test connection and save

#### MySQL Connection Setup
1. Click "New Connection"
2. Select "MySQL"
3. Configure connection:
   - **Host**: `mysql-service.database.svc.cluster.local`
   - **Port**: `3306`
   - **Database**: `porigins_db`
   - **Username**: `porigins`
   - **Password**: *(Use password from `~/.kube/database-credentials/mysql.txt`)*
4. Test connection and save

> Note: CloudBeaver's connection is pre-configured with these values during deployment

## Features

### Database Administration
- **Schema Browser**: View tables, views, procedures, and functions
- **Data Editor**: Edit table data with a spreadsheet-like interface
- **Query Console**: Execute SQL queries with syntax highlighting
- **Visual Query Builder**: Build queries using a visual interface

### Data Management
- **Import/Export**: Support for various formats (CSV, JSON, SQL)
- **Data Visualization**: Charts and graphs for data analysis
- **ERD**: Entity Relationship Diagrams for database schema

### Multi-Database Support
- **Connection Management**: Manage multiple database connections
- **Cross-Database Queries**: Query data across different database types
- **Unified Interface**: Single interface for all database operations

## Management Commands

### Deployment Management
```bash
# Check CloudBeaver status
kubectl get pods -n database -l app=cloudbeaver

# View CloudBeaver logs
kubectl logs -n database -l app=cloudbeaver

# Restart CloudBeaver
kubectl rollout restart deployment/cloudbeaver -n database

# Port forward for local access
kubectl port-forward -n database service/cloudbeaver-service 8978:8978
```

### Configuration Management
```bash
# Check CloudBeaver service
kubectl get svc -n database cloudbeaver-service

# Describe CloudBeaver deployment
kubectl describe deployment cloudbeaver -n database

# Check CloudBeaver configuration
kubectl get configmap -n database cloudbeaver-config
```

## Configuration

### Environment Variables
```yaml
env:
- name: CLOUDBEAVER_WORKSPACE
  value: "/opt/cloudbeaver/workspace"
- name: CLOUDBEAVER_WEB_CONFIG_PATH
  value: "/opt/cloudbeaver/conf"
```

### Workspace Storage
Currently using `emptyDir` for workspace storage to avoid admin user conflicts:

```yaml
volumes:
- name: cloudbeaver-workspace
  emptyDir: {}
```

**Note**: This means configurations are lost on pod restart. For production, consider using persistent volumes after initial setup.

## Troubleshooting

### Common Issues

#### 1. Admin User Already Exists Error
**Symptom**: Error message about admin user already existing
**Solution**: 
- Delete the deployment and redeploy
- Or use persistent storage and manually clean the workspace

#### 2. Cannot Connect to Databases
**Symptom**: Connection timeouts or failures
**Solution**:
- Verify database services are running
- Check network policies
- Confirm service DNS names and ports

#### 3. CloudBeaver Not Accessible
**Symptom**: Cannot access web interface
**Solution**:
- Check pod status: `kubectl get pods -n database`
- Verify port forwarding: `kubectl port-forward -n database service/cloudbeaver-service 8978:8978`
- Check logs: `kubectl logs -n database -l app=cloudbeaver`

### Diagnostic Commands
```bash
# Check all database namespace resources
kubectl get all -n database

# Test service connectivity
kubectl run test-pod --rm -i --tty --image=busybox -- sh
# Inside pod:
# nslookup cloudbeaver-service.database.svc.cluster.local
# wget -qO- http://cloudbeaver-service.database.svc.cluster.local:8978

# Check ingress configuration (if configured)
kubectl get ingress -n database
```

## Security Considerations

### Development Environment
- Default passwords are used for simplicity
- No SSL/TLS encryption configured
- Basic authentication only

### Production Recommendations
- Use strong, unique passwords
- Enable SSL/TLS encryption
- Configure proper authentication (LDAP, SSO)
- Implement network policies
- Use persistent storage with proper backup strategies
- Regular security updates

## Integration with Development Workflow

### Use Cases
1. **Database Development**: Design and modify schemas
2. **Data Analysis**: Query and visualize data
3. **Debugging**: Inspect database state during development
4. **Testing**: Verify data integrity and query performance
5. **Documentation**: Generate ERDs and schema documentation

### Best Practices
- Use read-only connections for production databases
- Create separate users with limited privileges
- Regularly backup connection configurations
- Document custom queries and procedures
- Use version control for schema changes

## Alternatives

While CloudBeaver is our primary database management tool, alternatives include:
- **Database-specific tools**: pgAdmin (PostgreSQL), phpMyAdmin (MySQL)
- **Desktop applications**: DBeaver, DataGrip, TablePlus
- **Command-line tools**: psql, mysql client
- **Cloud solutions**: Database-specific cloud consoles

## Support and Documentation

### Official Resources
- [CloudBeaver Documentation](https://cloudbeaver.io/docs/)
- [GitHub Repository](https://github.com/dbeaver/cloudbeaver)
- [Community Forum](https://github.com/dbeaver/cloudbeaver/discussions)

### Internal Resources
- [Database Namespace Overview](../database-namespace.md)
- [PostgreSQL Documentation](../postgresql/README.md)
- [MySQL Documentation](../mysql/README.md)
- [Development Environment Setup](../getting-started/README.md)

## Changelog

### Recent Changes
- Replaced phpMyAdmin and pgAdmin with CloudBeaver
- Configured for both PostgreSQL and MySQL access
- Deployed in database namespace for better organization
- Implemented emptyDir storage to resolve admin user conflicts
- Added comprehensive documentation and troubleshooting guides

---

**Note**: This documentation reflects the current development environment setup. For production deployments, additional security and performance considerations should be implemented.

### External Database Access

CloudBeaver provides a web-based interface for database management, but you can also connect directly to the databases from external tools:

- **📖 [Complete External Access Guide](../DATABASE_EXTERNAL_ACCESS.md)** - Comprehensive guide for external connections
- **Direct TCP Access**: MySQL (localhost:3306), PostgreSQL (requires additional setup)
- **Port Forwarding**: Alternative connection method for development
- **Client Tools**: DBeaver, DataGrip, TablePlus, and command-line clients

#### External PostgreSQL Access Setup

For PostgreSQL external access via `localhost:5432`, you need to configure K3d port mapping:

**Option 1: Port Forwarding (Immediate Solution)**
```bash
# Forward PostgreSQL port for external access
kubectl port-forward -n database svc/postgres 5432:5432 &

# Connect from external client
PGPASSWORD=1q2w3e4r@123 psql -h localhost -p 5432 -U admin -d devdb
```

**Option 2: K3d Port Mapping (Permanent Solution)**
```bash
# When recreating the K3d cluster, add PostgreSQL port mapping
k3d cluster delete k3s-dev
k3d cluster create k3s-dev \
  --port "80:80@loadbalancer" \
  --port "443:443@loadbalancer" \
  --port "3306:30306@loadbalancer" \
  --port "5432:30432@loadbalancer" \
  --port "8080:8080@loadbalancer"

# Then PostgreSQL will be accessible at localhost:5432
```

**Option 3: Alternative Port Mapping**
```bash
# If you don't want to recreate the cluster, use a different local port
kubectl port-forward -n database svc/postgres 15432:5432 &
PGPASSWORD=1q2w3e4r@123 psql -h localhost -p 15432 -U admin -d devdb
```

**Quick Test Script**
```bash
# Run the PostgreSQL external access test script
./scripts/test-postgres-external.sh
# This script will test connectivity and provide specific setup guidance
```

> **Quick External Connection Status**:
> - **MySQL**: ✅ `mysql -h localhost -P 3306 -u root -p45oV8arIokIAYgLqa9bQ`
> - **PostgreSQL**: ⚠️ Requires port forwarding: `kubectl port-forward -n database svc/postgres 5432:5432`