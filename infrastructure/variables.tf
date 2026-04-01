
variable "project_id" {
  type        = string
  description = "project id for deployment"
}

variable "project_num" {
  type        = string
  description = "project number for deployment"
}
variable "project" {
  type        = string
  description = "project for deployment"
}

variable "region" {
  type        = string
  description = "region for deployment"
}

variable "deploy_sa_email" {
  type        = string
  description = "service account for deployment"
  default     = null
}

variable "owner" {
  type        = string
  description = "The owner of the project, used for tagging resources and future ownership tracking"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository in format 'owner/repo' that is allowed to authenticate via workload identity"
}
