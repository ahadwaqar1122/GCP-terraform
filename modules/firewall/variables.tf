variable "network_name" {
  description = "VPC network name that firewall rules attach to."
  type        = string
}

variable "target_tags" {
  description = "Network tags that SSH firewall rules apply to."
  type        = list(string)
}

variable "enable_iap_ssh" {
  description = "Create a firewall rule allowing SSH from Identity-Aware Proxy."
  type        = bool
  default     = true
}

variable "enable_public_ssh" {
  description = "Create a firewall rule allowing SSH from trusted source ranges."
  type        = bool
  default     = true
}

variable "ssh_source_ranges" {
  description = "Source CIDR ranges allowed to SSH via the public rule."
  type        = list(string)
  default     = []
}

variable "enable_lb_health_check" {
  description = "Create a firewall rule allowing GFE/health-check ranges to reach backends."
  type        = bool
  default     = false
}

variable "lb_serving_ports" {
  description = "TCP ports the load balancer and health checks reach on backends."
  type        = list(string)
  default     = ["80"]
}
