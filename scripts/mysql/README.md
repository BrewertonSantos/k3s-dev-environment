# MySQL Scripts

This directory contains all MySQL-related deployment and management scripts.

## Available Scripts

### `deploy-mysql.sh`
- Deploys MySQL 8.0 to the `database` namespace
- Generates dynamic credentials saved to `~/.kube/database-credentials/mysql.txt`
- Creates PVC, Secret, Service, and Deployment
- Sets up database initialization scripts

### `cleanup-mysql.sh`
- Completely removes MySQL deployment and all resources
- Removes PVC, secrets, services, and deployments
- Provides detailed feedback on cleanup progress

### `check-mysql-status.sh`
- Checks MySQL deployment status
- Shows pod logs and service information
- Displays current credentials if available

## Usage

### Direct execution:
```bash
./scripts/mysql/deploy-mysql.sh
./scripts/mysql/cleanup-mysql.sh
./scripts/mysql/check-mysql-status.sh
```

### Via main database script:
```bash
./scripts/database.sh mysql deploy
./scripts/database.sh mysql cleanup
./scripts/database.sh mysql status
```

## Connection Details

After deployment, MySQL is available at:
- **Internal**: `mysql-service.database.svc.cluster.local:3306`
- **Credentials**: Stored in `~/.kube/database-credentials/mysql.txt`
- **Database**: `porigins_db`
- **User**: `porigins`

## Features

- ✅ Dynamic password generation on each deployment
- ✅ Persistent volume for data storage
- ✅ Kubernetes service for internal access
- ✅ Proper initialization scripts
- ✅ MySQL 8.0 compatible configuration
