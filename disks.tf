# ---------------------------------------------------------------------------
# Data disks for lo-redis-opensearch-prod — cloned from the original VM's
# attached disks. GCP preserves filesystem UUIDs on disk clones, so the
# existing fstab (which uses UUIDs) mounts correctly without any edits.
# ---------------------------------------------------------------------------

locals {
  media_vm_source_disks = {
    lo-media-cache-prod     = { source = "media-cache",     type = "pd-standard" } # /var/temp-media (100 GB)
    lo-redis-elastic-prod   = { source = "redis-elastic",   type = "pd-standard" } # /var/lib/redis  (100 GB)
    lo-swap-prod            = { source = "swapp-drive",     type = "pd-ssd"      } # /mnt/disks/swap (20 GB)
    lo-redis-exclusive-prod = { source = "redis-exclusive", type = "pd-balanced" } # /var/lib/keydb  (70 GB)
    lo-static-prod          = { source = "static",          type = "pd-ssd"      } # /static         (100 GB)
  }
}

resource "google_compute_disk" "media_vm" {
  for_each = local.media_vm_source_disks

  name    = each.key
  zone    = "europe-west2-a"
  project = var.project_id
  type    = each.value.type

  # Clone the source disk — preserves filesystem UUID so fstab works without
  # any edits on the new VM.
  source_disk = "projects/${var.project_id}/zones/europe-west2-a/disks/${each.value.source}"

  lifecycle {
    # Prevent accidental destruction of production data disks.
    prevent_destroy = true
  }
}
