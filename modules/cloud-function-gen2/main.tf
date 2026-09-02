resource "google_service_account" "function_sa" {
  account_id   = "cf-${var.name}"
  display_name = "Cloud Function Service Account for ${var.name}"
  description  = "Service account for ${var.name}, owned by ${var.owner}, managed by Terraform"
}

# Both grants are needed: gen2 functions are backed by Cloud Run, and callers
# may hit either front end.
resource "google_cloudfunctions2_function_iam_member" "invoker_allusers_iam" {
  count          = var.allow_unauthenticated ? 1 : 0
  project        = google_cloudfunctions2_function.function.project
  location       = google_cloudfunctions2_function.function.location
  cloud_function = google_cloudfunctions2_function.function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}

resource "google_cloud_run_service_iam_member" "invoker_allusers_iam" {
  count    = var.allow_unauthenticated ? 1 : 0
  project  = google_cloudfunctions2_function.function.project
  location = google_cloudfunctions2_function.function.location
  service  = google_cloudfunctions2_function.function.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_secret_manager_secret_iam_member" "secret_iam" {
  for_each = { for s in var.secret_environment_variables : s.key => s }
  # Via var.secret_ids rather than the raw name, so referencing a secret that is
  # missing from the root `secrets` list fails at plan time.
  secret_id = var.secret_ids[each.value.secret]
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.function_sa.email}"
}

resource "google_project_iam_member" "function_sa_logwriter_iam" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

data "archive_file" "source" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${var.temp_zip_output_dir}/${var.name}.zip"
  excludes    = var.files_to_exclude
}

resource "google_storage_bucket_object" "zip" {
  source       = data.archive_file.source.output_path
  content_type = "application/zip"
  metadata = {
    owner       = var.owner
    terraformed = "true"
  }

  # The name embeds the MD5 of the contents, so any source change produces a new
  # object and forces a redeploy.
  name   = "${var.source_object_prefix}${data.archive_file.source.output_md5}.zip"
  bucket = var.staging_bucket
}

resource "google_cloudfunctions2_function" "function" {
  name        = var.name
  location    = var.location
  description = var.description
  labels = {
    owner       = var.owner
    terraformed = "true"
  }

  build_config {
    runtime           = var.runtime
    entry_point       = var.function_entrypoint
    docker_repository = "projects/${var.project}/locations/${var.location}/repositories/gcf-artifacts"
    source {
      storage_source {
        bucket = var.staging_bucket
        object = google_storage_bucket_object.zip.name
      }
    }
  }

  service_config {
    timeout_seconds       = var.execution_timeout
    available_memory      = var.available_memory
    service_account_email = google_service_account.function_sa.email
    ingress_settings      = var.ingress_settings
    environment_variables = var.environment_variables
    min_instance_count    = var.min_instances
    max_instance_count    = var.max_instances

    dynamic "secret_environment_variables" {
      for_each = var.secret_environment_variables
      iterator = item
      content {
        key        = item.value.key
        secret     = var.secret_ids[item.value.secret]
        version    = item.value.version
        project_id = var.project
      }
    }
  }

  depends_on = [
    google_secret_manager_secret_iam_member.secret_iam,
  ]
}
