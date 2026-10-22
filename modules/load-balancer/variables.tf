variable "name" {
  description = "Base name for the load balancer resources."
  type        = string
}

variable "backends" {
  description = <<-EOT
    Backends keyed by name.
      source   = "mig" (group provided) or "vm" (unmanaged group created here)
      group    = instance group self link (mig backends)
      instance = instance self link (vm backends)
      zone     = zone of the instance (vm backends)
      protocol = HTTP or HTTPS (LB -> backend)
  EOT
  type = map(object({
    source                = string
    group                 = optional(string)
    instance              = optional(string)
    zone                  = optional(string)
    protocol              = optional(string, "HTTP")
    port                  = number
    port_name             = optional(string)
    health_check_path     = optional(string, "/")
    health_check_protocol = optional(string)
    health_check_host     = optional(string)
    timeout_sec           = optional(number, 30)
  }))
}

variable "default_backend" {
  description = "Backend key that serves traffic not matched by any host rule."
  type        = string
}

variable "routing" {
  description = "Host-based virtual hosts. Each maps hostnames to a default backend plus optional path rules."
  type = list(object({
    hosts           = list(string)
    default_backend = string
    path_rules = optional(list(object({
      paths   = list(string)
      backend = string
    })), [])
  }))
  default = []
}

variable "ssl_domains" {
  description = "Domains included in the Google-managed SSL certificate."
  type        = list(string)
}
