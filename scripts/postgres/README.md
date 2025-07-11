# PostgreSQL Scripts

This directory contains PostgreSQL-related management scripts.

## Current Status

PostgreSQL is deployed by default in the k3s development environment and is managed through the main infrastructure scripts.

## Available Operations

### Check Status
```bash
kubectl get pods -n database | grep postgres
kubectl logs -n database deployment/postgres
```

### Access PostgreSQL
- **Internal**: `postgres-service.database.svc.cluster.local:5432`
- **Database**: `postgres`
- **User**: `postgres`
- **Password**: `postgres123`

### Port Forward (if needed)
```bash
kubectl port-forward -n database service/postgres 5432:5432
```

## Future Scripts

Future PostgreSQL-specific scripts may include:
- `deploy-postgres.sh` - Independent PostgreSQL deployment
- `cleanup-postgres.sh` - Remove PostgreSQL resources
- `backup-postgres.sh` - Database backup operations
- `restore-postgres.sh` - Database restore operations

## Integration

PostgreSQL is automatically available for:
- CloudBeaver connections
- Application deployments
- Development databases

## Features

- ✅ PostgreSQL 13+ deployment
- ✅ Kubernetes service for internal access
- ✅ Persistent volume for data storage
- ✅ Default database and user configuration
