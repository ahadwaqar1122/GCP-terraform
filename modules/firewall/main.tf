resource "google_compute_firewall" "allow_iap_ssh" {
  count = var.enable_iap_ssh ? 1 : 0

  name    = "${var.network_name}-allow-iap-ssh"
  network = var.network_name

  description = "Allow SSH to instances via Identity-Aware Proxy."

  direction = "INGRESS"
  priority  = 65534

  source_ranges = ["35.235.240.0/20"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = var.target_tags
}

resource "google_compute_firewall" "allow_lb_health_check" {
  count = var.enable_lb_health_check ? 1 : 0

  name    = "${var.network_name}-allow-lb-health-check"
  network = var.network_name

  description = "Allow Google Front End and health check ranges to reach backends."

  direction = "INGRESS"
  priority  = 1000

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]

  allow {
    protocol = "tcp"
    ports    = var.lb_serving_ports
  }

  target_tags = var.target_tags
}

resource "google_compute_firewall" "allow_ssh" {
  count = var.enable_public_ssh ? 1 : 0

  name    = "${var.network_name}-allow-ssh"
  network = var.network_name

  description = "Allow SSH to instances from trusted source ranges."

  direction = "INGRESS"
  priority  = 65534

  source_ranges = var.ssh_source_ranges

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = var.target_tags
}
