output "id" {
  description = "Instance template ID."
  value       = google_compute_instance_template.this.id
}

output "self_link" {
  description = "Instance template self link."
  value       = google_compute_instance_template.this.self_link
}

output "name" {
  description = "Generated instance template name."
  value       = google_compute_instance_template.this.name
}
