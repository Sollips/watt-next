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

variable "ingest_schedule" {
  description = "How often the ingestion Lambda runs (EventBridge Scheduler expression)"
  type        = string
  default     = "rate(15 minutes)" # ~2,900 API calls/month, under RTE's 50,000 quota
}