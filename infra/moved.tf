# Athena results bucket → secure_bucket module (Nugget 24)
moved {
  from = aws_s3_bucket.athena
  to   = module.athena_results.aws_s3_bucket.this
}

moved {
  from = aws_s3_bucket_policy.tls_only["athena"]
  to   = module.athena_results.aws_s3_bucket_policy.this
}

moved {
  from = aws_s3_bucket_public_access_block.athena
  to   = module.athena_results.aws_s3_bucket_public_access_block.this
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.athena
  to   = module.athena_results.aws_s3_bucket_server_side_encryption_configuration.this
}