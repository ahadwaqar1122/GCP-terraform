output "name" {
  description = "Instance name."
  value       = google_compute_instance.this.name
}

output "self_link" {
  description = "Instance self link."
  value       = google_compute_instance.this.self_link
}

output "zone" {
  description = "Instance zone."
  value       = google_compute_instance.this.zone
}

output "internal_ip" {
  description = "Primary internal IP."
  value       = google_compute_instance.this.network_interface[0].network_ip
}

output "external_ip" {
  description = "External IP if assigned."
  value       = try(google_compute_instance.this.network_interface[0].access_config[0].nat_ip, null)
}

output "static_ip" {
  description = "Reserved static external IP, if created."
  value = var.static_ip_name != null ? {
    name    = google_compute_address.this[0].name
    address = google_compute_address.this[0].address
    region  = google_compute_address.this[0].region
  } : null
}

output "image" {
  description = "Boot disk image used by the instance."
  value = var.boot_disk_image != null ? {
    self_link = var.boot_disk_image
    } : {
    name               = data.google_compute_image.this[0].name
    family             = data.google_compute_image.this[0].family
    self_link          = data.google_compute_image.this[0].self_link
    creation_timestamp = data.google_compute_image.this[0].creation_timestamp
  }
}
