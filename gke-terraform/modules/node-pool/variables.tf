variable "project_id" {
  type = string
}

variable "location" {
  description = "Must match the cluster's location (region or zone)."
  type        = string
}

variable "cluster_name" {
  type = string
}

variable "pool_name" {
  type = string
}

variable "machine_type" {
  type    = string
  default = "e2-standard-4"
}

variable "disk_size_gb" {
  type    = number
  default = 100
}

variable "disk_type" {
  type    = string
  default = "pd-balanced"
}

variable "min_count" {
  description = "Minimum nodes PER ZONE."
  type        = number
  default     = 1
}

variable "max_count" {
  description = "Maximum nodes PER ZONE."
  type        = number
  default     = 3
}

variable "spot" {
  description = "Use Spot VMs for this pool (cheaper, can be preempted — good for stateless/batch workloads)."
  type        = bool
  default     = false
}

variable "service_account_email" {
  description = "Node service account (from the gke module's node_service_account_email output)."
  type        = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "network_tags" {
  type    = list(string)
  default = []
}

variable "taints" {
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}
