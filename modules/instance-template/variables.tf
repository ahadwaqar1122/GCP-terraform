variable "name_prefix" {
  description = "Prefix for the instance template name."
  type        = string
}

variable "machine_type" {
  description = "GCE machine type."
  type        = string
  default     = "e2-standard-4"
}

variable "region" {
  description = "Region for the regional instance template."
  type        = string
}

variable "subnetwork" {
  description = "Subnet self link."
  type        = string
}

variable "boot_disk_image" {
  description = "Boot disk source image self link. Use image_family when null."
  type        = string
  default     = null
}

variable "image_project" {
  description = "GCP project for the image family lookup."
  type        = string
  default     = "ubuntu-os-cloud"
}

variable "image_family" {
  description = "Image family used when boot_disk_image is null."
  type        = string
  default     = "ubuntu-2604-lts-amd64"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 30
}

variable "boot_disk_type" {
  description = "Boot disk type."
  type        = string
  default     = "pd-ssd"
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
  description = "Use OS Login for SSH. Disable when using metadata SSH keys."
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
