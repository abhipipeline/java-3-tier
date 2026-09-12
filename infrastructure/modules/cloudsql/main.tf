resource "google_sql_database_instance" "db_instance" {
  name                = var.instance_name
  project             = var.gcp_project
  region              = var.gcp_region
  deletion_protection = false

  database_version = var.db_version

  settings {
    tier = var.db_tier
    ip_configuration {
      ipv4_enabled = false
      private_network = var.network
    }
  }
}

resource "google_sql_user" "users" {
  name     = var.db_user
  instance = google_sql_database_instance.db_instance.name
  password = var.db_password
}

resource "google_sql_database" "database" {
  name     = var.db_name
  instance = google_sql_database_instance.db_instance.name
}

output "connection_name" {
  value = google_sql_database_instance.db_instance.connection_name
}

output "private_ip" {
  value = google_sql_database_instance.db_instance.private_ip_address
}
