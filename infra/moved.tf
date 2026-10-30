moved {
  from = aws_s3_bucket_policy.datalake
  to   = aws_s3_bucket_policy.tls_only["datalake"]
}

moved {
  from = aws_s3_bucket_policy.athena
  to   = aws_s3_bucket_policy.tls_only["athena"]
}