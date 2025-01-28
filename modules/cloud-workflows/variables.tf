variable "name" {
  type        = string
  description = "Name of the cloud workflow"
}

variable "description" {
  type        = string
  description = "Description for the cloud workflow"
  default     = null
}

variable "workflow_yaml_file" {
  type        = string
  description = "Path to the yaml to deploy as a workflow"
}

variable "functions" {
  type        = set(string)
  description = "List of functions to be called in the workflow"
}

variable "deploy_sa_email" {
  type        = string
  description = "Service account used for CD in GitHub actions"
  # TODO: Remove hardcoded account once deployment SA moved to terraform
  default = "gha-cloud-functions-deployment@sec-dnr-infra.iam.gserviceaccount.com"
}

variable "project" {
  type = string
}
variable "project_id" {
  type = string
}
variable "region" {
  type = string
}
