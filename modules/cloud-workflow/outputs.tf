output "workflow_sa_name" {
  value = google_service_account.workflow_sa.name
}

output "workflow_sa_email" {
  value = google_service_account.workflow_sa.email
}

output "workflow_sa_id" {
  value = google_service_account.workflow_sa.id
}

output "workflow_id" {
  value = google_workflows_workflow.workflow.id
}

output "workflow_project_id" {
  value = google_workflows_workflow.workflow.project
}