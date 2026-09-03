output "service_name" {
  value = google_cloud_run_v2_service.service.name
}

output "service_url" {
  value = google_cloud_run_v2_service.service.uri
}

output "service_account_email" {
  value = google_service_account.run_sa.email
}

output "image" {
  description = "Container image this service is pinned to."
  value       = var.image
}
