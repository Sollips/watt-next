resource "aws_s3_bucket" "datalake" {
  # bucket_prefix → Terraform appends a unique suffix: no global-name collision, no account ID in code
  bucket_prefix = "watt-next-datalake-"
}

# Belt and braces: all four public-access blocks ON
resource "aws_s3_bucket_public_access_block" "datalake" {
  bucket                  = aws_s3_bucket.datalake.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Explicit encryption. AWS encrypts by default, but declaring intent makes it reviewable and lintable
resource "aws_s3_bucket_server_side_encryption_configuration" "datalake" {
  bucket = aws_s3_bucket.datalake.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # SSE-S3: free. Design decision vs SSE-KMS → README
    }
  }
}

# Versioning: protects against accidental overwrite/delete (lifecycle cleanup in Nugget 26)
resource "aws_s3_bucket_versioning" "datalake" {
  bucket = aws_s3_bucket.datalake.id
  versioning_configuration {
    status = "Enabled"
  }
}