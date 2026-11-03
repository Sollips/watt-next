output "datalake_bucket_name" {
  description = "Name of the data lake bucket"
  value       = module.datalake.name
}

output "datalake_bucket_arn" {
  description = "ARN of the data lake bucket (used in IAM policies)"
  value       = module.datalake.arn
}

output "athena_results_bucket_name" {
  description = "Name of the Athena results bucket"
  value       = module.athena_results.name
}

output "ingest_role_arn" {
  description = "ARN of the ingestion Lambda's execution role"
  value       = aws_iam_role.ingest.arn
}

output "ingest_function_name" {
  description = "Name of the ingest function"
  value       = aws_lambda_function.ingest.function_name
}

output "alerts_topic_arn" {
  description = "ARN of the Alerts SNS topic"
  value       = aws_sns_topic.alerts.arn
}

output "athena_workgroup_name" {
  description = "Workgroup to select in the Athena console (enforces results location and a 100 MB scan limit)"
  value       = aws_athena_workgroup.watt.name
}

output "glue_database_name" {
  description = "Database to select in the Athena query editor; contains the eco2mix table"
  value       = aws_glue_catalog_database.watt.name
}

output "site_url" {
  description = "Public HTTPS address of the watt-next page (share this one)"
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "site_distribution_id" {
  description = "CloudFront distribution ID, needed for cache invalidations"
  value       = aws_cloudfront_distribution.site.id
}