locals {
  boot_disk_image = coalesce(
    var.boot_disk_image,
    try(data.google_compute_image.this[0].self_link, null),
  )

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

resource "google_compute_instance_template" "this" {
  name_prefix  = "${var.name_prefix}-"
  machine_type = var.machine_type
  region       = var.region

  tags   = var.network_tags
  labels = var.labels

  disk {
    source_image = local.boot_disk_image
    disk_size_gb = var.boot_disk_size_gb
    disk_type    = var.boot_disk_type
    auto_delete  = true
    boot         = true
  }

  # Private only — no access_config block means no external IP.
  # Outbound internet is provided by Cloud NAT.
  network_interface {
    subnetwork = var.subnetwork
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
    create_before_destroy = true
  }
}
