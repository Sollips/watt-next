# State bucket → secure_bucket module (Checkpoint 3)
moved {
  from = aws_s3_bucket.tfstate
  to   = module.tfstate.aws_s3_bucket.this
}
moved {
  from = aws_s3_bucket_policy.tfstate
  to   = module.tfstate.aws_s3_bucket_policy.this
}
moved {
  from = aws_s3_bucket_public_access_block.tfstate
  to   = module.tfstate.aws_s3_bucket_public_access_block.this
}
moved {
  from = aws_s3_bucket_server_side_encryption_configuration.tfstate
  to   = module.tfstate.aws_s3_bucket_server_side_encryption_configuration.this
}
moved {
  from = aws_s3_bucket_versioning.tfstate
  to   = module.tfstate.aws_s3_bucket_versioning.this[0] # careful: the count switch
}