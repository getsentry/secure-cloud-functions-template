variable "name" {
  type        = string
  description = "Name of the cronjob trigger"
}

variable "description" {
  type        = string
  description = "Description of the cronjob trigger"
  default     = null
}

variable "schedule" {
  type        = string
  description = "Schedule in cron format (* * * * *)"
  nullable    = false

  validation {
    condition     = length(regexall("\\S+", var.schedule)) == 5
    error_message = "schedule must be a 5-field cron expression, e.g. \"0 * * * *\" for hourly. Quote it in YAML so it isn't parsed as something else."
  }
}

variable "time_zone" {
  type        = string
  description = "Time zone for schedule, default Etc/UTC"
  default     = "Etc/UTC"
  nullable    = false
}

variable "target_project" {
  type        = string
  description = "Function's project"
}

variable "target_region" {
  type        = string
  description = "Function's region. Must match the region the function was deployed to."
}

variable "target_function_name" {
  type        = string
  description = "Function name"
}

variable "https_trigger_url" {
  type        = string
  description = "URL of the cloud function to trigger"
}

variable "http_method" {
  type        = string
  description = "HTTP method for the call to make, default GET"
  default     = "GET"
  nullable    = false

  validation {
    condition     = contains(["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"], upper(var.http_method))
    error_message = "http_method must be a valid HTTP method."
  }
}

variable "attempt_deadline" {
  type        = string
  description = "Deadline for the function to return before job fail, max 1800s or 30m"
  default     = "320s"
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]+(s|m|h)$", var.attempt_deadline))
    error_message = "attempt_deadline must be a duration string like 320s or 5m."
  }
}

variable "owner" {
  type        = string
  description = "The owner of the project, used for tagging resources and future ownership tracking"
}
