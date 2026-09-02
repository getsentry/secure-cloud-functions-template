output "deploy_sa_email" {
  description = "Privileged service account used by `terraform apply`."
  value       = local.apply_sa_email
}

output "plan_sa_email" {
  description = "Read-only service account used by `terraform plan` (null in BYO mode)."
  value       = var.deploy_sa_email != null ? null : google_service_account.gha_tf_plan[0].email
}

output "workload_identity_provider" {
  description = "Full resource path of the OIDC provider, for the `workload_identity_provider` input of google-github-actions/auth (null in BYO mode)."
  value = var.deploy_sa_email != null ? null : join("", [
    "projects/${var.project_num}/locations/global/workloadIdentityPools/",
    google_iam_workload_identity_pool.gha_terraform_checker_pool[0].workload_identity_pool_id,
    "/providers/${local.gha_name}-provider",
  ])
}

output "state_bucket_name" {
  description = "Terraform state bucket name."
  value       = google_storage_bucket.tf-state.name
}

output "staging_bucket_name" {
  description = "Cloud Function source staging bucket name."
  value       = google_storage_bucket.staging_bucket.name
}

output "image_registry" {
  description = "Artifact Registry path Cloud Run images are pushed to and pulled from."
  value       = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.cloud_run.repository_id}"
}
