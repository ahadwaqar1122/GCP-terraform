terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # Step 1 uses local state. Configure GCS before team/production use:
  # backend "gcs" {
  #   bucket = "your-terraform-state-bucket"
  #   prefix = "laptopoutlet-infra/vpc"
  # }
}
