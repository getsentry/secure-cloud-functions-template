variable "topic_name" {
  type        = string
  description = "Pub/Sub topic name"
}

variable "subscription_id" {
  type        = string
  description = "Pub/Sub subscription id"
}

variable "project_id" {
  type        = string
  description = "GCP Project name"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
}
