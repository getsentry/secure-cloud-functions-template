# Project-wide roles for the privileged "apply" service account.
locals {
  roles = [
    "roles/viewer",                         # general read-only access to most Google Cloud resources
    "roles/iam.securityReviewer",           # READ-ONLY *.getIamPolicy across services, so plan/apply can refresh IAM resources
    "roles/storage.admin",                  # full access to manage GCS buckets and objects
    "roles/cloudfunctions.developer",       # deploy and manage Cloud Functions
    "roles/logging.viewer",                 # view logs
    "roles/iam.workloadIdentityPoolViewer", # view workload identity pool
    "roles/iam.serviceAccountCreator",      # create the per-resource runtime service accounts
    "roles/iam.serviceAccountUser",         # actAs runtime SAs in order to deploy functions/workflows/cron as them
    "roles/pubsub.admin",                   # full access to Pub/Sub
    # NOTE on roles/iam.serviceAccountUser: this is a project-wide actAs (impersonation)
    # primitive. It is required because the template autonomously creates dedicated
    # runtime SAs and must actAs them to deploy. It CANNOT be scoped to just those SAs:
    # creating a per-SA actAs binding on a freshly-created SA itself requires
    # iam.serviceAccounts.setIamPolicy on that SA (circular), and IAM Conditions are not
    # supported for service-account resources. actAs is deliberately chosen over a custom
    # role with iam.serviceAccounts.setIamPolicy because setIamPolicy is strictly broader
    # (it can grant ANY principal actAs on ANY SA and rewrite policies). Residual risk is
    # bounded by: apply only runs on refs/heads/main behind the `production` approval gate,
    # is never exposed to untrusted PR code (that path uses the read-only plan SA), and the
    # template assumes a dedicated project. For maximum lockdown, drop this role and create
    # runtime-SA actAs bindings via a privileged bootstrap apply instead (loses CI self-service).
    # NOTE: roles/secretmanager.secretAccessor is intentionally NOT granted. Deploying/binding
    # secrets does not require reading their values; the custom role below grants
    # create + setIamPolicy on secrets without value access.
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

# Read-only project access for the plan SA. roles/viewer covers resource reads
# (gets/lists) and roles/iam.securityReviewer covers *.getIamPolicy so that
# `terraform plan` can refresh IAM resources. Neither grants
# secretmanager.versions.access, so the plan identity cannot read secret values.
# (State-bucket read + lock-object write is granted on the bucket in main.tf.)
resource "google_project_iam_member" "plan_viewer" {
  count   = var.deploy_sa_email != null ? 0 : 1
  project = var.project
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.gha_tf_plan[0].email}"
}

resource "google_project_iam_member" "plan_security_reviewer" {
  count   = var.deploy_sa_email != null ? 0 : 1
  project = var.project
  role    = "roles/iam.securityReviewer"
  member  = "serviceAccount:${google_service_account.gha_tf_plan[0].email}"
}
