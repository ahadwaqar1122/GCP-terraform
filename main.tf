module "vpc" {
  source = "./modules/vpc"

  name         = var.network_name
  routing_mode = var.routing_mode
  region       = var.region
  subnets      = var.subnets
}

module "firewall" {
  source = "./modules/firewall"

  network_name           = module.vpc.name
  target_tags            = [var.instance_network_tag]
  enable_iap_ssh         = true
  enable_public_ssh      = var.instance_allow_private_ssh
  ssh_source_ranges      = var.instance_ssh_source_ranges
  enable_lb_health_check = var.enable_load_balancer
  # Open every port the LB health-checks: MIG serving ports + standalone-VM backend ports.
  lb_serving_ports = distinct(concat(
    [for m in var.migs : tostring(m.serving_port)],
    [for b in var.lb_backends : tostring(b.port)],
  ))

  depends_on = [module.vpc]
}

module "cloud_nat" {
  source = "./modules/cloud-nat"

  name            = var.network_name
  region          = var.region
  network         = module.vpc.id
  static_ip_count = var.nat_static_ip_count

  depends_on = [module.vpc]
}

module "instance_template" {
  for_each = var.migs

  source = "./modules/instance-template"

  name_prefix       = each.key
  machine_type      = each.value.machine_type
  region            = var.region
  subnetwork        = module.vpc.subnets[coalesce(each.value.subnet_name, "lo-prod")].self_link
  boot_disk_size_gb = each.value.boot_disk_size_gb
  boot_disk_type    = coalesce(each.value.boot_disk_type, "pd-ssd")
  image_project     = coalesce(each.value.image_project, var.instance_image_project)
  image_family      = coalesce(each.value.image_family, var.instance_image_family)
  # When image_name is set, boot from that exact custom image (clone) instead of a family.
  boot_disk_image    = each.value.image_name != null ? "projects/${coalesce(each.value.image_project, var.project_id)}/global/images/${each.value.image_name}" : null
  enable_secure_boot = var.instance_enable_secure_boot

  network_tags = concat([var.instance_network_tag], coalesce(each.value.additional_tags, []))
  labels = merge(
    {
      environment = "prod"
      managed_by  = "terraform"
    },
    coalesce(each.value.labels, {})
  )

  startup_script  = each.value.startup_script_path != null ? file("${path.module}/${each.value.startup_script_path}") : null
  enable_os_login = var.instance_enable_os_login
  ssh_public_keys = var.instance_ssh_public_key != "" ? {
    (var.instance_ssh_username) = var.instance_ssh_public_key
  } : {}
  service_account_email = each.value.service_account_email

  depends_on = [module.vpc]
}

module "mig" {
  for_each = var.migs

  source = "./modules/mig"

  name               = each.key
  region             = var.region
  base_instance_name = each.key
  instance_template  = module.instance_template[each.key].self_link

  target_size           = each.value.target_size
  serving_port          = each.value.serving_port
  named_port_name       = "${each.key}-port"
  health_check_path     = each.value.health_check_path
  health_check_protocol = each.value.health_check_protocol
  health_check_host     = each.value.health_check_host
  autoscaling_enabled   = each.value.autoscaling_enabled
  autoscaling_min     = each.value.autoscaling_min
  autoscaling_max     = each.value.autoscaling_max

  depends_on = [module.cloud_nat]
}

module "load_balancer" {
  count = var.enable_load_balancer ? 1 : 0

  source = "./modules/load-balancer"

  name            = "${var.network_name}-lb2"
  default_backend = var.lb_default_backend
  routing         = var.lb_routing
  ssl_domains     = var.lb_ssl_domains

  # MIG backends reference a key in var.migs; VM backends reference a key in var.instances.
  backends = {
    for k, b in var.lb_backends : k => {
      source                = b.source
      group                 = b.source == "mig" ? module.mig[k].instance_group : null
      instance              = b.source == "vm" ? module.instances[b.instance].self_link : null
      zone                  = b.source == "vm" ? coalesce(var.instances[b.instance].zone, "${var.region}-c") : null
      protocol              = b.protocol
      port                  = b.port
      port_name             = null
      health_check_path     = b.health_check_path
      health_check_protocol = b.health_check_protocol
      health_check_host     = b.health_check_host
      timeout_sec           = b.timeout_sec
    }
  }

  depends_on = [module.mig, module.instances, module.firewall]
}

module "instances" {
  for_each = var.instances

  source = "./modules/compute-instance"

  name       = each.key
  zone       = coalesce(each.value.zone, "${var.region}-c")
  region     = var.region
  subnetwork = module.vpc.subnets[coalesce(each.value.subnet_name, "lo-prod")].self_link

  machine_type      = each.value.machine_type
  boot_disk_size_gb = each.value.boot_disk_size_gb
  boot_disk_type    = coalesce(each.value.boot_disk_type, "pd-ssd")
  image_project     = coalesce(each.value.image_project, var.instance_image_project)
  image_family      = coalesce(each.value.image_family, var.instance_image_family)
  # When image_name is set, boot from that exact custom image (clone) instead of a family.
  boot_disk_image    = each.value.image_name != null ? "projects/${coalesce(each.value.image_project, var.project_id)}/global/images/${each.value.image_name}" : null
  enable_secure_boot = var.instance_enable_secure_boot
  static_ip_name     = null
  nat_ip             = null
  internal_ip        = each.value.internal_ip

  # Attach cloned data disks (e.g. media VM's redis/static/swap disks).
  # Disk self-links are constructed from disk names listed in attached_disk_names.
  attached_disks = [
    for disk_name in coalesce(each.value.attached_disk_names, []) : {
      source      = "projects/${var.project_id}/zones/${coalesce(each.value.zone, "${var.region}-c")}/disks/${disk_name}"
      device_name = disk_name
      mode        = "READ_WRITE"
    }
  ]

  network_tags = concat([var.instance_network_tag], coalesce(each.value.additional_tags, []))
  labels = merge(
    {
      environment = "prod"
      managed_by  = "terraform"
    },
    coalesce(each.value.labels, {})
  )

  startup_script  = each.value.startup_script_path != null ? file("${path.module}/${each.value.startup_script_path}") : null
  enable_os_login = coalesce(each.value.enable_os_login, var.instance_enable_os_login)
  ssh_public_keys = try(coalesce(each.value.ssh_public_key, var.instance_ssh_public_key), "") != "" ? {
    (coalesce(each.value.ssh_username, var.instance_ssh_username)) = coalesce(each.value.ssh_public_key, var.instance_ssh_public_key)
  } : {}
  service_account_email = each.value.service_account_email

  depends_on = [
    module.vpc,
    module.firewall,
    google_compute_disk.media_vm,
  ]
}
