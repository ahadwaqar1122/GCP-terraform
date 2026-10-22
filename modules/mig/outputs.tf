output "id" {
  description = "MIG ID."
  value       = google_compute_region_instance_group_manager.this.id
}

output "name" {
  description = "MIG name."
  value       = google_compute_region_instance_group_manager.this.name
}

output "instance_group" {
  description = "Instance group self link, used as a load balancer backend."
  value       = google_compute_region_instance_group_manager.this.instance_group
}
