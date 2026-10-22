variable "name" {
  description = "Compute instance name."
  type        = string
}

variable "zone" {
  description = "Zone for the instance."
  type        = string
}

variable "machine_type" {
  description = "GCE machine type."
  type        = string
  default     = "e2-standard-4"
}

variable "region" {
  description = "Region for the static external IP. Required when static_ip_name is set."
  type        = string
  default     = null
}

variable "subnetwork" {
  description = "Subnet self link."
  type        = string
}

variable "static_ip_name" {
  description = "Optional name for a reserved regional static external IP."
  type        = string
  default     = null
}

variable "boot_disk_image" {
  description = "Boot disk source image self link. Use image_family when null."
  type        = string
  default     = null
}

variable "image_project" {
  description = "GCP project for the image family lookup."
  type        = string
  default     = "rocky-linux-cloud"
}

variable "image_family" {
  description = "Image family used when boot_disk_image is null."
  type        = string
  default     = "rocky-linux-10-optimized-gcp"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 100
}

variable "boot_disk_type" {
  description = "Boot disk type."
  type        = string
  default     = "pd-balanced"
}

variable "nat_ip" {
  description = "External IP address to attach. Ignored when static_ip_name is set."
  type        = string
  default     = null
}

variable "network_tags" {
  description = "Network tags for firewall rules."
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}

variable "enable_os_login" {
  description = "Use OS Login for SSH. Disable when using metadata SSH keys or workforce identities without POSIX mapping."
  type        = bool
  default     = false
}

variable "ssh_public_keys" {
  description = "SSH public keys for metadata-based login. Map of username to public key."
  type        = map(string)
  default     = {}
}

variable "startup_script" {
  description = "Metadata startup script."
  type        = string
  default     = null
}

variable "service_account_email" {
  description = "Optional service account email."
  type        = string
  default     = null
}

variable "enable_secure_boot" {
  description = "Enable Shielded VM secure boot. Set false for cloned/custom images that lack a signed bootloader."
  type        = bool
  default     = true
}

variable "internal_ip" {
  description = "Static internal IP address. If null, GCP assigns one dynamically."
  type        = string
  default     = null
}

variable "attached_disks" {
  description = "Additional data disks to attach. List of objects with source (self_link) and optional device_name."
  type = list(object({
    source      = string
    device_name = optional(string)
    mode        = optional(string, "READ_WRITE")
  }))
  default = []
}
