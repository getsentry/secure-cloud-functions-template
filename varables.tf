variable "project" {
  type        = string
  description = "The GCP project ID"
}

variable "region" {
  type        = string
  description = "The GCP region"
}

variable "zone" {
  type        = string
  description = "The GCP zone"
}

variable "project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "project_num" {
  type        = string
  description = "The GCP project number"
}

variable "bucket_location" {
  type        = string
  description = "The location for GCS bucket"
}

variable "alerts_collection" {
  type        = string
  description = "The name of the alerts collection"
}

variable "tf_state_bucket" {
  type        = string
  description = "The name of the tfstate bucket"
}

variable "deploy_sa_email" {
  type        = string
  description = "service account for deployment"
  default     = null
}
