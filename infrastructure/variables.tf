variable "gcp_project" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Deployment environment (dev/prod)"
  type        = string
  default     = "dev"
}

# GKE
variable "gke_node_count" {
  type    = number
  default = 2
}

variable "gke_machine_type" {
  type    = string
  default = "e2-medium"
}

# Cloud SQL
variable "db_version" {
  type    = string
  default = "MYSQL_8_0"
}

variable "db_tier" {
  type    = string
  default = "db-f1-micro"
}

variable "db_username" {
  type    = string
  default = "dbuser"
}

variable "db_password" {
  type    = string
  sensitive = true
}
