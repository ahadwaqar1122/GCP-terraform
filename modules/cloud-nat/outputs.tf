output "router_name" {
  description = "Cloud Router name."
  value       = google_compute_router.this.name
}

output "nat_name" {
  description = "Cloud NAT name."
  value       = google_compute_router_nat.this.name
}

output "nat_ips" {
  description = "Static egress IPs reserved for NAT (add these to Cloud SQL authorized networks)."
  value       = google_compute_address.nat[*].address
}
