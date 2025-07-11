# CloudBeaver Scripts

This directory contains all CloudBeaver-related deployment and management scripts.

## Available Scripts

### `deploy-cloudbeaver.sh`
- Deploys CloudBeaver to the `database` namespace
- Configures ingress for access at `http://database.localhost`
- Automatically detects MySQL credentials for connection setup
- Creates clean workspace to avoid configuration conflicts

### `cleanup-cloudbeaver.sh`
- Completely removes CloudBeaver deployment and all resources
- Removes deployment, services, ingress, and configmaps
- Provides detailed feedback on cleanup progress
- Preserves other database services (MySQL, PostgreSQL)

### `configure-cloudbeaver-connections.sh`
- Helper script for database connection configuration
- Displays exact connection details for copy-paste into CloudBeaver UI
- Shows both MySQL and PostgreSQL connection settings
- Provides step-by-step setup instructions

### `deploy-mysql-cloudbeaver.sh` (Legacy)
- Combined MySQL + CloudBeaver deployment
- Use separate scripts instead: `../mysql/deploy-mysql.sh` then `deploy-cloudbeaver.sh`

### `cleanup-mysql-cloudbeaver.sh` (Legacy)
- Combined cleanup script
- Use separate scripts instead for better control

## Usage

### Direct execution:
```bash
./scripts/cloudbeaver/deploy-cloudbeaver.sh
./scripts/cloudbeaver/cleanup-cloudbeaver.sh
./scripts/cloudbeaver/configure-cloudbeaver-connections.sh
```

### Via main database script:
```bash
./scripts/database.sh cloudbeaver deploy
./scripts/database.sh cloudbeaver cleanup
./scripts/database.sh cloudbeaver configure
```

## Access Methods

### Primary Access (No Port Forwarding)
- **URL**: `http://database.localhost`
- **Requirements**: Entry in `/etc/hosts`: `127.0.0.1 database.localhost`

### Alternative Access (Port Forward)
```bash
kubectl port-forward -n database service/cloudbeaver-service 8978:8978
# Then open: http://localhost:8978
```

## Database Connections

### MySQL Connection (if deployed)
- **Host**: `mysql-service.database.svc.cluster.local`
- **Port**: `3306`
- **Database**: Retrieved from credentials file
- **User**: Retrieved from credentials file
- **Password**: Retrieved from credentials file

### PostgreSQL Connection
- **Host**: `postgres-service.database.svc.cluster.local`
- **Port**: `5432`
- **Database**: `postgres`
- **User**: `postgres`
- **Password**: `postgres123`

## Features

- ✅ Web-based database management interface
- ✅ Direct URL access without port forwarding
- ✅ Automatic MySQL credential detection
- ✅ Clean workspace deployment (avoids GraphQL errors)
- ✅ Support for multiple database types
- ✅ Kubernetes-native deployment
