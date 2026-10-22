output "ip_address" {
  description = "External IP address of the load balancer."
  value       = google_compute_global_address.this.address
}

output "url_map" {
  description = "URL map name."
  value       = google_compute_url_map.this.name
}

output "backend_services" {
  description = "Backend service names keyed by backend."
  value       = { for k, b in google_compute_backend_service.this : k => b.name }
}

output "ssl_certificate" {
  description = "Managed SSL certificate name."
  value       = google_compute_managed_ssl_certificate.this.name
}
