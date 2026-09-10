# GCP Firewall Rules Module

# Firewall Rule - ALB (Load Balancer) - Allow inbound HTTP/HTTPS
resource "google_compute_firewall" "alb_http_https" {
  name      = "${var.environment}-alb-allow-http-https"
  network   = var.network_name
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.environment}-lb"]

  labels = {
    environment = var.environment
  }
}

# Firewall Rule - Application Layer - Allow from Load Balancer
resource "google_compute_firewall" "app_from_lb" {
  name      = "${var.environment}-app-allow-from-lb"
  network   = var.network_name
  direction = "INGRESS"
  priority  = 1001

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_tags = ["${var.environment}-lb"]
  target_tags = ["${var.environment}-app"]

  labels = {
    environment = var.environment
  }
}

# Firewall Rule - Application Layer - Allow SSH from Bastion
resource "google_compute_firewall" "app_ssh_from_bastion" {
  name      = "${var.environment}-app-allow-ssh-bastion"
  network   = var.network_name
  direction = "INGRESS"
  priority  = 1002

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags = ["${var.environment}-bastion"]
  target_tags = ["${var.environment}-app"]

  labels = {
    environment = var.environment
  }
}

# Firewall Rule - Database Layer - Allow from Application Layer
resource "google_compute_firewall" "db_from_app" {
  name      = "${var.environment}-db-allow-from-app"
  network   = var.network_name
  direction = "INGRESS"
  priority  = 1003

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_tags = ["${var.environment}-app"]
  target_tags = ["${var.environment}-db"]

  labels = {
    environment = var.environment
  }
}

# Firewall Rule - Bastion Host - Allow SSH from external
resource "google_compute_firewall" "bastion_external_ssh" {
  name      = "${var.environment}-bastion-allow-external-ssh"
  network   = var.network_name
  direction = "INGRESS"
  priority  = 1004

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_cidr_blocks
  target_tags   = ["${var.environment}-bastion"]

  labels = {
    environment = var.environment
  }
}

# Firewall Rule - Allow all outbound traffic
resource "google_compute_firewall" "allow_all_outbound" {
  name      = "${var.environment}-allow-all-outbound"
  network   = var.network_name
  direction = "EGRESS"
  priority  = 65534

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]

  labels = {
    environment = var.environment
  }
}

# Firewall Rule - Deny all inbound by default (implicit rule, but making it explicit)
resource "google_compute_firewall" "deny_all_inbound" {
  name      = "${var.environment}-deny-all-inbound"
  network   = var.network_name
  direction = "INGRESS"
  priority  = 65535

  deny {
    protocol = "all"
  }

  labels = {
    environment = var.environment
  }
}
