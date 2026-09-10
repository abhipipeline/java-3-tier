# GCP Cloud SQL Module

# Cloud SQL Instance
resource "google_sql_database_instance" "main" {
  name             = "${var.environment}-mysql-instance"
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    tier              = var.instance_tier
    availability_type = "REGIONAL"

    database_flags {
      name  = "character_set_server"
      value = "utf8mb4"
    }

    ip_configuration {
      require_ssl        = true
      private_network    = var.network_id
      enable_ipv4        = false
      ipv4_enabled       = false
      authorized_networks = []
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 30
        retention_unit   = "COUNT"
      }
    }

    maintenance_window {
      day          = 7  # Sunday
      hour         = 3
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled  = true
      query_plans_per_minute  = 5
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }
  }

  deletion_protection = true

  labels = {
    environment = var.environment
  }
}

# Cloud SQL Database
resource "google_sql_database" "main" {
  name     = var.database_name
  instance = google_sql_database_instance.main.name

  charset   = "utf8mb4"
  collation = "utf8mb4_unicode_ci"
}

# Cloud SQL User
resource "google_sql_user" "main" {
  name     = var.database_user
  instance = google_sql_database_instance.main.name
  password = var.database_password

  type = "BUILT_IN"
}

# Cloud SQL Backup
resource "google_sql_backup_run" "main" {
  instance = google_sql_database_instance.main.name

  depends_on = [google_sql_database_instance.main]
}
