variable "name" {
  type        = string
  description = "Name of the eventarc trigger"
}

variable "location" {
  type        = string
  description = "Trigger location (default us-west1)"
}

variable "workflow_project_id" {
  type        = string
  description = "Project ID for the workflow to trigger"
}

variable "workflow_id" {
  type        = string
  description = "ID for the workflow to trigger"
}

variable "deploy_sa_email" {
  type        = string
  description = "Service account used for CD in GitHub actions"
}

variable "criteria" {
  description = "list of matching criteria for the trigger"
  type = list(object({
    attribute = string
    value     = string
  }))
}

variable "owner" {
  type        = string
  description = "The owner of the project, used for tagging resources and future ownership tracking"
}
