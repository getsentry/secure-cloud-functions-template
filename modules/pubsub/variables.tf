variable "topic_name" {
  type        = string
  description = "Pub/Sub topic name"
}

variable "subscription_id" {
  type        = string
  description = "Pub/Sub subscription name"
}

variable "gcp_region" {
  type        = string
  description = "Region messages are allowed to be persisted in"
}

variable "service_account_id" {
  type        = string
  description = "Service account id for the subscriber"
}

variable "service_account_display_name" {
  type        = string
  description = "Service account display name"
}

variable "ttl" {
  type        = string
  description = "Subscription expiration policy: how long the subscription may sit idle before Pub/Sub deletes it. A duration string in seconds, e.g. \"604800s\" for 7 days. Null means never expire."
  default     = null

  validation {
    condition     = var.ttl == null || can(regex("^[0-9]+s$", var.ttl))
    error_message = "ttl must be a duration string in seconds, e.g. \"604800s\" for 7 days. A bare number like 7 is not valid."
  }
}

variable "owner" {
  type        = string
  description = "The owner of the project, used for tagging resources and future ownership tracking"
}
