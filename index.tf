module "infrastructure" {
  source = "./infrastructure"

  project    = local.project
  region     = local.region
  project_id = local.project_id
}

module "functions" {
  source = "./functions"

  project         = local.project
  region          = local.region
  project_id      = local.project_id
  secret_ids      = module.infrastructure.secret_ids
  deploy_sa_email = module.infrastructure.deploy_sa_email

  depends_on = [
    module.infrastructure
  ]
}

module "workflows" {
  source = "./workflows"

  project         = local.project
  region          = local.region
  project_id      = local.project_id
  deploy_sa_email = module.infrastructure.deploy_sa_email

  depends_on = [
    module.infrastructure
  ]
}
