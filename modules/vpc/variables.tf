variable "name" {
  description = "VPC network name."
  type        = string
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

variable "description" {
  description = "Optional description for the VPC."
  type        = string
  default     = "Laptop Outlet production VPC managed by Terraform."
}

variable "region" {
  description = "Default region for subnets that do not specify one."
  type        = string
}

variable "subnets" {
  description = "Subnets to create in this VPC. Map key is the subnet name."
  type = map(object({
    cidr                     = string
    region                   = optional(string)
    description              = optional(string)
    private_ip_google_access = optional(bool)
  }))
}

variable "private_ip_google_access" {
  description = "Default Private Google Access setting for subnets."
  type        = bool
  default     = true
}
