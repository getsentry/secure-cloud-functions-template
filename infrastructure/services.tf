# APIs this template needs enabled. No import needed -- enabling is idempotent.
#
# On a brand-new project these take a few minutes to propagate, so the first
# `terraform apply` often fails partway through. Re-run it.
locals {
  services = [
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudapis.googleapis.com",
    "cloudasset.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudtrace.googleapis.com",
    "compute.googleapis.com",
    "containerregistry.googleapis.com",
    "datastore.googleapis.com",
    "eventarc.googleapis.com",
    "firebaserules.googleapis.com",
    "firestore.googleapis.com",
    "firestorekeyvisualizer.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "iap.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "oslogin.googleapis.com",
    "pubsub.googleapis.com",
    "pubsublite.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "servicemanagement.googleapis.com",
    "serviceusage.googleapis.com",
    "sql-component.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "vpcaccess.googleapis.com",
    "workflowexecutions.googleapis.com",
    "workflows.googleapis.com",
  ]
}

resource "google_project_service" "services" {
  for_each = toset(local.services)
  service  = each.value

  # The default (true) means a `terraform destroy`, or just deleting an entry
  # above, disables the API project-wide and breaks anything else using it.
  disable_on_destroy = false
}
