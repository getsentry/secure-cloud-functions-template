resource "random_string" "bucket-prefix-lower" {
  length  = 12
  upper   = false
  lower   = true
  numeric = false
  special = false
}

resource "google_storage_bucket" "pubsub-sink-bucket" {
  name                     = "${random_string.bucket-prefix-lower.result}-${var.sink_name}"
  location                 = var.bucket_location
  force_destroy            = true
  public_access_prevention = "enforced"

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}
