output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "cluster_id" {
  value = google_container_cluster.primary.id
}

output "endpoint" {
  description = "Control plane endpoint IP."
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "ca_certificate" {
  value     = google_container_cluster.primary.master_auth.0.cluster_ca_certificate
  sensitive = true
}

output "node_service_account_email" {
  value = google_service_account.gke_nodes.email
}

output "workload_pool" {
  value = "${var.project_id}.svc.id.goog"
}
