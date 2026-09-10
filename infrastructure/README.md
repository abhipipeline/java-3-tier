# Google Cloud Platform infrastructure for Java Application

This directory contains Terraform configurations to set up the GCP infrastructure for the Java application deployment. It replaces the previous AWS-focused configuration.

Architecture overview

- VPC (Custom mode) with subnetwork
- GKE cluster for application workloads
- Cloud SQL (MySQL) for persistent storage
- Terraform state stored in a GCS bucket

Prerequisites

1. GCP Project and permissions
   - Enable APIs: Cloud Resource Manager, Compute Engine, Kubernetes Engine, Cloud SQL Admin, Service Usage, and IAM
   - Create a service account for Terraform with permissions to manage the above resources and download its JSON key OR configure Workload Identity

2. Tools
   - Terraform >= 1.0.0
   - gcloud SDK

Usage

1. Initialize Terraform

```bash
terraform init
```

2. Create a terraform.tfvars file with at least:

```hcl
gcp_project    = "your-gcp-project"
gcp_region     = "us-central1"
gcp_zone       = "us-central1-a"
state_bucket   = "your-tfstate-bucket"
db_password    = "your-db-password"
```

3. Plan and apply

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

Notes

- Ensure the GCS bucket specified by `state_bucket` exists and Terraform service account has access to it.
