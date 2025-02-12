resource "google_secret_manager_secret" "secret" {
  for_each  = { for s in local.secrets : s => s }
  secret_id = each.value
  replication {
    auto {}
  }
  labels = {
    owner = var.owner
    terraformed = "true"
  }
}

# since some of the secrets will be shared across functions and workflows
# we decided to place them here instead of under each functions
locals {
  secrets = [
    "test_key_1",
    "test_key_2",
    "GH_APP_ID",
    "GH_APP_INSTALLATION_ID",
    "GH_APP_PRI_KEY",
  ]
}
