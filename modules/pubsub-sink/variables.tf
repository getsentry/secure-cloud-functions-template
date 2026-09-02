variable "sink_name" {
  type        = string
  description = "Name of the sink. The bucket is created as <project>-<sink_name> so it is unique in the global GCS namespace."
}

variable "topic_name" {
  type        = string
  description = "Topic whose messages are exported to the bucket"
}

variable "bucket_location" {
  type        = string
  description = "GCP bucket location"
}

variable "project" {
  type        = string
  description = "GCP project ID"
}

variable "project_num" {
  type        = string
  description = "GCP project number, used to build the Pub/Sub service agent email"
}

variable "retention_days" {
  type        = number
  description = "Days before exported message files are deleted from the bucket. Set high enough for your retention obligations -- this silently deletes data."
  default     = 30
  nullable    = false

  validation {
    condition     = var.retention_days > 0
    error_message = "retention_days must be at least 1. Omit the lifecycle rule instead if you want to keep data forever."
  }
}

variable "message_retention_duration" {
  type        = string
  description = "How long Pub/Sub keeps unexported messages"
  default     = "604800s" # 7 days, the maximum
  nullable    = false
}

variable "filename_prefix" {
  type        = string
  description = "Prefix for exported object names"
  default     = "messages-"
  nullable    = false
}

variable "max_duration" {
  type        = string
  description = "Maximum time Pub/Sub batches messages before writing a file. Lower means fresher data and more, smaller objects."
  default     = "300s"
  nullable    = false
}

variable "max_bytes" {
  type        = number
  description = "Maximum size of an exported file before Pub/Sub starts a new one"
  default     = 10485760 # 10 MiB
  nullable    = false
}

variable "owner" {
  type        = string
  description = "The owner of the project, used for tagging resources and future ownership tracking"
}
