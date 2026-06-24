resource "google_service_account" "cronjob_sa" {
  account_id   = "cj-${var.name}"
  display_name = "CronJob Service Account for ${var.name}"
  description  = "Service account for ${var.name}, owned by ${var.owner}, managed by Terraform"
}

# NOTE: the deploy SA's actAs on this runtime SA comes from the project-wide
# roles/iam.serviceAccountUser grant (see infrastructure/permissions.tf). A
# per-SA binding here would have to be created with iam.serviceAccounts.setIamPolicy
# on a freshly-created SA, which is not possible without a broader project grant.

resource "google_cloudfunctions2_function_iam_member" "cj_gen2_cron_invoker" {
  project        = var.target_project
  location       = var.target_region
  cloud_function = var.target_function_name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.cronjob_sa.email}"
}

resource "google_cloud_run_service_iam_member" "cj_gen2_cron_invoker" {
  project  = var.target_project
  location = var.target_region
  service  = var.target_function_name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.cronjob_sa.email}"
}

resource "google_cloud_scheduler_job" "cron_scheduler" {
  name             = var.name
  description      = var.description
  schedule         = var.schedule
  time_zone        = var.time_zone
  attempt_deadline = var.attempt_deadline

  http_target {
    http_method = var.http_method
    uri         = var.https_trigger_url

    oidc_token {
      audience              = var.https_trigger_url
      service_account_email = google_service_account.cronjob_sa.email
    }
  }
}