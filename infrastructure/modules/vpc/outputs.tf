output "vpc_id" {
  description = "ID of the VPC Network"
  value       = google_compute_network.main.id
}

output "vpc_name" {
  description = "Name of the VPC Network"
  value       = google_compute_network.main.name
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = google_compute_subnetwork.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = google_compute_subnetwork.private[*].id
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = google_compute_subnetwork.public[*].ip_cidr_range
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = google_compute_subnetwork.private[*].ip_cidr_range
}

output "internet_gateway_id" {
  description = "Cloud Router ID (GCP equivalent)"
  value       = google_compute_router.main.id
}

output "public_route_table_ids" {
  description = "Public subnets (GCP uses subnetworks)"
  value       = google_compute_subnetwork.public[*].id
}

output "private_route_table_ids" {
  description = "Private subnets (GCP uses subnetworks)"
  value       = google_compute_subnetwork.private[*].id
}

output "nat_gateway_ids" {
  description = "Cloud NAT ID"
  value       = [google_compute_router_nat.main.name]
}

output "nat_gateway_elastic_ips" {
  description = "Cloud NAT auto-allocates IPs internally"
  value       = ["Auto-allocated by Cloud NAT"]
}

output "vpc_cidr_block" {
  description = "CIDR blocks of the VPC"
  value       = concat(var.public_subnets, var.private_subnets)
}
