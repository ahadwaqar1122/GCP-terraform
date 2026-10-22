data "google_compute_image" "this" {
  count = var.boot_disk_image == null ? 1 : 0

  family  = var.image_family
  project = var.image_project
}
