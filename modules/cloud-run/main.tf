resource "google_service_account" "run_sa" {
  account_id   = "cr-${var.name}"
  display_name = "Cloud Run Service Account for ${var.name}"
  description  = "Service account for ${var.name}, owned by ${var.owner}, managed by Terraform"
}

resource "google_project_iam_member" "run_sa_logwriter" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "secret_iam" {
  for_each  = { for s in var.secret_environment_variables : s.key => s }
  secret_id = var.secret_ids[each.value.secret]
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.run_sa.email}"
}

resource "google_cloud_run_v2_service" "service" {
  name        = var.name
  location    = var.location
  project     = var.project
  description = var.description
  ingress     = var.ingress

  # Defaults to true in the provider. Left on so that removing a service from
  # Terraform fails loudly instead of silently deleting a live service; set
  # `deletion_protection: false` in terraform.yaml when you actually mean it.
  deletion_protection = var.deletion_protection

  labels = {
    owner       = var.owner
    terraformed = "true"
  }

  template {
    service_account                  = google_service_account.run_sa.email
    timeout                          = "${var.request_timeout}s"
    max_instance_request_concurrency = var.concurrency
    execution_environment            = var.execution_environment

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = var.image

      ports {
        container_port = var.port
      }

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        # false keeps the CPU allocated between requests, which costs more but
        # is required for background work after a response is returned.
        cpu_idle = var.cpu_idle
      }

      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = { for s in var.secret_environment_variables : s.key => s }
        content {
          name = env.value.key
          value_source {
            secret_key_ref {
              secret  = var.secret_ids[env.value.secret]
              version = env.value.version
            }
          }
        }
      }
    }
  }

  depends_on = [
    google_secret_manager_secret_iam_member.secret_iam,
  ]
}

# Opt-in public access. Without this the service requires an authenticated
# caller holding roles/run.invoker.
resource "google_cloud_run_v2_service_iam_member" "invoker_allusers" {
  count    = var.allow_unauthenticated ? 1 : 0
  project  = google_cloud_run_v2_service.service.project
  location = google_cloud_run_v2_service.service.location
  name     = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
