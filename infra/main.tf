# Data lake: raw grid data, the source of truth — versioned, never force-destroyed
module "datalake" {
  source             = "../modules/secure_bucket"
  bucket_prefix      = "watt-next-datalake-"
  force_destroy      = false # explicit on purpose: precious data
  versioning_enabled = true
  tags               = { DataClassification = "public" }
}

# Housekeeping: versioning keeps old versions forever → expire them after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "datalake" {
  bucket = module.datalake.name # the data lake's NAME (a module output)

  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    filter {} # empty filter = the whole bucket

    noncurrent_version_expiration {
      noncurrent_days = 30 # deleted/overwritten versions recoverable for 30 days, then gone
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7 # clean up failed large uploads
    }
    # NO "expiration" block here: current raw data must never expire
  }

  lifecycle {
    precondition {
      condition     = module.datalake.versioning_enabled # true only if the data lake is versioned (a module output)
      error_message = "The noncurrent-version rule needs a versioned bucket: set versioning_enabled = true on module.datalake."
    }
  }
}