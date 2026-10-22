output "name" {
  description = "VPC network name."
  value       = google_compute_network.this.name
}

output "id" {
  description = "VPC network ID."
  value       = google_compute_network.this.id
}

output "self_link" {
  description = "VPC network self link."
  value       = google_compute_network.this.self_link
}

output "subnets" {
  description = "Subnet details keyed by subnet name."
  value = {
    for name, subnet in google_compute_subnetwork.this : name => {
      name      = subnet.name
      id        = subnet.id
      self_link = subnet.self_link
      cidr      = subnet.ip_cidr_range
      region    = subnet.region
    }
  }
}
