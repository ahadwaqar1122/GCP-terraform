resource "google_compute_network" "this" {
  name                    = var.name
  description             = var.description
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
}
