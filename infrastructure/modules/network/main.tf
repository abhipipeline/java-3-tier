resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
  project                 = var.gcp_project
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.network_name}-subnet"
  ip_cidr_range = "10.10.0.0/20"
  region        = var.gcp_region
  network       = google_compute_network.vpc_network.id
  project       = var.gcp_project
}

output "network_self_link" {
  value = google_compute_network.vpc_network.self_link
}

output "subnetwork_self_link" {
  value = google_compute_subnetwork.subnet.self_link
}
