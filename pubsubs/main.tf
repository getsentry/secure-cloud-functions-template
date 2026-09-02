# Every subdirectory of pubsubs/ containing a terraform.yaml becomes a Pub/Sub
# topic and subscription, optionally with a GCS archive sink. See README.md.

variable "project" {}
variable "project_num" {}
variable "region" {}
variable "bucket_location" {}
variable "owner" {}

locals {
  terraform_files = fileset(path.module, "*/terraform.yaml")

  configs = {
    for f in local.terraform_files :
    dirname(f) => yamldecode(file("${path.module}/${f}"))
  }

  allowed_top_keys    = ["name", "description", "pubsub", "sink"]
  allowed_pubsub_keys = ["topic_name", "subscription_id", "service_account_id", "service_account_display_name", "ttl"]
  allowed_sink_keys   = ["sink_name", "retention_days", "max_duration", "max_bytes", "filename_prefix"]

  required_pubsub_keys = ["topic_name", "subscription_id", "service_account_id", "service_account_display_name"]

  pubsubs = { for d, c in local.configs : d => c if contains(keys(c), "pubsub") }
  sinks   = { for d, c in local.configs : d => c if contains(keys(c), "sink") }
}

resource "terraform_data" "config_validation" {
  for_each = local.configs
  input    = each.key

  lifecycle {
    precondition {
      condition     = contains(keys(each.value), "name")
      error_message = "pubsubs/${each.key}/terraform.yaml is missing the required `name` key."
    }

    precondition {
      condition     = try(each.value["name"], each.key) == each.key
      error_message = "pubsubs/${each.key}/terraform.yaml has name '${try(each.value["name"], "")}' but lives in directory '${each.key}'. They must match."
    }

    precondition {
      condition     = contains(keys(each.value), "pubsub")
      error_message = "pubsubs/${each.key}/terraform.yaml is missing the required `pubsub` block. A sink needs a topic to archive."
    }

    precondition {
      condition     = length(setsubtract(keys(each.value), local.allowed_top_keys)) == 0
      error_message = "pubsubs/${each.key}/terraform.yaml has unknown top-level key(s): ${join(", ", setsubtract(keys(each.value), local.allowed_top_keys))}. Valid keys: ${join(", ", local.allowed_top_keys)}."
    }

    precondition {
      condition     = length(setsubtract(keys(try(each.value["pubsub"], {})), local.allowed_pubsub_keys)) == 0
      error_message = "pubsubs/${each.key}/terraform.yaml has unknown key(s) under pubsub: ${join(", ", setsubtract(keys(try(each.value["pubsub"], {})), local.allowed_pubsub_keys))}. Valid keys: ${join(", ", local.allowed_pubsub_keys)}."
    }

    precondition {
      condition     = length(setsubtract(local.required_pubsub_keys, keys(try(each.value["pubsub"], {})))) == 0
      error_message = "pubsubs/${each.key}/terraform.yaml is missing required key(s) under pubsub: ${join(", ", setsubtract(local.required_pubsub_keys, keys(try(each.value["pubsub"], {}))))}."
    }

    precondition {
      condition     = !contains(keys(each.value), "sink") || length(setsubtract(keys(try(each.value["sink"], {})), local.allowed_sink_keys)) == 0
      error_message = "pubsubs/${each.key}/terraform.yaml has unknown key(s) under sink: ${join(", ", setsubtract(keys(try(each.value["sink"], {})), local.allowed_sink_keys))}. Valid keys: ${join(", ", local.allowed_sink_keys)}."
    }

    precondition {
      condition     = !contains(keys(each.value), "sink") || try(each.value["sink"]["sink_name"], null) != null
      error_message = "pubsubs/${each.key}/terraform.yaml has a `sink` block with no `sink_name`."
    }
  }
}

module "pubsubs" {
  source   = "../modules/pubsub"
  for_each = local.pubsubs

  topic_name                   = each.value["pubsub"]["topic_name"]
  subscription_id              = each.value["pubsub"]["subscription_id"]
  service_account_id           = each.value["pubsub"]["service_account_id"]
  service_account_display_name = each.value["pubsub"]["service_account_display_name"]
  ttl                          = try(each.value["pubsub"]["ttl"], null)

  gcp_region = var.region
  owner      = var.owner

  depends_on = [terraform_data.config_validation]
}

module "pubsubs_sink" {
  source   = "../modules/pubsub-sink"
  for_each = local.sinks

  sink_name       = each.value["sink"]["sink_name"]
  topic_name      = module.pubsubs[each.key].pubsub_topic_name
  retention_days  = try(each.value["sink"]["retention_days"], null)
  max_duration    = try(each.value["sink"]["max_duration"], null)
  max_bytes       = try(each.value["sink"]["max_bytes"], null)
  filename_prefix = try(each.value["sink"]["filename_prefix"], null)

  project         = var.project
  project_num     = var.project_num
  bucket_location = var.bucket_location
  owner           = var.owner
}
