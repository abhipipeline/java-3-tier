terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  backend "gcs" {
    bucket = var.state_bucket
    prefix = "java-app/terraform.tfstate"
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
  zone    = var.gcp_zone
}

# Network
module "network" {
  source = "./modules/network"

  gcp_project = var.gcp_project
  gcp_region  = var.gcp_region
  environment = var.environment
  network_name = "${var.environment}-java-app-network"
}

# GKE Cluster
module "gke" {
  source = "./modules/gke"

  gcp_project = var.gcp_project
  gcp_region  = var.gcp_region
  gcp_zone    = var.gcp_zone
  cluster_name = "${var.environment}-java-app-cluster"
  network      = module.network.network_self_link
  subnetwork   = module.network.subnetwork_self_link

  node_count   = var.gke_node_count
  machine_type = var.gke_machine_type
}

# Cloud SQL (MySQL)
module "cloudsql" {
  source = "./modules/cloudsql"

  gcp_project = var.gcp_project
  gcp_region  = var.gcp_region

  instance_name = "${var.environment}-java-app-sql"
  db_version = var.db_version
  db_tier    = var.db_tier
  db_user    = var.db_username
  db_password = var.db_password
}

output "gke_endpoint" {
  value = module.gke.endpoint
}

output "cloudsql_connection_name" {
  value = module.cloudsql.connection_name
}
