terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0.1"
    }
  }
  backend "gcs" {
    # Had to hardcode the bucket name here because it does not support variables
    bucket = "jeffreyhung-test-tfstate"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_storage_bucket" "staging_bucket" {
  name                     = "${var.project}-cloud-function-staging"
  location                 = "US"
  force_destroy            = true
  public_access_prevention = "enforced"
}

resource "google_storage_bucket_iam_binding" "staging-bucket-iam" {
  bucket = google_storage_bucket.tf-state.name
  role   = "roles/storage.objectUser"

  members = ["serviceAccount:${module.infrastructure.deploy_sa_email}"]

  depends_on = [
    module.infrastructure,
    google_storage_bucket.staging_bucket
  ]
}

resource "google_storage_bucket_iam_member" "staging_bucket_get" {
  bucket = google_storage_bucket.staging_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${module.infrastructure.deploy_sa_email}"
}

resource "google_storage_bucket" "tf-state" {
  name                     = "${var.project}-tfstate"
  force_destroy            = false
  location                 = "US"
  storage_class            = "STANDARD"
  public_access_prevention = "enforced"
  versioning {
    enabled = true
  }
}

resource "google_storage_bucket_iam_binding" "tfstate-bucket-iam" {
  bucket = google_storage_bucket.tf-state.name
  role   = "roles/storage.objectUser"

  members = ["serviceAccount:${module.infrastructure.deploy_sa_email}"]

  depends_on = [
    module.infrastructure,
    google_storage_bucket.tf-state
  ]
}

resource "google_storage_bucket_iam_member" "tfstate_bucket_get" {
  bucket = google_storage_bucket.tf-state.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${module.infrastructure.deploy_sa_email}"
}