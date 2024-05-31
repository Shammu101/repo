To set up a SonarQube pod to use a PostgreSQL pod as its default database in a Kubernetes environment, you need to perform several steps:

Deploy PostgreSQL: Deploy a PostgreSQL pod along with its service. You can use a Helm chart or create the deployment and service YAML files manually.

Deploy SonarQube: Deploy the SonarQube pod and configure it to connect to the PostgreSQL database. This involves setting environment variables for the database connection.

Here's a step-by-step guide to achieve this:

Step 1: Deploy PostgreSQL
You can use a Helm chart to deploy PostgreSQL:

bash
Copy code
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install postgresql bitnami/postgresql --set postgresqlPassword=myPassword,postgresqlDatabase=sonarqube
Alternatively, you can create the PostgreSQL deployment and service manually. Here's an example YAML:

postgresql-deployment.yaml:

yaml
Copy code
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgresql
  labels:
    app: postgresql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      labels:
        app: postgresql
    spec:
      containers:
        - name: postgresql
          image: postgres:13
          env:
            - name: POSTGRES_DB
              value: sonarqube
            - name: POSTGRES_USER
              value: sonarqube
            - name: POSTGRES_PASSWORD
              value: myPassword
          ports:
            - containerPort: 5432
          volumeMounts:
            - mountPath: /var/lib/postgresql/data
              name: postgredb
      volumes:
        - name: postgredb
          persistentVolumeClaim:
            claimName: postgredb-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgresql
spec:
  type: ClusterIP
  ports:
    - port: 5432
  selector:
    app: postgresql
postgresql-pvc.yaml:

yaml
Copy code
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgredb-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
Apply these configurations:

bash
Copy code
kubectl apply -f postgresql-pvc.yaml
kubectl apply -f postgresql-deployment.yaml
Step 2: Deploy SonarQube
Create a SonarQube deployment and service with the necessary environment variables to connect to the PostgreSQL database.

sonarqube-deployment.yaml:

yaml
Copy code
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sonarqube
  labels:
    app: sonarqube
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sonarqube
  template:
    metadata:
      labels:
        app: sonarqube
    spec:
      containers:
        - name: sonarqube
          image: sonarqube:lts
          ports:
            - containerPort: 9000
          env:
            - name: SONAR_JDBC_URL
              value: jdbc:postgresql://postgresql:5432/sonarqube
            - name: SONAR_JDBC_USERNAME
              value: sonarqube
            - name: SONAR_JDBC_PASSWORD
              value: myPassword
          volumeMounts:
            - mountPath: /opt/sonarqube/data
              name: sonarqube-data
            - mountPath: /opt/sonarqube/extensions
              name: sonarqube-extensions
      volumes:
        - name: sonarqube-data
          persistentVolumeClaim:
            claimName: sonarqube-data-pvc
        - name: sonarqube-extensions
          persistentVolumeClaim:
            claimName: sonarqube-extensions-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: sonarqube
spec:
  type: ClusterIP
  ports:
    - port: 9000
  selector:
    app: sonarqube
sonarqube-pvc.yaml:

yaml
Copy code
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sonarqube-data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sonarqube-extensions-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
Apply these configurations:

bash
Copy code
kubectl apply -f sonarqube-pvc.yaml
kubectl apply -f sonarqube-deployment.yaml
Step 3: Verify the Deployment
Check the status of the pods to ensure they are running correctly:

bash
Copy code
kubectl get pods
You should see both the PostgreSQL and SonarQube pods running. You can also check the logs of the SonarQube pod to ensure it has successfully connected to the PostgreSQL database:

bash
Copy code
kubectl logs <sonarqube-pod-name>
Step 4: Access SonarQube
Once the SonarQube pod is running, you can access it using the service created. If you want to access it from outside the cluster, you may need to create an Ingress or use a LoadBalancer service type.

For a quick test, you can use port forwarding:

bash
Copy code
kubectl port-forward svc/sonarqube 9000:9000
Now, you can access SonarQube at http://localhost:9000 in your web browser.

By following these steps, you have set up SonarQube to use PostgreSQL as its default database in a Kubernetes environment.

