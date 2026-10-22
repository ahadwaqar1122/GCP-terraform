output "vpc" {
  description = "VPC network details."
  value = {
    name      = module.vpc.name
    id        = module.vpc.id
    self_link = module.vpc.self_link
    subnets   = module.vpc.subnets
  }
}

output "firewall" {
  description = "Firewall rule names."
  value = {
    iap_ssh_rule     = module.firewall.iap_ssh_rule_name
    private_ssh_rule = module.firewall.public_ssh_rule_name
  }
}

output "instances" {
  description = "Private compute instance details."
  value = {
    for name, instance in module.instances : name => {
      name        = instance.name
      zone        = instance.zone
      internal_ip = instance.internal_ip
      external_ip = instance.external_ip
      self_link   = instance.self_link
    }
  }
}

output "instance_images" {
  description = "Boot images used by the instances."
  value = {
    for name, instance in module.instances : name => instance.image
  }
}

output "cloud_nat" {
  description = "Cloud NAT details."
  value = {
    router  = module.cloud_nat.router_name
    nat     = module.cloud_nat.nat_name
    nat_ips = module.cloud_nat.nat_ips
  }
}

output "migs" {
  description = "Managed instance groups."
  value = {
    for name, mig in module.mig : name => {
      name           = mig.name
      instance_group = mig.instance_group
    }
  }
}

output "load_balancer" {
  description = "External load balancer details, if enabled."
  value = var.enable_load_balancer ? {
    ip_address       = module.load_balancer[0].ip_address
    url_map          = module.load_balancer[0].url_map
    backend_services = module.load_balancer[0].backend_services
    ssl_certificate  = module.load_balancer[0].ssl_certificate
  } : null
}
