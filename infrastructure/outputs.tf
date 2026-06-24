output "deploy_sa_email" {
  description = "Privileged service account used by `terraform apply`."
  value       = local.apply_sa_email
}

output "plan_sa_email" {
  description = "Read-only service account used by `terraform plan` (null in BYO mode)."
  value       = var.deploy_sa_email != null ? null : google_service_account.gha_tf_plan[0].email
}
