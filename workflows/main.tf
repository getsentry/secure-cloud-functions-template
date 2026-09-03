# Every subdirectory of workflows/ containing a terraform.yaml becomes a Cloud
# Workflow. Nothing else needs editing to add one -- see README.md.

variable "project" {}
variable "region" {}
variable "owner" {}

locals {
  terraform_files = fileset(path.module, "*/terraform.yaml")

  configs = {
    for f in local.terraform_files :
    dirname(f) => yamldecode(file("${path.module}/${f}"))
  }

  allowed_top_keys     = ["name", "description", "functions", "bucket", "workflow", "workflow-trigger"]
  allowed_trigger_keys = ["criteria"]

  triggers = { for d, c in local.configs : d => c if contains(keys(c), "workflow-trigger") }
}

resource "terraform_data" "config_validation" {
  for_each = local.configs
  input    = each.key

  lifecycle {
    precondition {
      condition     = contains(keys(each.value), "name")
      error_message = "workflows/${each.key}/terraform.yaml is missing the required `name` key."
    }

    precondition {
      condition     = try(each.value["name"], each.key) == each.key
      error_message = "workflows/${each.key}/terraform.yaml has name '${try(each.value["name"], "")}' but lives in directory '${each.key}'. They must match."
    }

    precondition {
      condition     = fileexists("${path.module}/${each.key}/workflow.yaml")
      error_message = "workflows/${each.key}/workflow.yaml does not exist. Every workflow directory needs both terraform.yaml (the Terraform config) and workflow.yaml (the workflow definition itself)."
    }

    precondition {
      condition     = length(setsubtract(keys(each.value), local.allowed_top_keys)) == 0
      error_message = "workflows/${each.key}/terraform.yaml has unknown top-level key(s): ${join(", ", setsubtract(keys(each.value), local.allowed_top_keys))}. Valid keys: ${join(", ", local.allowed_top_keys)}."
    }

    precondition {
      condition     = !contains(keys(each.value), "workflow-trigger") || length(setsubtract(keys(try(each.value["workflow-trigger"], {})), local.allowed_trigger_keys)) == 0
      error_message = "workflows/${each.key}/terraform.yaml has unknown key(s) under workflow-trigger: ${join(", ", setsubtract(keys(try(each.value["workflow-trigger"], {})), local.allowed_trigger_keys))}. Valid keys: ${join(", ", local.allowed_trigger_keys)}."
    }
  }
}

module "workflows" {
  source   = "../modules/cloud-workflow"
  for_each = local.configs

  name               = each.key
  description        = try(each.value["description"], null)
  functions          = toset(try(each.value["functions"], []))
  bucket             = toset(try(each.value["bucket"], []))
  workflow           = toset(try(each.value["workflow"], []))
  workflow_yaml_file = "${path.module}/${each.key}/workflow.yaml"

  project = var.project
  region  = var.region
  owner   = var.owner

  depends_on = [terraform_data.config_validation]
}

module "workflows-ingest-trigger" {
  source   = "../modules/eventarc-workflow-trigger"
  for_each = local.triggers

  name                = "${each.key}-trigger"
  location            = var.region
  workflow_project_id = var.project
  workflow_id         = module.workflows[each.key].workflow_id
  criteria            = each.value["workflow-trigger"]["criteria"]
  owner               = var.owner
}
