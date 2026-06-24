locals {
  gha_name = "gha-terraform-checker"

  # The privileged "apply" identity. When the caller brings their own service
  # account (BYO via security-as-code) we use that; otherwise we use the SA
  # this module creates below.
  apply_sa_email = var.deploy_sa_email != null ? var.deploy_sa_email : google_service_account.gha_cloud_functions_deployment[0].email
}

# Privileged service account used by `terraform apply` (runs only on push to
# main). Holds the write-capable roles defined in permissions.tf.
resource "google_service_account" "gha_cloud_functions_deployment" {
  count = var.deploy_sa_email != null ? 0 : 1

  account_id   = "gha-cloud-functions-deployment"
  description  = "Privileged SA for `terraform apply` (push to main only), owned by ${var.owner}, managed by Terraform"
  display_name = "gha-cloud-functions-deployment"
  project      = var.project
}

# Read-only service account used by `terraform plan` on pull requests. Because
# `terraform plan` executes attacker-controllable PR configuration (data
# sources / providers can run during plan), this identity must never hold
# write or secret-read permissions. See permissions.tf for its bindings.
resource "google_service_account" "gha_tf_plan" {
  count = var.deploy_sa_email != null ? 0 : 1

  account_id   = "gha-cf-tf-plan"
  description  = "Read-only SA for `terraform plan` on pull requests, owned by ${var.owner}, managed by Terraform"
  display_name = "gha-cf-tf-plan"
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
    # Map google.subject to the full GitHub subject (repo + ref/environment) so
    # it is unique per identity rather than per repository.
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # Only this repository can mint any token from this provider.
  attribute_condition = "assertion.repository == '${var.github_repository}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
    allowed_audiences = [
      "https://iam.googleapis.com/projects/${var.project_id}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.gha_terraform_checker_pool[0].workload_identity_pool_id}/providers/${local.gha_name}-provider",
      "https://iam.googleapis.com/projects/${var.project_num}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.gha_terraform_checker_pool[0].workload_identity_pool_id}/providers/${local.gha_name}-provider"
    ]
  }
}

# Apply SA can only be impersonated from the main branch of this repository.
# (The provider's attribute_condition already restricts to this repo, so
# scoping on ref here pins it to repo + refs/heads/main.)
resource "google_service_account_iam_member" "gha_apply_workload_identity_user" {
  count = var.deploy_sa_email != null ? 0 : 1

  service_account_id = google_service_account.gha_cloud_functions_deployment[0].id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.gha_terraform_checker_pool[0].name}/attribute.ref/refs/heads/main"
}

# Plan SA can be impersonated from any ref in this repository (covers PR refs
# such as refs/pull/<n>/merge). This identity is read-only.
resource "google_service_account_iam_member" "gha_plan_workload_identity_user" {
  count = var.deploy_sa_email != null ? 0 : 1

  service_account_id = google_service_account.gha_tf_plan[0].id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.gha_terraform_checker_pool[0].name}/attribute.repository/${var.github_repository}"
}
