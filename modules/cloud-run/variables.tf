variable "name" {
  type        = string
  description = "Name of the Cloud Run service"
}

variable "description" {
  type        = string
  description = "Description for the Cloud Run service"
  default     = null
}

variable "project" {
  type        = string
  description = "GCP project the service is deployed into"
}

variable "location" {
  type        = string
  description = "Region the service is deployed to. Always passed in from the root `region` variable so the service and anything invoking it agree."
}

variable "image" {
  type        = string
  description = "Fully qualified container image, including tag or digest."
}

variable "secret_ids" {
  type        = map(string)
  description = "Map of secret name to secret id, from the secrets module"
}

variable "port" {
  type        = number
  description = "Port your container listens on. Cloud Run also passes this as the PORT env var."
  default     = 8080
  nullable    = false
}

variable "cpu" {
  type        = string
  description = "CPU limit, e.g. \"1\" or \"2\". Values below 1 cap max_instances and disallow cpu_idle = false."
  default     = "1"
  nullable    = false
}

variable "memory" {
  type        = string
  description = "Memory limit, e.g. 512Mi or 1Gi"
  default     = "512Mi"
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]+(Mi|Gi|M|G)$", var.memory))
    error_message = "memory must be a number followed by Mi, Gi, M or G, e.g. 512Mi or 1Gi."
  }
}

variable "cpu_idle" {
  type        = bool
  description = "true bills CPU only while a request is in flight. Set false if your container does work after returning a response."
  default     = true
  nullable    = false
}

variable "concurrency" {
  type        = number
  description = "Requests one instance handles at once. 1 makes each instance single-threaded, like a Cloud Function."
  default     = 80
  nullable    = false

  validation {
    condition     = var.concurrency >= 1 && var.concurrency <= 1000
    error_message = "concurrency must be between 1 and 1000."
  }
}

variable "min_instances" {
  type        = number
  description = "Warm instances. 0 scales to zero (cheapest, cold starts)."
  default     = 0
  nullable    = false
}

variable "max_instances" {
  type        = number
  description = "Maximum concurrent instances. Bounds the blast radius of a traffic spike on your bill."
  default     = 10
  nullable    = false

  validation {
    condition     = var.max_instances > 0
    error_message = "max_instances must be at least 1."
  }
}

variable "request_timeout" {
  type        = number
  description = "Seconds a request may run before Cloud Run kills it (max 3600)."
  default     = 300
  nullable    = false

  validation {
    condition     = var.request_timeout > 0 && var.request_timeout <= 3600
    error_message = "request_timeout must be between 1 and 3600 seconds."
  }
}

variable "execution_environment" {
  type        = string
  description = "EXECUTION_ENVIRONMENT_GEN2 (full Linux, faster CPU, slower cold start) or EXECUTION_ENVIRONMENT_GEN1."
  default     = "EXECUTION_ENVIRONMENT_GEN2"
  nullable    = false

  validation {
    condition     = contains(["EXECUTION_ENVIRONMENT_GEN1", "EXECUTION_ENVIRONMENT_GEN2"], var.execution_environment)
    error_message = "execution_environment must be EXECUTION_ENVIRONMENT_GEN1 or EXECUTION_ENVIRONMENT_GEN2."
  }
}

variable "ingress" {
  type        = string
  description = "Who can reach the service's URL. Network reachability only -- callers still need roles/run.invoker unless allow_unauthenticated is set."
  default     = "INGRESS_TRAFFIC_ALL"
  nullable    = false

  validation {
    condition     = contains(["INGRESS_TRAFFIC_ALL", "INGRESS_TRAFFIC_INTERNAL_ONLY", "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"], var.ingress)
    error_message = "ingress must be INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY or INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER."
  }
}

variable "allow_unauthenticated" {
  type        = bool
  description = "Grant allUsers the invoker role, making the service callable by anyone on the internet with no credentials."
  default     = false
  nullable    = false
}

variable "deletion_protection" {
  type        = bool
  description = "Refuse to delete the service. Turn off deliberately before removing a service from Terraform."
  default     = true
  nullable    = false
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment variables available to the container"
  default     = {}
  nullable    = false
}

variable "secret_environment_variables" {
  description = "Secrets to expose as environment variables"
  type = list(object({
    key     = string
    secret  = string
    version = string
  }))
  default = []
}

variable "owner" {
  type        = string
  description = "The owner of the project, used for tagging resources and future ownership tracking"
}
