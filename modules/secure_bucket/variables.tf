variable "bucket_prefix" {
  description = "Prefix for the bucket name; AWS appends a unique suffix"
  type        = string
}

variable "force_destroy" {
  description = "Allow destroy even when the bucket contains objects (only for disposable data)"
  type        = bool
  default     = false # safe by default
}

variable "versioning_enabled" {
  description = "Keep previous versions of objects (for data that can't easily be regenerated)"
  type        = bool
  default     = false
}

variable "additional_policy_documents" {
  description = "Extra IAM policy JSON documents merged into the bucket policy (e.g. CloudFront read access)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Bucket-specific tags, merged with the provider's default_tags"
  type        = map(string)
  default     = {}
}