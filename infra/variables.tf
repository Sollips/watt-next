variable "aws_region" {
  description = "AWS region for all watt-next resources"
  type        = string
  default     = "eu-west-3"
}

variable "environment" {
  description = "Deployment environment, used in tags (and later in names)"
  type        = string
  # No default on purpose: every run must state which environment it targets.

  validation {
    condition     = contains(["dev", "prod"], var.environment) # contains(list, value) → true/false
    error_message = "environment must be \"dev\" or \"prod\"."
  }
}