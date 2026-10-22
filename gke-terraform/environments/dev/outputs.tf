output "cluster_name" {
  value = module.gke.cluster_name
}

output "get_credentials_command" {
  description = "Run this to configure kubectl against the cluster."
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${var.project_id}"
}

output "node_service_account_email" {
  value = module.gke.node_service_account_email
}

output "workload_pool" {
  value = module.gke.workload_pool
}
