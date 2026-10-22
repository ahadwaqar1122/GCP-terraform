variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "GCP region for the subnet, router and NAT."
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network."
  type        = string
}

variable "subnet_name" {
  description = "Name of the GKE subnet."
  type        = string
}

variable "subnet_cidr" {
  description = "Primary CIDR range for the GKE subnet (node IPs)."
  type        = string
}

variable "pods_range_name" {
  description = "Name of the secondary range used for Pod IPs."
  type        = string
}

variable "pods_cidr" {
  description = "CIDR range for Pod IPs (secondary range)."
  type        = string
}

variable "services_range_name" {
  description = "Name of the secondary range used for Service IPs."
  type        = string
}

variable "services_cidr" {
  description = "CIDR range for Service IPs (secondary range)."
  type        = string
}
