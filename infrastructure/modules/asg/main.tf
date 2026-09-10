# GCP Instance Group Module

# Instance Template
resource "google_compute_instance_template" "main" {
  name          = "${var.environment}-instance-template"
  machine_type  = var.instance_type
  region        = var.region
  can_ip_forward = false

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    network            = var.network_name
    subnetwork         = var.subnet_name
    network_ip         = ""
    access_config {
      nat_ip = ""
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    startup-script = base64encode(<<-EOF
                      #!/bin/bash
                      apt-get update
                      apt-get install -y default-jdk
                      apt-get install -y tomcat10
                      systemctl enable tomcat10
                      systemctl start tomcat10
                      EOF
    )
  }

  labels = {
    environment = var.environment
    name        = "${var.environment}-web-instance"
  }

  tags = [var.environment, "web"]

  lifecycle {
    create_before_destroy = true
  }
}

# Instance Group Manager (Managed Instance Group)
resource "google_compute_instance_group_manager" "main" {
  name               = "${var.environment}-instance-group-manager"
  base_instance_name = "${var.environment}-web"
  instance_template  = google_compute_instance_template.main.self_link
  zone               = var.zone

  target_size = var.desired_capacity

  named_port {
    name = "http"
    port = 8080
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.main.id
    initial_delay_sec = 300
  }
}

# Autoscaler
resource "google_compute_autoscaler" "main" {
  name       = "${var.environment}-autoscaler"
  zone       = var.zone
  target     = google_compute_instance_group_manager.main.id
  depends_on = [google_compute_instance_group_manager.main]

  autoscaling_policy {
    min_replicas    = var.min_size
    max_replicas    = var.max_size
    cooldown_period = 300

    cpu_utilization {
      target = 0.7
    }
  }
}

# Health Check
resource "google_compute_health_check" "main" {
  name        = "${var.environment}-health-check"
  description = "Health check for application servers"

  http_health_check {
    port         = 8080
    request_path = "/"
  }
}
