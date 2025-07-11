#!/bin/bash

# This script deploys MySQL to the database namespace with dynamically generated credentials

# Generate secure passwords
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9!@#$%^&*()' | head -c 20)
MYSQL_PASSWORD=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9!@#$%^&*()' | head -c 16)
MYSQL_DATABASE="porigins_db"
MYSQL_USER="porigins"

# Create the database namespace if it doesn't exist
kubectl create namespace database --dry-run=client -o yaml | kubectl apply -f -

# Create MySQL secret with generated credentials
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
  namespace: database
  labels:
    app: mysql
type: Opaque
data:
  mysql-root-password: $(echo -n "$MYSQL_ROOT_PASSWORD" | base64)
  mysql-password: $(echo -n "$MYSQL_PASSWORD" | base64)
  mysql-database: $(echo -n "$MYSQL_DATABASE" | base64)
  mysql-user: $(echo -n "$MYSQL_USER" | base64)
EOF

echo "MySQL secret created with generated credentials"

# Create MySQL ConfigMap for initialization script
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-init-script
  namespace: database
data:
  init-mysql.sql: |
    -- MySQL initialization script
    
    -- Use the created database
    USE ${MYSQL_DATABASE};
    
    -- Create a sample table for testing
    CREATE TABLE IF NOT EXISTS sample_data (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    );
    
    -- Insert some sample data
    INSERT IGNORE INTO sample_data (name, email) VALUES 
        ('Admin User', 'admin@example.com'),
        ('Test User', 'test@example.com'),
        ('Developer', 'dev@example.com');
    
    -- Create an index for performance (MySQL-compatible syntax)
    -- First check if the index exists
    SET @exist := (SELECT COUNT(1) FROM INFORMATION_SCHEMA.STATISTICS 
                  WHERE table_schema = DATABASE() 
                  AND table_name = 'sample_data' 
                  AND index_name = 'idx_email');
    
    SET @sqlstmt := IF(@exist > 0, 'SELECT ''Index exists''', 
                     'CREATE INDEX idx_email ON sample_data(email)');
    
    PREPARE stmt FROM @sqlstmt;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    -- Grant privileges to the MySQL user
    GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
    FLUSH PRIVILEGES;
EOF

echo "MySQL init script created"

# Create MySQL PVC
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
  namespace: database
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: local-path
EOF

echo "MySQL PVC created"

# Create MySQL Deployment
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
          name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-root-password
        - name: MYSQL_DATABASE
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-database
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-user
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-password
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
        - name: mysql-init
          mountPath: /docker-entrypoint-initdb.d
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          exec:
            command:
            - mysqladmin
            - ping
            - -h
            - localhost
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          exec:
            command:
            - mysqladmin
            - ping
            - -h
            - localhost
          initialDelaySeconds: 5
          periodSeconds: 2
          timeoutSeconds: 1
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: mysql-pvc
      - name: mysql-init
        configMap:
          name: mysql-init-script
EOF

echo "MySQL deployment created"

# Create MySQL Service
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
  namespace: database
spec:
  selector:
    app: mysql
  ports:
  - name: mysql
    port: 3306
    targetPort: 3306
  type: ClusterIP
EOF

echo "MySQL service created"

# Create MySQL TCP Ingress
cat << EOF | kubectl apply -f -
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: mysql-tcp-ingress
  namespace: database
spec:
  entryPoints:
    - mysql-tcp
  routes:
  - match: HostSNI(\`*\`)
    services:
    - name: mysql-service
      port: 3306
EOF

echo "MySQL TCP ingress created"

# Wait for deployment to be ready
echo "Waiting for MySQL deployment..."
kubectl -n database wait --for=condition=Available deployment/mysql --timeout=120s || echo "MySQL deployment not yet ready, please check status"

# Show MySQL service
echo "MySQL Service:"
kubectl get service mysql-service -n database

# Show MySQL Secret
echo -e "\nMySQL Secret (human-readable):"
echo "Database: $MYSQL_DATABASE"
echo "User: $MYSQL_USER"
echo "Password: $MYSQL_PASSWORD"
echo "Root Password: $MYSQL_ROOT_PASSWORD"

# Save credentials to a local file for reference
mkdir -p ~/.kube/database-credentials
cat > ~/.kube/database-credentials/mysql.txt << EOF
# MySQL Credentials - Generated on $(date)
Database: $MYSQL_DATABASE
User: $MYSQL_USER
Password: $MYSQL_PASSWORD
Root Password: $MYSQL_ROOT_PASSWORD
Service: mysql-service.database.svc.cluster.local:3306
EOF

echo -e "\nCredentials saved to: ~/.kube/database-credentials/mysql.txt"

# Instructions
echo -e "\nMySQL deployment completed!"
echo "MySQL is available at mysql-service.database.svc.cluster.local:3306"
echo -e "\nTo connect to MySQL from outside the cluster:"
echo "kubectl port-forward -n database service/mysql-service 3306:3306"
echo -e "\nTo access MySQL shell:"
echo "kubectl run mysql-shell --rm -it --restart=Never --namespace database --image=mysql:8.0 -- mysql -h mysql-service -u $MYSQL_USER -p"
