# Project-wide roles for the privileged "apply" service account.
locals {
  roles = [
    "roles/viewer",                         # general read-only access to most Google Cloud resources
    "roles/storage.admin",                  # full access to manage GCS buckets and objects
    "roles/cloudfunctions.developer",       # deploy and manage Cloud Functions
    "roles/logging.viewer",                 # view logs
    "roles/iam.workloadIdentityPoolViewer", # view workload identity pool
    "roles/iam.serviceAccountCreator",      # create service accounts
    "roles/pubsub.admin",                   # full access to Pub/Sub
    # NOTE: roles/iam.serviceAccountUser is intentionally NOT granted at the
    # project level. Project-wide serviceAccountUser is actAs over EVERY service
    # account in the project (a privilege-escalation primitive). actAs on the
    # per-resource runtime SAs is granted narrowly inside each module instead.
    # NOTE: roles/secretmanager.secretAccessor is intentionally NOT granted.
    # Deploying/binding secrets does not require reading their values; the
    # custom role below grants create + setIamPolicy without value access.
  ]
}

resource "google_project_iam_member" "project_roles" {
  for_each = toset(local.roles)
  project  = var.project
  role     = each.value
  member   = "serviceAccount:${local.apply_sa_email}"
}

# Custom role letting the apply SA create and manage Secret Manager secrets and
# their IAM bindings WITHOUT the ability to read secret payloads. This replaces
# the previous project-wide roles/secretmanager.secretAccessor grant so that a
# compromised CI run cannot exfiltrate secret values.
resource "google_project_iam_custom_role" "tf_secret_manager" {
  role_id     = "cfTemplateSecretManager"
  title       = "CF Template Secret Manager (no value access)"
  description = "Create and manage Secret Manager secrets and their IAM bindings without reading secret values"
  permissions = [
    "secretmanager.secrets.create",
    "secretmanager.secrets.delete",
    "secretmanager.secrets.get",
    "secretmanager.secrets.list",
    "secretmanager.secrets.update",
    "secretmanager.secrets.getIamPolicy",
    "secretmanager.secrets.setIamPolicy",
  ]
}

resource "google_project_iam_member" "apply_secret_manager" {
  project = var.project
  role    = google_project_iam_custom_role.tf_secret_manager.name
  member  = "serviceAccount:${local.apply_sa_email}"
}

# Custom role letting the apply SA set IAM bindings on service accounts (e.g.
# grant itself roles/iam.serviceAccountUser on per-resource runtime SAs) without
# project-wide serviceAccountUser or full serviceAccountAdmin.
resource "google_project_iam_custom_role" "tf_service_account_iam" {
  role_id     = "cfTemplateServiceAccountIam"
  title       = "CF Template Service Account IAM"
  description = "Set IAM bindings on service accounts without project-wide serviceAccountUser"
  permissions = [
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.setIamPolicy",
  ]
}

resource "google_project_iam_member" "apply_service_account_iam" {
  project = var.project
  role    = google_project_iam_custom_role.tf_service_account_iam.name
  member  = "serviceAccount:${local.apply_sa_email}"
}

# Read-only project access for the plan SA. roles/viewer lets `terraform plan`
# refresh resource state but does NOT include secretmanager.versions.access, so
# the plan identity cannot read secret values. (State-bucket read/lock access
# is granted on the bucket itself in main.tf.)
resource "google_project_iam_member" "plan_viewer" {
  count   = var.deploy_sa_email != null ? 0 : 1
  project = var.project
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.gha_tf_plan[0].email}"
}
