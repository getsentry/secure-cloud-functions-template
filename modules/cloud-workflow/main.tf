resource "google_service_account" "workflow_sa" {
  account_id   = "wf-${var.name}"
  display_name = "Workflow Service Account for ${var.name}"
}

resource "google_service_account_iam_member" "workflow_sa_actas_iam" {
  service_account_id = google_service_account.workflow_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.workflow_sa.email}"
}

resource "google_service_account_iam_member" "deploy_sa_actas_iam" {
  service_account_id = google_service_account.workflow_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.deploy_sa_email}" # we have to set this for our CD to work
}

resource "google_workflows_workflow" "workflow" {
  name            = var.name
  description     = var.description
  service_account = google_service_account.workflow_sa.id
  source_contents = templatefile("${var.workflow_yaml_file}", {})
  depends_on = [
    google_service_account_iam_member.workflow_sa_actas_iam,
    google_service_account_iam_member.deploy_sa_actas_iam
  ]
}

resource "google_cloudfunctions2_function_iam_member" "_" {
  for_each       = var.functions
  cloud_function = each.value
  member         = "serviceAccount:${google_service_account.workflow_sa.email}"
  role           = "roles/cloudfunctions.invoker"
}
