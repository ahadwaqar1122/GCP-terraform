variable "name" {
  description = "Base name for the Cloud NAT and its router."
  type        = string
}

variable "region" {
  description = "Region for the router and NAT."
  type        = string
}

variable "network" {
  description = "VPC network ID or self link the router attaches to."
  type        = string
}

variable "static_ip_count" {
  description = "Number of static external IPs to reserve for NAT egress. 0 = ephemeral (AUTO_ONLY). Set >=1 to allowlist the egress IP in Cloud SQL authorized networks."
  type        = number
  default     = 0
}
