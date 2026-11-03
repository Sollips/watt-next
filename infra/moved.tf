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

# datalake bucket → secure_bucket module

moved {
  from = aws_s3_bucket.datalake
  to   = module.datalake.aws_s3_bucket.this
}

moved {
  from = aws_s3_bucket_public_access_block.datalake
  to   = module.datalake.aws_s3_bucket_public_access_block.this
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.datalake
  to   = module.datalake.aws_s3_bucket_server_side_encryption_configuration.this
}

# data lake: versioning → the count switch's instance [0]
moved {
  from = aws_s3_bucket_versioning.datalake
  to   = module.datalake.aws_s3_bucket_versioning.this[0]
}

# data lake: policy → its old address was the for_each instance
moved {
  from = aws_s3_bucket_policy.tls_only["datalake"]
  to   = module.datalake.aws_s3_bucket_policy.this
}

# site bucket → secure_bucket module

moved {
  from = aws_s3_bucket.site
  to   = module.site.aws_s3_bucket.this
}

moved {
  from = aws_s3_bucket_public_access_block.site
  to   = module.site.aws_s3_bucket_public_access_block.this
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.site
  to   = module.site.aws_s3_bucket_server_side_encryption_configuration.this
}

# site: the old two-statement policy → the module's merged policy
moved {
  from = aws_s3_bucket_policy.site
  to   = module.site.aws_s3_bucket_policy.this
}