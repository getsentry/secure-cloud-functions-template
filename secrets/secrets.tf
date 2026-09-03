# Terraform creates the secret container only, never the value -- see readme.md.
resource "google_secret_manager_secret" "secret" {
  for_each  = toset(var.secrets)
  secret_id = each.value

  replication {
    auto {}
  }

  labels = {
    owner       = var.owner
    terraformed = "true"
  }

  # Deleting a secret destroys every version irreversibly, and Terraform would
  # do that the moment a name is dropped from `secrets` -- easy to do by
  # accident in a large diff.
  lifecycle {
    prevent_destroy = true
  }
}
