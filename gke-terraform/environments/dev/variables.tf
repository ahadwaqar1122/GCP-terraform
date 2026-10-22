variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "subnet_cidr" {
  type    = string
  default = "10.10.0.0/20"
}

variable "pods_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "services_cidr" {
  type    = string
  default = "10.30.0.0/20"
}

variable "master_ipv4_cidr_block" {
  description = "A /28 that does not overlap subnet_cidr/pods_cidr/services_cidr."
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_networks" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "enable_private_endpoint" {
  type    = bool
  default = false # dev: keep the public (but IP-restricted) endpoint for easy kubectl access
}

variable "release_channel" {
  type    = string
  default = "REGULAR"
}

variable "deletion_protection" {
  type    = bool
  default = false # dev: allow easy teardown
}

variable "default_pool_machine_type" {
  type    = string
  default = "e2-standard-4"
}

variable "default_pool_min_count" {
  type    = number
  default = 1
}

variable "default_pool_max_count" {
  type    = number
  default = 3
}
