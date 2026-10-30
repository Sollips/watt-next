output "datalake_bucket_name" {
  description = "Name of the data lake bucket"
  value       = aws_s3_bucket.datalake.bucket
}

output "datalake_bucket_arn" {
  description = "ARN of the data lake bucket (used in IAM policies)"
  value       = aws_s3_bucket.datalake.arn
}

output "athena_results_bucket" {
  description = "Name of the Athena results bucket"
  value       = aws_s3_bucket.athena.bucket
}

output "ingest_role_arn" {
  description = "ARN of the ingestion Lambda's execution role"
  value       = aws_iam_role.ingest.arn
}

output "ingest_function_name" {
  description = "Name of the ingest function"
  value       = aws_lambda_function.ingest.function_name
}