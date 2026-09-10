# Load Balancer Module - GCP

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "network" {
  description = "Network name for firewall rules"
  type        = string
}

variable "public_subnet_names" {
  description = "List of public subnet names"
  type        = list(string)
}

variable "health_check_port" {
  description = "Port for health checks"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/"
}
