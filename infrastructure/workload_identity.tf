locals {
  gha_name        = "gha-terraform-checker"
  attribute_scope = "repository"
}

resource "google_service_account" "gha_cloud_functions_deployment" {
  count = var.deploy_sa_email != null ? 0 : 1

  account_id   = "gha-cloud-functions-deployment"
  description  = "For use by Terraform and GitHub Actions to deploy cloud-functions, owned by ${var.owner}, managed by Terraform"
  display_name = "gha-cloud-functions-deployment"
  project      = var.project
}

resource "google_iam_workload_identity_pool" "gha_terraform_checker_pool" {
  count = var.deploy_sa_email != null ? 0 : 1

  workload_identity_pool_id = "${local.gha_name}-pool"
  display_name              = "GHA Terraform Checker Pool"
  description               = "Identity pool for Terraform Plan GHA, owned by ${var.owner}, managed by Terraform"
}

resource "google_iam_workload_identity_pool_provider" "gha_terraform_checker_provider" {
  count = var.deploy_sa_email != null ? 0 : 1

  workload_identity_pool_id          = google_iam_workload_identity_pool.gha_terraform_checker_pool[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "${local.gha_name}-provider"
  display_name                       = "GHA Terraform Checker Provider"
  description                        = "OIDC identity pool provider for Terraform Plan GHA, owned by ${var.owner}, managed by Terraform"

  attribute_mapping = {
    "google.subject"       = "assertion.${local.attribute_scope}"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "gha_workload_identity_user" {
  count = var.deploy_sa_email != null ? 0 : 1

  service_account_id = google_service_account.gha_cloud_functions_deployment[0].id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.gha_terraform_checker_pool[0].name}/*"
}

