module "infrastructure" {
  source = "./infrastructure"

  project           = var.project
  project_num       = var.project_num
  region            = var.region
  bucket_location   = var.bucket_location
  deploy_sa_email   = var.deploy_sa_email
  github_repository = var.github_repository
  owner             = var.owner
}

module "secrets" {
  source = "./secrets"

  secrets = var.secrets
  owner   = var.owner

  depends_on = [
    module.infrastructure
  ]
}

module "functions" {
  source = "./functions"

  project         = var.project
  region          = var.region
  staging_bucket  = module.infrastructure.staging_bucket_name
  secret_ids      = module.secrets.secret_ids
  local_variables = local.local_variables
  owner           = var.owner

  depends_on = [
    module.infrastructure
  ]
}

module "workflows" {
  source = "./workflows"

  project = var.project
  region  = var.region
  owner   = var.owner

  depends_on = [
    module.infrastructure,
    module.functions
  ]
}

module "pubsubs" {
  source = "./pubsubs"

  project         = var.project
  project_num     = var.project_num
  region          = var.region
  bucket_location = var.bucket_location
  owner           = var.owner

  depends_on = [
    module.infrastructure
  ]
}

locals {
  apply_sa_email = var.deploy_sa_email != null ? var.deploy_sa_email : module.infrastructure.deploy_sa_email
}
