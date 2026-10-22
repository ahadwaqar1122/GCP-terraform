resource "google_compute_address" "this" {
  count = var.static_ip_name != null ? 1 : 0

  name   = var.static_ip_name
  region = var.region
}
