output "name" {
  description = "Bucket name: for API calls and environment variables"
  value       = aws_s3_bucket.this.bucket # which attribute holds the full generated name?
}

output "arn" {
  description = "Bucket ARN: for IAM policies"
  value       = aws_s3_bucket.this.arn
}

output "regional_domain_name" {
  description = "Regional domain name: for network connections (CloudFront origin)"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}