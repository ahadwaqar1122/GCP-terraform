variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "subnet_cidr" {
  type    = string
  default = "10.11.0.0/20"
}

variable "pods_cidr" {
  type    = string
  default = "10.21.0.0/16"
}

variable "services_cidr" {
  type    = string
  default = "10.31.0.0/20"
}

variable "master_ipv4_cidr_block" {
  type    = string
  default = "172.16.0.16/28"
}

variable "master_authorized_networks" {
  description = "Required in prod — do not leave empty. Should be your VPN/bastion/CI ranges only."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
}

variable "enable_private_endpoint" {
  type    = bool
  default = true # prod: no public endpoint at all — access via VPN/bastion/CI runner inside the VPC
}

variable "release_channel" {
  type    = string
  default = "STABLE"
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "default_pool_machine_type" {
  type    = string
  default = "e2-standard-4"
}

variable "default_pool_min_count" {
  type    = number
  default = 2
}

variable "default_pool_max_count" {
  type    = number
  default = 6
}
