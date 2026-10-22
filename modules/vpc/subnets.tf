resource "google_compute_subnetwork" "this" {
  for_each = var.subnets

  name          = each.key
  ip_cidr_range = each.value.cidr
  region        = coalesce(each.value.region, var.region)
  network       = google_compute_network.this.id

  private_ip_google_access = coalesce(each.value.private_ip_google_access, var.private_ip_google_access)

  description = try(each.value.description, null)
}
