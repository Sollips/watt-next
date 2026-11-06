module "tfstate" {
  source             = "../modules/secure_bucket" # same relative path as from infra/
  bucket_prefix      = "watt-next-tfstate-"
  versioning_enabled = true
  force_destroy      = false # explicit: Terraform's memory must never be force-deleted
}

resource "aws_s3_bucket_lifecycle_configuration" "tfstate" {
  bucket = module.tfstate.name

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"
    filter {} # empty filter = the whole bucket

    noncurrent_version_expiration {
      noncurrent_days           = 90 # old versions older than 90 days…
      newer_noncurrent_versions = 10 # …expire, but the 10 most recent are always kept (rollback)
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}