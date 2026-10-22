locals {
  # Backends that are standalone VMs need an unmanaged instance group created here.
  vm_backends = { for k, b in var.backends : k => b if b.source == "vm" }

  # Named port per backend: MIGs publish their own (passed in), VMs get one created here.
  backend_port_name = {
    for k, b in var.backends : k => coalesce(b.port_name, "${k}-port")
  }

  # Resolve the instance group each backend service points at.
  backend_group = {
    for k, b in var.backends : k => (
      b.source == "vm" ? google_compute_instance_group.vm[k].self_link : b.group
    )
  }

  # Health check protocol defaults to the backend's serving protocol.
  hc_protocol = {
    for k, b in var.backends : k => coalesce(b.health_check_protocol, b.protocol)
  }
}

# ---------------------------------------------------------------------------
# Unmanaged instance groups wrapping standalone VMs (media, connector, ...).
# ---------------------------------------------------------------------------
resource "google_compute_instance_group" "vm" {
  for_each = local.vm_backends

  name      = "${var.name}-${each.key}-ig"
  zone      = each.value.zone
  instances = [each.value.instance]

  named_port {
    name = local.backend_port_name[each.key]
    port = each.value.port
  }
}

# ---------------------------------------------------------------------------
# Health checks (HTTP or HTTPS, matched to each backend).
# Source ranges 35.191.0.0/16 and 130.211.0.0/22 are opened in the firewall.
# ---------------------------------------------------------------------------
resource "google_compute_health_check" "this" {
  for_each = var.backends

  name                = "${var.name}-${each.key}-hc"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  dynamic "http_health_check" {
    for_each = local.hc_protocol[each.key] == "HTTP" ? [1] : []
    content {
      port         = each.value.port
      request_path = each.value.health_check_path
      host         = each.value.health_check_host
    }
  }

  dynamic "https_health_check" {
    for_each = local.hc_protocol[each.key] == "HTTPS" ? [1] : []
    content {
      port         = each.value.port
      request_path = each.value.health_check_path
      host         = each.value.health_check_host
    }
  }
}

# ---------------------------------------------------------------------------
# One backend service per app.
# ---------------------------------------------------------------------------
resource "google_compute_backend_service" "this" {
  for_each = var.backends

  name                  = "${var.name}-${each.key}-bes"
  protocol              = each.value.protocol
  port_name             = local.backend_port_name[each.key]
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = each.value.timeout_sec
  health_checks         = [google_compute_health_check.this[each.key].id]

  backend {
    group           = local.backend_group[each.key]
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  timeouts {
    create = "40m"
    update = "40m"
  }
}

# ---------------------------------------------------------------------------
# URL map: one virtual host (host_rule + path_matcher) per entry in var.routing.
# ---------------------------------------------------------------------------
resource "google_compute_url_map" "this" {
  name            = "${var.name}-url-map"
  default_service = google_compute_backend_service.this[var.default_backend].id

  dynamic "host_rule" {
    for_each = { for idx, vh in var.routing : idx => vh }
    content {
      hosts        = host_rule.value.hosts
      path_matcher = "pm-${host_rule.key}"
    }
  }

  dynamic "path_matcher" {
    for_each = { for idx, vh in var.routing : idx => vh }
    content {
      name            = "pm-${path_matcher.key}"
      default_service = google_compute_backend_service.this[path_matcher.value.default_backend].id

      dynamic "path_rule" {
        for_each = path_matcher.value.path_rules
        content {
          paths   = path_rule.value.paths
          service = google_compute_backend_service.this[path_rule.value.backend].id
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Single global IP + HTTPS front end (managed cert) + HTTP->HTTPS redirect.
# ---------------------------------------------------------------------------
resource "google_compute_global_address" "this" {
  name = "${var.name}-ip"
}

resource "google_compute_managed_ssl_certificate" "this" {
  name = "${var.name}-cert"

  managed {
    domains = var.ssl_domains
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_target_https_proxy" "this" {
  name             = "${var.name}-https-proxy"
  url_map          = google_compute_url_map.this.id
  ssl_certificates = [google_compute_managed_ssl_certificate.this.id]
}

resource "google_compute_global_forwarding_rule" "https" {
  name                  = "${var.name}-https-fr"
  target                = google_compute_target_https_proxy.this.id
  ip_address            = google_compute_global_address.this.id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
}

# Plain :80 traffic is permanently redirected to :443.
resource "google_compute_url_map" "redirect" {
  name = "${var.name}-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "redirect" {
  name    = "${var.name}-http-proxy"
  url_map = google_compute_url_map.redirect.id
}

resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${var.name}-http-fr"
  target                = google_compute_target_http_proxy.redirect.id
  ip_address            = google_compute_global_address.this.id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL"
}
