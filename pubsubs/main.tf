# load the folders under `pubsub` and locate the terraform.yaml files
locals {
  terraform_files   = fileset(path.module, "*/terraform.yaml")
  terraform_configs = [for f in local.terraform_files : yamldecode(file("${path.module}/${f}"))]
}

variable "project_id" {}
variable "project" {}
variable "region" {}
variable "deploy_sa_email" {}

module "pubsubs" {
  source   = "../modules/pubsub"
  for_each = { for config in local.terraform_configs : config.name => config if contains(keys(config), "pubsub") }

  project_id      = var.project_id
  topic_name      = each.value.pubsub.topic_name
  subscription_id = each.value.pubsub.subscription_id
  gcp_region      = var.region
}

module "pubsubs_sink" {
  source   = "../modules/pubsub-sink"
  for_each = { for config in local.terraform_configs : config.name => config if contains(keys(config), "sink") }

  project_id      = var.project_id
  topic_name      = each.value.pubsub.topic_name
  subscription_id = each.value.pubsub.subscription_id
  gcp_region      = var.region
}
