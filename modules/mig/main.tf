resource "google_compute_health_check" "autoheal" {
  name                = "${var.name}-autoheal-hc"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  dynamic "http_health_check" {
    for_each = var.health_check_protocol == "HTTP" ? [1] : []
    content {
      port         = var.serving_port
      request_path = var.health_check_path
      host         = var.health_check_host
    }
  }

  dynamic "https_health_check" {
    for_each = var.health_check_protocol == "HTTPS" ? [1] : []
    content {
      port         = var.serving_port
      request_path = var.health_check_path
      host         = var.health_check_host
    }
  }
}

resource "google_compute_region_instance_group_manager" "this" {
  name               = var.name
  region             = var.region
  base_instance_name = var.base_instance_name

  version {
    instance_template = var.instance_template
  }

  named_port {
    name = var.named_port_name
    port = var.serving_port
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autoheal.id
    initial_delay_sec = var.autoheal_initial_delay_sec
  }

  # target_size is ignored when an autoscaler manages this MIG.
  target_size = var.autoscaling_enabled ? null : var.target_size

  lifecycle {
    ignore_changes = [target_size]
  }
}

resource "google_compute_region_autoscaler" "this" {
  count = var.autoscaling_enabled ? 1 : 0

  name   = "${var.name}-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.this.id

  autoscaling_policy {
    min_replicas    = var.autoscaling_min
    max_replicas    = var.autoscaling_max
    cooldown_period = 60

    cpu_utilization {
      target = var.autoscaling_cpu_target
    }
  }
}
