# load the folders under `workflows` and locate the terraform.yaml files
locals {
  terraform_files   = fileset(path.module, "*/terraform.yaml")
  terraform_configs = [for f in local.terraform_files : yamldecode(file("${path.module}/${f}"))]
}

variable "project_id" {}
variable "project" {}
variable "region" {}

module "workflows" {
  source   = "../modules/cloud-workflows"
  for_each = { for config in local.terraform_configs : config.name => config}

  name = each.value.name
  description = each.value.description
  functions = toset(each.value.functions)
  workflow_yaml_file = "${path.module}/${each.value.name}/workflow.yaml"
  # passing the static values
  project = var.project
  project_id = var.project_id
  region = var.region
}
