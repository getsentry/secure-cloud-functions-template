variable "project" {
  type        = string
  description = "GCP project the function is deployed into"
}

variable "staging_bucket" {
  type        = string
  description = "Bucket that the zipped source is uploaded to. Passed in from the infrastructure module rather than rebuilt from the project name, so there is a real dependency edge on the bucket existing."
}

variable "secret_ids" {
  type        = map(string)
  description = "Map of secret name to secret id, from the secrets module"
}

variable "name" {
  type        = string
  description = "Name of the cloud function"
}

variable "description" {
  type        = string
  description = "Description for the cloud function"
  default     = null
}

variable "source_dir" {
  type        = string
  description = "Directory containing source code, relative or absolute (relative preferred, think about CI/CD!)"
}

variable "location" {
  type        = string
  description = "Region this cloud function is deployed to. Always passed in from the root `region` variable -- do not rely on a default here, or the function and the resources that invoke it can end up in different regions."
}

variable "runtime" {
  type        = string
  description = "Function runtime, default python 3.11"
  default     = "python311"
  nullable    = false
}

variable "source_object_prefix" {
  type        = string
  description = "String prefixing source upload objects"
  default     = "src-"
}

variable "function_entrypoint" {
  type        = string
  description = "Entrypoint function on cloud function trigger"
  nullable    = false
  default     = "main"
}

variable "execution_timeout" {
  type        = number
  description = "Amount of time function can execute before timing out, in seconds"
  default     = 60
  nullable    = false

  validation {
    condition     = var.execution_timeout > 0 && var.execution_timeout <= 3600
    error_message = "execution_timeout must be between 1 and 3600 seconds."
  }
}

variable "available_memory" {
  type        = string
  description = "Amount of memory assigned to each execution"
  default     = "256M"
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]+(M|Mi|G|Gi)$", var.available_memory))
    error_message = "available_memory must be a number followed by M, Mi, G or Gi, e.g. 256M or 1Gi."
  }
}

variable "min_instances" {
  type        = number
  description = "Minimum warm instances. 0 means scale to zero (cheapest, cold starts)."
  default     = 0
  nullable    = false
}

variable "max_instances" {
  type        = number
  description = "Maximum concurrent instances. Bounds the blast radius of a runaway loop or a traffic spike on your bill."
  default     = 10
  nullable    = false

  validation {
    condition     = var.max_instances > 0
    error_message = "max_instances must be at least 1."
  }
}

variable "temp_zip_output_dir" {
  type        = string
  description = "Dir path where temporary archive will be written"
  default     = "/tmp"
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment variables available to the function"
  default     = {}
  nullable    = false
}

variable "secret_environment_variables" {
  description = "list of secrets to mount as env vars"
  type = list(object({
    key     = string
    secret  = string
    version = string
  }))

  default = []
}

variable "ingress_settings" {
  description = "Who can reach the function's endpoint. ALLOW_ALL, ALLOW_INTERNAL_ONLY, or ALLOW_INTERNAL_AND_GCLB. Note this is network reachability only -- callers still need roles/cloudfunctions.invoker unless allow_unauthenticated is set."
  type        = string
  default     = "ALLOW_ALL"
  nullable    = false

  validation {
    condition     = contains(["ALLOW_ALL", "ALLOW_INTERNAL_ONLY", "ALLOW_INTERNAL_AND_GCLB"], var.ingress_settings)
    error_message = "ingress_settings must be one of ALLOW_ALL, ALLOW_INTERNAL_ONLY, ALLOW_INTERNAL_AND_GCLB."
  }
}

variable "files_to_exclude" {
  description = "Files in the function directory that should not be shipped in the deployment archive"
  type        = list(string)
  default = [
    "terraform.yaml",
    "main.tf",
    "README.md",
    "readme.md",
    ".DS_Store",
  ]
}

variable "allow_unauthenticated" {
  type        = bool
  description = "Grant allUsers the invoker role, making the function callable by anyone on the internet with no credentials. Only for public webhook receivers that do their own request verification."
  nullable    = false
  default     = false
}

variable "owner" {
  type        = string
  description = "The owner of the project, used for tagging resources and future ownership tracking"
}
