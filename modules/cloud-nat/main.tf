resource "google_compute_router" "this" {
  name    = "${var.name}-router"
  region  = var.region
  network = var.network
}

# Static egress IP(s) so the address can be added to Cloud SQL authorized networks.
resource "google_compute_address" "nat" {
  count  = var.static_ip_count
  name   = "${var.name}-nat-ip-${count.index}"
  region = var.region
}

resource "google_compute_router_nat" "this" {
  name   = var.name
  router = google_compute_router.this.name
  region = var.region

  nat_ip_allocate_option = var.static_ip_count > 0 ? "MANUAL_ONLY" : "AUTO_ONLY"
  nat_ips                = google_compute_address.nat[*].self_link

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
