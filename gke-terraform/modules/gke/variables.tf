variable "project_id" {
  type = string
}

variable "region" {
  description = "Region for a regional (multi-zone) cluster. Use a zone here instead for a cheaper zonal cluster."
  type        = string
}

variable "cluster_name" {
  type = string
}

variable "network_id" {
  description = "Self link/ID of the VPC network (from the vpc module)."
  type        = string
}

variable "subnet_id" {
  description = "Self link/ID of the GKE subnet (from the vpc module)."
  type        = string
}

variable "pods_range_name" {
  type = string
}

variable "services_range_name" {
  type = string
}

variable "master_ipv4_cidr_block" {
  description = "A /28 CIDR block for the GKE control plane (must not overlap any other range in the VPC)."
  type        = string
}

variable "master_authorized_networks" {
  description = "CIDR ranges allowed to reach the Kubernetes API server (e.g. your office/VPN, or a bastion/CI range)."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "enable_private_endpoint" {
  description = "If true, the cluster's control plane is only reachable from inside the VPC (no public endpoint at all). If false, the endpoint is public but still gated by master_authorized_networks."
  type        = bool
  default     = false
}

variable "release_channel" {
  description = "GKE release channel: RAPID, REGULAR, or STABLE."
  type        = string
  default     = "REGULAR"
}

variable "deletion_protection" {
  description = "Prevent `terraform destroy` from deleting the cluster. Should be true for prod."
  type        = bool
  default     = true
}
