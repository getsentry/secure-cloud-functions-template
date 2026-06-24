resource "google_storage_bucket" "staging_bucket" {
  name                        = "${var.project}-cloud-function-staging"
  location                    = "US"
  force_destroy               = true
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
  labels = {
    owner       = var.owner
    terraformed = "true"
  }
}

resource "google_storage_bucket_iam_binding" "staging-bucket-iam" {
  bucket = google_storage_bucket.staging_bucket.name
  role   = "roles/storage.objectUser"

  members = ["serviceAccount:${local.apply_sa_email}"]

  depends_on = [
    google_storage_bucket.staging_bucket
  ]
}

resource "google_storage_bucket_iam_member" "staging_bucket_get" {
  bucket = google_storage_bucket.staging_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${local.apply_sa_email}"
}

# Plan SA: object-content read (storage.objects.get) to refresh the function
# source zip objects, scoped to the staging bucket ONLY. roles/viewer grants no
# object reads, and this is deliberately not project-wide so the read-only plan
# identity cannot read other buckets' object contents (e.g. pub/sub sink data).
resource "google_storage_bucket_iam_member" "staging_bucket_plan_object_read" {
  count  = var.deploy_sa_email != null ? 0 : 1
  bucket = google_storage_bucket.staging_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.gha_tf_plan[0].email}"
}

resource "google_storage_bucket" "tf-state" {
  name                        = "${var.project}-tfstate"
  force_destroy               = false
  location                    = "US"
  storage_class               = "STANDARD"
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
  labels = {
    owner       = var.owner
    terraformed = "true"
  }

  # The state bucket is the source of truth for managing this project. Guard
  # against accidental deletion (e.g. a stray `terraform destroy`).
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_storage_bucket_iam_binding" "tfstate-bucket-iam" {
  bucket = google_storage_bucket.tf-state.name
  role   = "roles/storage.objectUser"

  # Apply SA always; plan SA also needs object read + lock-object write to run
  # `terraform plan` against the GCS backend. (This binding is authoritative for
  # the role, so both members must be listed here.)
  members = var.deploy_sa_email != null ? [
    "serviceAccount:${local.apply_sa_email}",
    ] : [
    "serviceAccount:${local.apply_sa_email}",
    "serviceAccount:${google_service_account.gha_tf_plan[0].email}",
  ]

  depends_on = [
    google_storage_bucket.tf-state
  ]
}

resource "google_storage_bucket_iam_member" "tfstate_bucket_get" {
  bucket = google_storage_bucket.tf-state.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${local.apply_sa_email}"
}
