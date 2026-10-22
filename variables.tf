variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "Default GCP region for regional resources."
  type        = string
  default     = "europe-west2"
}

variable "network_name" {
  description = "Name of the VPC network (LO-Prod)."
  type        = string
  default     = "lo-prod"
}

variable "routing_mode" {
  description = "VPC routing mode."
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "routing_mode must be REGIONAL or GLOBAL."
  }
}

variable "subnets" {
  description = "Subnets to create in the VPC. Map key is the subnet name."
  type = map(object({
    cidr                     = string
    region                   = optional(string)
    description              = optional(string)
    private_ip_google_access = optional(bool)
  }))

  default = {
    lo-prod = {
      cidr        = "10.210.102.0/24"
      description = "Laptop Outlet (LO-Prod) production subnet in europe-west2"
    }
  }
}

variable "nat_static_ip_count" {
  description = "Static egress IPs to reserve for Cloud NAT. Set to 1 so the egress IP can be added to Cloud SQL authorized networks."
  type        = number
  default     = 1
}

variable "instance_allow_private_ssh" {
  description = "Allow SSH from instance_ssh_source_ranges to private instances."
  type        = bool
  default     = false
}

variable "instance_ssh_source_ranges" {
  description = "Source CIDR ranges allowed to SSH to private instances, typically VPN client or tunnel ranges."
  type        = list(string)
  default     = []
}

variable "instance_enable_os_login" {
  description = "Enable OS Login. Keep false when using metadata SSH keys."
  type        = bool
  default     = false
}

variable "instance_ssh_username" {
  description = "Linux username created from the metadata SSH key."
  type        = string
  default     = "adan"
}

variable "instance_ssh_public_key" {
  description = "Optional instance-level SSH key. Leave empty to rely solely on project-level metadata keys (Compute Engine > Metadata > SSH Keys)."
  type        = string
  sensitive   = true
  default     = ""
}

variable "instance_network_tag" {
  description = "Shared network tag used for private VM firewall rules."
  type        = string
  default     = "lo-prod-private-vm"
}

variable "instance_enable_secure_boot" {
  description = "Enable Shielded VM secure boot. Keep false for cloned/custom images (matches the source VMs, which run with it off)."
  type        = bool
  default     = false
}

variable "instance_image_project" {
  description = "GCP project that publishes the Ubuntu image."
  type        = string
  default     = "ubuntu-os-cloud"
}

variable "instance_image_family" {
  description = "Ubuntu image family."
  type        = string
  default     = "ubuntu-2604-lts-amd64"
}

variable "instances" {
  description = "Standalone private compute instances to create. Map key is the instance name."
  type = map(object({
    zone                  = optional(string)
    subnet_name           = optional(string)
    machine_type          = string
    boot_disk_size_gb     = number
    boot_disk_type        = optional(string)
    image_project         = optional(string)
    image_family          = optional(string)
    image_name            = optional(string)
    internal_ip           = optional(string)
    attached_disk_names   = optional(list(string), [])
    additional_tags       = optional(list(string))
    labels                = optional(map(string))
    startup_script_path   = optional(string)
    enable_os_login       = optional(bool)
    ssh_username          = optional(string)
    ssh_public_key        = optional(string)
    service_account_email = optional(string)
  }))
  default = {}
}

variable "migs" {
  description = "Managed instance groups (each gets its own instance template). Map key is the MIG name."
  type = map(object({
    subnet_name           = optional(string)
    machine_type          = string
    target_size           = optional(number, 2)
    boot_disk_size_gb     = optional(number, 30)
    boot_disk_type        = optional(string)
    image_project         = optional(string)
    image_family          = optional(string)
    image_name            = optional(string)
    serving_port          = optional(number, 80)
    health_check_path     = optional(string, "/")
    health_check_protocol = optional(string, "HTTP")
    health_check_host     = optional(string)
    autoscaling_enabled   = optional(bool, false)
    autoscaling_min       = optional(number, 2)
    autoscaling_max       = optional(number, 4)
    additional_tags       = optional(list(string))
    labels                = optional(map(string))
    startup_script_path   = optional(string)
    service_account_email = optional(string)
  }))
  default = {}
}

variable "enable_load_balancer" {
  description = "Create the single external HTTPS load balancer in front of all apps."
  type        = bool
  default     = false
}

variable "lb_default_backend" {
  description = "Backend key (from var.lb_backends) that serves traffic not matched by any host rule."
  type        = string
  default     = null
}

variable "lb_ssl_domains" {
  description = "Domains for the LB's Google-managed SSL certificate (all hostnames served by the LB)."
  type        = list(string)
  default     = []
}

variable "lb_backends" {
  description = <<-EOT
    Backends behind the single LB. Map key is the backend name.
      source = "mig" -> key must match a var.migs entry (uses that MIG's instance group)
      source = "vm"  -> set instance = a var.instances key (wrapped in an unmanaged instance group)
      protocol = HTTP | HTTPS (how the LB talks to the backend)
  EOT
  type = map(object({
    source                = string
    instance              = optional(string)
    protocol              = optional(string, "HTTP")
    port                  = number
    health_check_path     = optional(string, "/")
    health_check_protocol = optional(string)
    health_check_host     = optional(string)
    timeout_sec           = optional(number, 30)
  }))
  default = {}
}

variable "lb_routing" {
  description = "Host-based routing. Each entry maps hostnames to a default backend plus optional path rules."
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
