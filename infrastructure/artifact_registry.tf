# Container images for Cloud Run services, built and pushed by the apply
# workflow. Cloud Run pulls from here as the project's serverless service agent,
# which already has read access to same-project repositories, so no extra grant
# is needed for the services themselves.
resource "google_artifact_registry_repository" "cloud_run" {
  location = var.region
  # The build step in .github/workflows/terraform-apply.yaml rebuilds this same
  # path from terraform.tfvars, so change both together.
  repository_id = "cloud-run"
  description   = "Cloud Run container images, owned by ${var.owner}, managed by Terraform"
  format        = "DOCKER"

  labels = {
    owner       = var.owner
    terraformed = "true"
  }

  cleanup_policies {
    id     = "keep-recent-versions"
    action = "KEEP"
    most_recent_versions {
      keep_count = var.image_versions_to_keep
    }
  }

  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"
    condition {
      tag_state  = "UNTAGGED"
      older_than = "604800s" # 7 days
    }
  }
}
