# Application Load Balancer Module - GCP Migration

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Health Check
resource "google_compute_health_check" "main" {
  name        = "${var.environment}-health-check"
  description = "Health check for backend services"

  http_health_check {
    port               = var.health_check_port
    request_path       = var.health_check_path
    proxy_header       = "NONE"
    check_interval_sec = 30
    timeout_sec        = 5
    healthy_threshold  = 2
    unhealthy_threshold = 2
  }
}

# Instance Group (Unmanaged) for now - to be used with ASG
resource "google_compute_instance_group" "main" {
  name        = "${var.environment}-instance-group"
  description = "Instance group for load balancer"
  zone        = "us-central1-a"  # Update based on region/zone selection
}

# Backend Service
resource "google_compute_backend_service" "main" {
  name                  = "${var.environment}-backend-service"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  enable_cdn            = false
  connection_draining_timeout_sec = 300

  health_checks = [google_compute_health_check.main.id]

  backend {
    group           = google_compute_instance_group.main.id
    balancing_mode  = "RATE"
    max_rate_per_instance = 100
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# URL Map
resource "google_compute_url_map" "main" {
  name            = "${var.environment}-lb"
  default_service = google_compute_backend_service.main.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "default"
  }

  path_matcher {
    name            = "default"
    default_service = google_compute_backend_service.main.id
  }
}

# HTTP Proxy
resource "google_compute_target_http_proxy" "main" {
  name    = "${var.environment}-http-proxy"
  url_map = google_compute_url_map.main.id
}

# Global Forwarding Rule (for HTTP)
resource "google_compute_global_forwarding_rule" "main" {
  name                  = "${var.environment}-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.main.id
}

# Firewall Rule for Health Checks
resource "google_compute_firewall" "health_check" {
  name      = "${var.environment}-allow-health-check"
  network   = var.network
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = [var.health_check_port]
  }

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]

  target_tags = ["http-server"]
}

# Firewall Rule for Load Balancer Traffic
resource "google_compute_firewall" "lb" {
  name      = "${var.environment}-allow-lb"
  network   = var.network
  direction = "INGRESS"
  priority  = 1001

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]
}
