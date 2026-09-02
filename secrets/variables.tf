variable "secrets" {
  type        = list(string)
  description = "Names of the Secret Manager secrets to create. Values are added out of band -- see readme.md."
  default     = []
  nullable    = false
}

variable "owner" {
  type        = string
  description = "The owner of the project, used for tagging resources and future ownership tracking"
}
