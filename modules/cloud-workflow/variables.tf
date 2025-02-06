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
  default     = []
}

variable "bucket" {
  type        = set(string)
  description = "List of buckets to be watched for events"
  default     = []
}

variable "workflow" {
  type        = set(string)
  description = "List of workflows to be called in the workflow"
  default     = []
}

variable "deploy_sa_email" {
  type        = string
  description = "Service account used for CD in GitHub actions"
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
