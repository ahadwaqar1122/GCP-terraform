terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.40"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.40"
    }
  }

  # Remote state so multiple people/CI can safely apply. Create the bucket
  # once, out of band, e.g.:
  #   gsutil mb -l <region> -b on gs://REPLACE_WITH_YOUR_TF_STATE_BUCKET
  #   gsutil versioning set on gs://REPLACE_WITH_YOUR_TF_STATE_BUCKET
  backend "gcs" {
    bucket = "REPLACE_WITH_YOUR_TF_STATE_BUCKET"
    prefix = "gke/dev"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}
