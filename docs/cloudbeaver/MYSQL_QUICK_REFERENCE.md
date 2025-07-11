# MySQL and CloudBeaver Quick Reference Guide

## Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `deploy-mysql-cloudbeaver.sh` | Deploy MySQL and CloudBeaver with dynamic credentials | `./scripts/deploy-mysql-cloudbeaver.sh` |
| `cleanup-mysql-cloudbeaver.sh` | Remove all MySQL and CloudBeaver resources | `./scripts/cleanup-mysql-cloudbeaver.sh` |
| `check-mysql-status.sh` | Troubleshoot MySQL issues | `./scripts/check-mysql-status.sh` |

## Connection Information

### MySQL
- **Service**: `mysql-service.database.svc.cluster.local:3306`
- **Database**: `porigins_db`
- **User**: `porigins`
- **Password**: *(Generated during deployment)*
- **Credentials File**: `~/.kube/database-credentials/mysql.txt`

### CloudBeaver
- **Service**: `cloudbeaver-service.database.svc.cluster.local:8978`
- **Local Access**: `http://localhost:8978` (after port-forwarding)
- **Admin User**: `admin`
- **Admin Password**: `adminpassword`

## Common Commands

### Port Forwarding
```bash
# Access CloudBeaver UI
kubectl port-forward -n database service/cloudbeaver-service 8978:8978

# Direct MySQL access (if needed)
kubectl port-forward -n database service/mysql-service 3306:3306
```

### Check Status
```bash
# MySQL pod status
kubectl get pods -n database -l app=mysql

# CloudBeaver pod status
kubectl get pods -n database -l app=cloudbeaver

# MySQL logs
kubectl logs -n database -l app=mysql --tail=50

# CloudBeaver logs
kubectl logs -n database -l app=cloudbeaver --tail=50
```

### MySQL Operations
```bash
# Connect to MySQL from inside the cluster
kubectl run mysql-shell --rm -it --restart=Never --namespace database --image=mysql:8.0 -- mysql -h mysql-service -u porigins -p

# Execute a SQL command
kubectl run mysql-client --rm -it --restart=Never --namespace database --image=mysql:8.0 -- mysql -h mysql-service -u porigins -p porigins_db -e "SHOW TABLES;"

# Import a SQL file
kubectl cp ./my-data.sql database/$(kubectl get pod -l app=mysql -n database -o jsonpath='{.items[0].metadata.name}'):/tmp/
kubectl exec -it -n database $(kubectl get pod -l app=mysql -n database -o jsonpath='{.items[0].metadata.name}') -- mysql -u porigins -p porigins_db < /tmp/my-data.sql
```

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| MySQL fails to start | Check logs with `kubectl logs -n database -l app=mysql` |
| CloudBeaver can't connect to MySQL | Verify MySQL service: `kubectl get svc -n database mysql-service` |
| Lost MySQL credentials | Check `~/.kube/database-credentials/mysql.txt` or reset with cleanup and redeploy |
| Need to reset CloudBeaver | Delete the pod: `kubectl delete pod -n database -l app=cloudbeaver` |
| Database schema issues | Use CloudBeaver SQL console to fix or run `./scripts/cleanup-mysql-cloudbeaver.sh` and redeploy |

## Notes

- The MySQL deployment uses dynamically generated credentials for better security
- CloudBeaver is configured automatically with these credentials
- For production use, consider enabling proper TLS and stronger authentication
- MySQL data is persisted in a PVC and survives pod restarts (but not PVC deletion)
