#!/bin/bash

# This script deploys CloudBeaver to the database namespace
# CloudBeaver will be configured to connect to PostgreSQL and optionally to MySQL if it exists

# Create the database namespace if it doesn't exist
kubectl create namespace database --dry-run=client -o yaml | kubectl apply -f -

# Check if MySQL credentials exist
MYSQL_CREDENTIALS_FILE="$HOME/.kube/database-credentials/mysql.txt"

if [ -f "$MYSQL_CREDENTIALS_FILE" ]; then
    echo "MySQL credentials found - will be available for manual connection in CloudBeaver UI"
    MYSQL_DATABASE=$(grep "Database:" "$MYSQL_CREDENTIALS_FILE" | awk '{print $2}')
    MYSQL_USER=$(grep "User:" "$MYSQL_CREDENTIALS_FILE" | awk '{print $2}')
    MYSQL_PASSWORD=$(grep "Password:" "$MYSQL_CREDENTIALS_FILE" | awk '{print $2}')
    echo "  Database: $MYSQL_DATABASE"
    echo "  User: $MYSQL_USER"
    echo "  Host: mysql-service.database.svc.cluster.local:3306"
else
    echo "No MySQL credentials found - only PostgreSQL will be available"
fi

echo "Creating CloudBeaver deployment..."

# Create CloudBeaver Deployment with clean workspace
kubectl apply -f - << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudbeaver
  namespace: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cloudbeaver
  template:
    metadata:
      labels:
        app: cloudbeaver
    spec:
      containers:
      - name: cloudbeaver
        image: dbeaver/cloudbeaver:latest
        ports:
        - containerPort: 8978
          name: http
        env:
        - name: CLOUDBEAVER_CB_SERVER_NAME
          value: "CloudBeaver Database Manager"
        volumeMounts:
        - name: cloudbeaver-workspace
          mountPath: /opt/cloudbeaver/workspace
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /status
            port: 8978
          initialDelaySeconds: 90
          periodSeconds: 30
          timeoutSeconds: 10
        readinessProbe:
          httpGet:
            path: /status
            port: 8978
          initialDelaySeconds: 60
          periodSeconds: 10
          timeoutSeconds: 5
      volumes:
      - name: cloudbeaver-workspace
        emptyDir: {}
EOF

echo "CloudBeaver deployment created"

# Create CloudBeaver Service
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: cloudbeaver-service
  namespace: database
spec:
  selector:
    app: cloudbeaver
  ports:
  - name: http
    port: 8978
    targetPort: 8978
  type: ClusterIP
EOF

echo "CloudBeaver service created"

# Create CloudBeaver HTTP Ingress
kubectl apply -f - << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: cloudbeaver-ingress
  namespace: database
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  rules:
  - host: database.localhost
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: cloudbeaver-service
            port:
              number: 8978
EOF

echo "CloudBeaver HTTP ingress created"

# Wait for deployment to be ready
echo "Waiting for CloudBeaver deployment..."
kubectl -n database wait --for=condition=Available deployment/cloudbeaver --timeout=120s

if [ $? -eq 0 ]; then
    echo "✅ CloudBeaver deployment successful!"
else
    echo "⚠️  CloudBeaver deployment may not be fully ready yet. Check status with:"
    echo "   kubectl get pods -n database"
fi

# Show CloudBeaver service
echo ""
echo "CloudBeaver Service Status:"
kubectl get service cloudbeaver-service -n database

# Access instructions
echo ""
echo "🌐 ACCESS CLOUDBEAVER:"
echo "================================"
echo "Direct URL: http://database.localhost"
echo ""
echo "Note: Make sure your /etc/hosts file includes:"
echo "127.0.0.1 database.localhost"
echo ""
echo "Alternative - Port Forward:"
echo "  kubectl port-forward -n database service/cloudbeaver-service 8978:8978"
echo "  Then open: http://localhost:8978"
echo ""
echo "📋 INITIAL SETUP:"
echo "================================"
echo "1. Open CloudBeaver in your browser"
echo "2. Complete the initial setup wizard"
echo "3. Create an admin user when prompted"
echo ""

if [ -f "$MYSQL_CREDENTIALS_FILE" ]; then
    echo "🔗 MYSQL CONNECTION:"
    echo "================================"
    echo "In CloudBeaver, create a new MySQL connection with:"
    echo "   Host: mysql-service.database.svc.cluster.local"
    echo "   Port: 3306"
    echo "   Database: $MYSQL_DATABASE"
    echo "   User: $MYSQL_USER"
    echo "   Password: $MYSQL_PASSWORD"
    echo ""
    echo "💡 Use './scripts/cloudbeaver/configure-cloudbeaver-connections.sh' for detailed setup help"
    echo ""
fi

echo "🐘 POSTGRESQL CONNECTION:"
echo "================================"
echo "In CloudBeaver, create a new PostgreSQL connection with:"
echo "   Host: postgres-service.database.svc.cluster.local"
echo "   Port: 5432"
echo "   Database: postgres"
echo "   User: postgres"
echo "   Password: postgres123"
echo ""
echo "💡 Use './scripts/cloudbeaver/configure-cloudbeaver-connections.sh' for detailed setup help"
echo ""
echo "🎉 CloudBeaver is ready at http://database.localhost!"
echo "🔧 Run './scripts/cloudbeaver/configure-cloudbeaver-connections.sh' for connection setup help"
