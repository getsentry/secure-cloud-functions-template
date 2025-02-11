resource "google_storage_bucket" "pubsub-sink-bucket" {
  name                     = var.sink_name
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
