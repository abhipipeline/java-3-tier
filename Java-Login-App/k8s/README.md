# GKE deployment

Build and push the image from `Java-Login-App` using Artifact Registry:

```bash
gcloud services enable artifactregistry.googleapis.com cloudbuild.googleapis.com container.googleapis.com
gcloud artifacts repositories create java-login \
  --repository-format=docker \
  --location=us-central1
gcloud auth configure-docker us-central1-docker.pkg.dev
gcloud builds submit --tag us-central1-docker.pkg.dev/PROJECT_ID/java-login/java-login-app:latest .
```

Create the database secret. Do not commit the real password:

```bash
kubectl create secret generic java-login-db \
  --from-literal=username=DB_USERNAME \
  --from-literal=password=DB_PASSWORD
```

Replace `IMAGE_PLACEHOLDER` with `us-central1-docker.pkg.dev/PROJECT_ID/java-login/java-login-app:latest` and `CLOUD_SQL_PRIVATE_IP` with the Terraform output in `deployment.yaml`, then deploy:

```bash
kubectl apply -f deployment.yaml
kubectl get service java-login-app
```

Use the Cloud SQL private IP from Terraform:

```bash
terraform output -raw cloudsql_private_ip
```