variable "name" {
  type        = string
  description = "Name of the Cloud Run service being scheduled. The job is created as <name>-cron."
}

variable "description" {
  type        = string
  description = "Description of the scheduled job"
  default     = null
}

variable "schedule" {
  type        = string
  description = "Schedule in cron format (* * * * *)"
  nullable    = false

  validation {
    condition     = length(split(" ", trimspace(var.schedule))) == 5
    error_message = "schedule must be a 5-field cron expression, e.g. \"0 * * * *\" for hourly. Quote it in YAML so it isn't parsed as something else."
  }
}

variable "time_zone" {
  type        = string
  description = "Time zone for the schedule"
  default     = "Etc/UTC"
  nullable    = false
}

variable "path" {
  type        = string
  description = "Path on the service to call, e.g. /tasks/nightly. Empty hits the service root."
  default     = ""
  nullable    = false

  validation {
    condition     = var.path == "" || startswith(var.path, "/")
    error_message = "path must start with a / , e.g. /tasks/nightly."
  }
}

variable "http_method" {
  type        = string
  description = "HTTP method for the scheduled call"
  default     = "POST"
  nullable    = false

  validation {
    condition     = contains(["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"], upper(var.http_method))
    error_message = "http_method must be a valid HTTP method."
  }
}

variable "attempt_deadline" {
  type        = string
  description = "Deadline for the call to return before the attempt fails, max 1800s"
  default     = "320s"
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]+(s|m|h)$", var.attempt_deadline))
    error_message = "attempt_deadline must be a duration string like 320s or 5m."
  }
}

variable "target_project" {
  type        = string
  description = "Project the target service lives in"
}

variable "target_region" {
  type        = string
  description = "Region the target service lives in"
}

variable "target_service_name" {
  type        = string
  description = "Name of the Cloud Run service to invoke"
}

variable "target_url" {
  type        = string
  description = "Root URL of the Cloud Run service to invoke"
}

variable "owner" {
  type        = string
  description = "The owner of the project, used for tagging resources and future ownership tracking"
}
