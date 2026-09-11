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

resource "google_compute_global_address" "private_service_range" {
  name          = "${var.network_name}-private-services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
  project       = var.gcp_project
}

resource "google_service_networking_connection" "private_services" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range.name]
}

output "network_self_link" {
  value = google_compute_network.vpc_network.self_link
}

output "subnetwork_self_link" {
  value = google_compute_subnetwork.subnet.self_link
}
