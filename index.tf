module "infrastructure" {
  source = "./infrastructure"

  project         = var.project
  region          = var.region
  project_id      = var.project_id
  deploy_sa_email = var.deploy_sa_email
}

module "functions" {
  source = "./functions"

  project         = var.project
  region          = var.region
  project_id      = var.project_id
  secret_ids      = module.infrastructure.secret_ids
  deploy_sa_email = var.deploy_sa_email != null ? var.deploy_sa_email : module.infrastructure.deploy_sa_email
  local_variables = local.local_variables

  depends_on = [
    module.infrastructure
  ]
}

module "workflows" {
  source = "./workflows"

  project         = var.project
  region          = var.region
  project_id      = var.project_id
  deploy_sa_email = var.deploy_sa_email != null ? var.deploy_sa_email : module.infrastructure.deploy_sa_email

  depends_on = [
    module.infrastructure
  ]
}

module "pubsubs" {
  source = "./pubsubs"

  project         = var.project
  region          = var.region
  project_id      = var.project_id
  bucket_location = var.bucket_location
  zone            = var.zone
  deploy_sa_email = var.deploy_sa_email != null ? var.deploy_sa_email : module.infrastructure.deploy_sa_email

  depends_on = [
    module.infrastructure
  ]
}
