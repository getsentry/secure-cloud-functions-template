output "bucket_name" {
  description = "Bucket that exported messages land in."
  value       = google_storage_bucket.pubsub-sink-bucket.name
}

output "subscription_name" {
  description = "Export subscription feeding the bucket."
  value       = google_pubsub_subscription.sink.name
}
