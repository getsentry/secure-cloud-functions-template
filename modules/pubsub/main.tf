resource "google_pubsub_topic" "topic" {
  name = var.topic_name
  labels = {
    owner       = var.owner
    terraformed = "true"
  }

  message_retention_duration = "604800s" # 7 days, the maximum
  message_storage_policy {
    allowed_persistence_regions = [var.gcp_region]
  }
}

resource "google_pubsub_subscription" "subscription" {
  name                       = var.subscription_id
  topic                      = google_pubsub_topic.topic.name
  message_retention_duration = "604800s"
  retain_acked_messages      = false
  ack_deadline_seconds       = 600 # the maximum
  enable_message_ordering    = false
  labels = {
    owner       = var.owner
    terraformed = "true"
  }

  dynamic "expiration_policy" {
    for_each = var.ttl != null ? [1] : []
    content {
      ttl = var.ttl
    }
  }

  retry_policy {
    minimum_backoff = "10s"
  }
}

resource "google_service_account" "pubsub_service_account" {
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
  description  = "Service account for ${var.topic_name}, owned by ${var.owner}, managed by Terraform"
}

resource "google_pubsub_subscription_iam_member" "viewer" {
  subscription = google_pubsub_subscription.subscription.name
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${google_service_account.pubsub_service_account.email}"
}

resource "google_pubsub_subscription_iam_member" "subscriber" {
  subscription = google_pubsub_subscription.subscription.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.pubsub_service_account.email}"
}
