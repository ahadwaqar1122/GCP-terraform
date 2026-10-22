variable "name" {
  description = "Managed instance group name."
  type        = string
}

variable "region" {
  description = "Region for the regional MIG."
  type        = string
}

variable "base_instance_name" {
  description = "Base name for instances created by the MIG."
  type        = string
}

variable "instance_template" {
  description = "Self link of the instance template to use."
  type        = string
}

variable "target_size" {
  description = "Number of instances when autoscaling is disabled."
  type        = number
  default     = 2
}

variable "named_port_name" {
  description = "Named port name exposed to the load balancer."
  type        = string
  default     = "http"
}

variable "serving_port" {
  description = "Port the application serves on (named port + health check)."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP path used by the auto-healing health check."
  type        = string
  default     = "/"
}

variable "health_check_protocol" {
  description = "Protocol for the auto-heal health check (HTTP or HTTPS)."
  type        = string
  default     = "HTTP"
}

variable "health_check_host" {
  description = "Host header sent by the health check. Needed when the app returns non-200 for an unknown Host."
  type        = string
  default     = null
}

variable "autoheal_initial_delay_sec" {
  description = "Seconds to wait after instance creation before health checking."
  type        = number
  default     = 300
}

variable "autoscaling_enabled" {
  description = "Enable a regional autoscaler for this MIG."
  type        = bool
  default     = false
}

variable "autoscaling_min" {
  description = "Minimum replicas when autoscaling."
  type        = number
  default     = 2
}

variable "autoscaling_max" {
  description = "Maximum replicas when autoscaling."
  type        = number
  default     = 4
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization (0-1) for autoscaling."
  type        = number
  default     = 0.6
}
