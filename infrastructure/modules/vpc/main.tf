# VPC Module - GCP Migration

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

# VPC Network
resource "google_compute_network" "main" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false

  depends_on = []
}

# Public Subnets
resource "google_compute_subnetwork" "public" {
  count             = length(var.public_subnets)
  name              = "${var.environment}-public-subnet-${count.index + 1}"
  ip_cidr_range     = var.public_subnets[count.index]
  region            = var.region
  network           = google_compute_network.main.id
  purpose           = "PRIVATE"
  private_ip_google_access = false

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
  }
}

# Private Subnets
resource "google_compute_subnetwork" "private" {
  count             = length(var.private_subnets)
  name              = "${var.environment}-private-subnet-${count.index + 1}"
  ip_cidr_range     = var.private_subnets[count.index]
  region            = var.region
  network           = google_compute_network.main.id
  purpose           = "PRIVATE"
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
  }
}

# Cloud Router for NAT
resource "google_compute_router" "main" {
  name    = "${var.environment}-router"
  region  = var.region
  network = google_compute_network.main.id

  bgp {
    asn = 64514
  }
}

# Cloud NAT Gateway
resource "google_compute_router_nat" "main" {
  name                               = "${var.environment}-nat"
  router                             = google_compute_router.main.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall - Allow internal traffic
resource "google_compute_firewall" "allow_internal" {
  name      = "${var.environment}-allow-internal"
  network   = google_compute_network.main.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = concat(var.public_subnets, var.private_subnets)
}

# Firewall - Allow SSH from anywhere (adjust as needed)
resource "google_compute_firewall" "allow_ssh" {
  name      = "${var.environment}-allow-ssh"
  network   = google_compute_network.main.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# VPC Flow Logs
resource "google_logging_project_sink" "vpc_flow_logs" {
  name        = "${var.environment}-vpc-flow-logs"
  destination = "logging.googleapis.com/projects/${var.project_id}/logs/vpc-flow-logs"

  filter = "resource.type=\"gce_subnetwork\" OR resource.type=\"gce_network\""

  unique_writer_identity = true
}
