output "datalake_bucket_name" {
  description = "Name of the data lake bucket"
  value       = aws_s3_bucket.datalake.bucket
}