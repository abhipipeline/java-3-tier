resource "google_sql_database_instance" "db_instance" {
  name             = var.instance_name
  project          = var.gcp_project
  region           = var.gcp_region

  database_version = var.db_version

  settings {
    tier = var.db_tier
    ip_configuration {
      ipv4_enabled = false
    }
  }
}

resource "google_sql_user" "users" {
  name     = var.db_user
  instance = google_sql_database_instance.db_instance.name
  password = var.db_password
}

output "connection_name" {
  value = google_sql_database_instance.db_instance.connection_name
}
