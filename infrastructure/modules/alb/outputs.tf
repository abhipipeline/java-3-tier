output "load_balancer_ip" {
  description = "External IP address of the Load Balancer"
  value       = google_compute_global_forwarding_rule.main.ip_address
}

output "load_balancer_name" {
  description = "Name of the URL Map / Load Balancer"
  value       = google_compute_url_map.main.name
}

output "backend_service_id" {
  description = "ID of the Backend Service"
  value       = google_compute_backend_service.main.id
}

output "health_check_id" {
  description = "ID of the Health Check"
  value       = google_compute_health_check.main.id
}

output "instance_group_id" {
  description = "ID of the Instance Group"
  value       = google_compute_instance_group.main.id
}
