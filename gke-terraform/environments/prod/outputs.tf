output "cluster_name" {
  value = module.gke.cluster_name
}

output "get_credentials_command" {
  description = "Run this from inside the VPC (VPN/bastion/CI runner) since the endpoint is private."
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${var.project_id} --internal-ip"
}

output "node_service_account_email" {
  value = module.gke.node_service_account_email
}

output "workload_pool" {
  value = module.gke.workload_pool
}
