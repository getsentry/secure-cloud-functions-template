resource "google_service_account" "earc-trigger-sa" {
  account_id   = "earc-${var.name}"
  display_name = "Earc trigger ${var.name}"
  description  = "Service account for the earc trigger ${var.name}, owned by ${var.owner}, managed by Terraform"
}

resource "google_project_iam_member" "earc_sa_triggerwf_iam" {
  # NOTE: This grant is project-wide because Cloud Workflows cannot currently be
  # scoped to a single workflow in Terraform: the hashicorp/google provider
  # exposes no google_workflows_workflow_iam_* resource in ANY version (v6 or
  # v7), and workflows.googleapis.com does not support resource.name IAM
  # Conditions. Residual risk is limited: workflows.invoker only permits
  # executing workflows in the project, and this is a dedicated single-purpose
  # SA. Revisit if/when the provider adds resource-level Workflows IAM.
  project = var.workflow_project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.earc-trigger-sa.email}"
}

resource "google_project_iam_member" "earc_sa_receiveevent_iam" {
  project = var.workflow_project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.earc-trigger-sa.email}"
}

resource "google_service_account_iam_member" "deploy_sa_actas_iam" {
  service_account_id = google_service_account.earc-trigger-sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.deploy_sa_email}" # Allow CD service account to manage this SA
}

resource "google_eventarc_trigger" "earc-trigger" {
  name            = var.name
  location        = var.location
  service_account = google_service_account.earc-trigger-sa.email
  labels = {
    owner       = var.owner
    terraformed = "true"
  }

  dynamic "matching_criteria" {
    for_each = var.criteria
    iterator = item
    content {
      attribute = item.value.attribute
      value     = item.value.value
    }
  }

  destination {
    workflow = var.workflow_id
  }

  depends_on = [
    google_project_iam_member.earc_sa_receiveevent_iam
  ]
}