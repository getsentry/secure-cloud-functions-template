resource "google_storage_bucket" "staging_bucket" {
  name                     = "${var.project}-cloud-function-staging"
  location                 = "US"
  force_destroy            = true
  public_access_prevention = "enforced"
}

resource "google_storage_bucket_iam_binding" "staging-bucket-iam" {
  bucket = google_storage_bucket.tf-state.name
  role   = "roles/storage.objectUser"

  members = ["serviceAccount:${var.deploy_sa_email != null ? var.deploy_sa_email : google_service_account.gha_cloud_functions_deployment[0].email}"]

  depends_on = [
    google_storage_bucket.staging_bucket
  ]
}

resource "google_storage_bucket_iam_member" "staging_bucket_get" {
  bucket = google_storage_bucket.staging_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.deploy_sa_email != null ? var.deploy_sa_email : google_service_account.gha_cloud_functions_deployment[0].email}"
}

resource "google_storage_bucket" "tf-state" {
  name                     = "${var.project}-tfstate"
  force_destroy            = true
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

  members = ["serviceAccount:${var.deploy_sa_email != null ? var.deploy_sa_email : google_service_account.gha_cloud_functions_deployment[0].email}"]

  depends_on = [
    google_storage_bucket.tf-state
  ]
}

resource "google_storage_bucket_iam_member" "tfstate_bucket_get" {
  bucket = google_storage_bucket.tf-state.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.deploy_sa_email != null ? var.deploy_sa_email : google_service_account.gha_cloud_functions_deployment[0].email}"
}
