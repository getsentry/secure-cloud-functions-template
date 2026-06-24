resource "google_service_account" "workflow_sa" {
  account_id   = "wf-${var.name}"
  display_name = "Workflow Service Account for ${var.name}"
  description  = "Service account for ${var.name}, owned by ${var.owner}, managed by Terraform"
}

# NOTE: the deploy SA's actAs on this runtime SA comes from the project-wide
# roles/iam.serviceAccountUser grant (see infrastructure/permissions.tf), not a
# per-SA binding here — see that file for why per-SA scoping isn't feasible.

resource "google_workflows_workflow" "workflow" {
  name            = var.name
  description     = var.description
  service_account = google_service_account.workflow_sa.id
  source_contents = templatefile("${var.workflow_yaml_file}", {})
  labels = {
    owner       = var.owner
    terraformed = "true"
  }
}

resource "google_cloudfunctions2_function_iam_member" "_" {
  for_each       = var.functions
  cloud_function = each.value
  member         = "serviceAccount:${google_service_account.workflow_sa.email}"
  role           = "roles/cloudfunctions.invoker"
}

resource "google_storage_bucket_iam_member" "workflow_bucket_read" {
  for_each = var.bucket
  bucket   = each.value
  role     = "roles/storage.objectViewer"
  member   = "serviceAccount:${google_service_account.workflow_sa.email}"
}

resource "google_project_iam_member" "workflow_invoker" {
  # NOTE: This grant is project-wide because Cloud Workflows cannot currently be
  # scoped to a single workflow in Terraform: the hashicorp/google provider
  # exposes no google_workflows_workflow_iam_* resource in ANY version (v6 or
  # v7), and workflows.googleapis.com does not support resource.name IAM
  # Conditions. Only created when this workflow actually calls other workflows.
  # Revisit if/when the provider adds resource-level Workflows IAM.
  count   = length(var.workflow) == 0 ? 0 : 1
  project = var.project
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.workflow_sa.email}"
}