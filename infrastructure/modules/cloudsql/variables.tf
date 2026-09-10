variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "db_version" {
  type = string
}

variable "db_tier" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
  sensitive = true
}
