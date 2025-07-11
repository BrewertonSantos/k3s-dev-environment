# CloudBeaver Manifest

## Component Information

- **Name**: CloudBeaver
- **Version**: 23.3.1 (Latest stable as of July 2025)
- **Container Image**: dbeaver/cloudbeaver:latest
- **Repository**: https://github.com/dbeaver/cloudbeaver
- **Documentation**: https://cloudbeaver.io/docs/
- **License**: Apache License 2.0

## Dependencies

### Runtime Dependencies
- Kubernetes 1.22+
- Network access to database services
- Web browser with JavaScript enabled

### Database Connectivity
- PostgreSQL (Connection to postgres-service)
- MySQL (Connection to mysql-service)
- Support for other database types built-in

## Resources

### Compute Resources
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Storage
```yaml
# Current configuration
volumes:
- name: cloudbeaver-workspace
  emptyDir: {}

# Optional persistent storage
volumes:
- name: cloudbeaver-workspace
  persistentVolumeClaim:
    claimName: cloudbeaver-pvc
```

## Network

### Service
- **Type**: ClusterIP
- **Port**: 8978
- **Target Port**: 8978

### Ingress (Optional)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: cloudbeaver-ingress
  namespace: database
spec:
  rules:
  - host: cloudbeaver.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: cloudbeaver-service
            port:
              number: 8978
```

## Security

### Authentication
- Local user authentication
- Optional LDAP integration
- Optional SSO integration

### Authorization
- Role-based access control
- Connection-level permissions
- Object-level permissions

### Network Security
- No TLS in development environment
- Recommended to enable TLS for production

## Configuration

### Environment Variables
```yaml
env:
- name: CLOUDBEAVER_WORKSPACE
  value: "/opt/cloudbeaver/workspace"
- name: CLOUDBEAVER_WEB_CONFIG_PATH
  value: "/opt/cloudbeaver/conf"
```

### Custom Configuration
CloudBeaver can be configured via web UI or by modifying configuration files in the workspace directory.

## Maintenance

### Updates
- Pull latest image: `docker pull dbeaver/cloudbeaver:latest`
- Apply new deployment: `kubectl apply -f k8s-manifests/cloudbeaver.yaml`

### Backup
- Export connection configurations from UI
- Backup workspace directory if using persistent storage

## Health Monitoring

### Liveness Probe
```yaml
livenessProbe:
  httpGet:
    path: /
    port: 8978
  initialDelaySeconds: 60
  periodSeconds: 10
```

### Readiness Probe
```yaml
readinessProbe:
  httpGet:
    path: /
    port: 8978
  initialDelaySeconds: 30
  periodSeconds: 10
```

## Integration Points

- Direct access to PostgreSQL and MySQL services
- Can be integrated with CI/CD pipelines for database migrations
- Supports exporting data for use in applications

---

This manifest provides essential information about the CloudBeaver deployment in the k3s development environment.