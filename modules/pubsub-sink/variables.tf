variable "sink_name" {
  type        = string
  description = "Pub/Sub topic name"
}

variable "bucket_location" {
  type        = string
  description = "GCP bucket location"
}

variable "project_id" {
  type        = string
  description = "GCP Project name"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
}
