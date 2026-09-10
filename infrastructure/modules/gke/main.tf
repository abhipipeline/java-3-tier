resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.gcp_zone
  project  = var.gcp_project

  network    = var.network
  subnetwork = var.subnetwork

  remove_default_node_pool = false
  initial_node_count       = var.node_count

  node_config {
    machine_type = var.machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  ip_allocation_policy {}
}

output "endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "name" {
  value = google_container_cluster.primary.name
}
