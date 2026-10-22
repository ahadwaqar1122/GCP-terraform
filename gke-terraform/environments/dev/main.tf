module "vpc" {
  source = "../../modules/vpc"

  project_id           = var.project_id
  region               = var.region
  network_name         = "${var.environment}-vpc"
  subnet_name          = "${var.environment}-gke-subnet"
  subnet_cidr          = var.subnet_cidr
  pods_range_name      = "${var.environment}-pods"
  pods_cidr            = var.pods_cidr
  services_range_name  = "${var.environment}-services"
  services_cidr        = var.services_cidr
}

module "gke" {
  source = "../../modules/gke"

  project_id                 = var.project_id
  region                     = var.region
  cluster_name               = "${var.environment}-gke"
  network_id                 = module.vpc.network_id
  subnet_id                  = module.vpc.subnet_id
  pods_range_name            = module.vpc.pods_range_name
  services_range_name        = module.vpc.services_range_name
  master_ipv4_cidr_block     = var.master_ipv4_cidr_block
  master_authorized_networks = var.master_authorized_networks
  enable_private_endpoint    = var.enable_private_endpoint
  release_channel            = var.release_channel
  deletion_protection        = var.deletion_protection
}

module "default_node_pool" {
  source = "../../modules/node-pool"

  project_id             = var.project_id
  location               = var.region
  cluster_name           = module.gke.cluster_name
  pool_name              = "default-pool"
  machine_type           = var.default_pool_machine_type
  min_count              = var.default_pool_min_count
  max_count              = var.default_pool_max_count
  disk_size_gb           = 100
  disk_type              = "pd-balanced"
  spot                   = true # dev: use Spot VMs to cut cost, fine for non-critical workloads
  service_account_email  = module.gke.node_service_account_email
  labels                 = { environment = var.environment }
  network_tags           = ["${var.environment}-gke-node"]
}
