# `sbin/bootstrap` reads these to rewrite .github/workflows/*.yaml, so no
# identifier has to be hand-copied.

output "workload_identity_provider" {
  description = "Value for `workload_identity_provider` in both GitHub Actions workflows. Null in BYO mode."
  value       = module.infrastructure.workload_identity_provider
}

output "apply_service_account" {
  description = "Value for `service_account` in .github/workflows/terraform-apply.yaml."
  value       = local.apply_sa_email
}

output "plan_service_account" {
  description = "Value for `service_account` in .github/workflows/terraform-plan.yaml. Null in BYO mode -- bring your own read-only account."
  value       = module.infrastructure.plan_sa_email
}

output "state_bucket" {
  description = "Terraform state bucket. Must match the `bucket` in the backend block in main.tf."
  value       = module.infrastructure.state_bucket_name
}

output "staging_bucket" {
  description = "Bucket that Cloud Function source archives are uploaded to."
  value       = module.infrastructure.staging_bucket_name
}
