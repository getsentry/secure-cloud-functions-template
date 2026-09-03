resource "google_service_account" "cronjob_sa" {
  account_id   = "crc-${var.name}"
  display_name = "Cloud Run cron Service Account for ${var.name}"
  description  = "Service account for the ${var.name} schedule, owned by ${var.owner}, managed by Terraform"
}

resource "google_cloud_run_v2_service_iam_member" "invoker" {
  project  = var.target_project
  location = var.target_region
  name     = var.target_service_name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.cronjob_sa.email}"
}

resource "google_cloud_scheduler_job" "cron_scheduler" {
  name             = "${var.name}-cron"
  region           = var.target_region
  description      = var.description
  schedule         = var.schedule
  time_zone        = var.time_zone
  attempt_deadline = var.attempt_deadline

  http_target {
    http_method = var.http_method
    uri         = "${var.target_url}${var.path}"

    oidc_token {
      # The audience is the service root, not the path: Cloud Run validates the
      # token against the service URL, so appending the path here fails with 401.
      audience              = var.target_url
      service_account_email = google_service_account.cronjob_sa.email
    }
  }
}
