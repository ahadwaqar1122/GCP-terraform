locals {
  boot_disk_image = coalesce(
    var.boot_disk_image,
    try(data.google_compute_image.this[0].self_link, null),
  )

  external_ip = var.static_ip_name != null ? google_compute_address.this[0].address : var.nat_ip

  ssh_keys_metadata = length(var.ssh_public_keys) > 0 ? {
    ssh-keys = join("\n", [
      for username, public_key in var.ssh_public_keys : "${username}:${chomp(public_key)}"
    ])
  } : {}

  metadata = merge(
    { enable-oslogin = var.enable_os_login ? "TRUE" : "FALSE" },
    local.ssh_keys_metadata,
    var.startup_script != null ? { startup-script = var.startup_script } : {},
  )
}

resource "google_compute_instance" "this" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone

  tags   = var.network_tags
  labels = var.labels

  boot_disk {
    auto_delete = false
    initialize_params {
      image = local.boot_disk_image
      size  = var.boot_disk_size_gb
      type  = var.boot_disk_type
    }
  }

  dynamic "attached_disk" {
    for_each = var.attached_disks
    content {
      source      = attached_disk.value.source
      device_name = attached_disk.value.device_name
      mode        = coalesce(attached_disk.value.mode, "READ_WRITE")
    }
  }

  network_interface {
    subnetwork = var.subnetwork
    network_ip = var.internal_ip

    dynamic "access_config" {
      for_each = local.external_ip != null ? [1] : []
      content {
        nat_ip = local.external_ip
      }
    }
  }

  dynamic "service_account" {
    for_each = var.service_account_email != null ? [1] : []
    content {
      email  = var.service_account_email
      scopes = ["cloud-platform"]
    }
  }

  metadata = local.metadata

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  shielded_instance_config {
    enable_secure_boot          = var.enable_secure_boot
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  lifecycle {
    create_before_destroy = false
  }
}
