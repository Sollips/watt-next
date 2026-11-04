# A private, encrypted bucket that refuses non-HTTPS requests.
resource "aws_s3_bucket" "this" {
  bucket_prefix = var.bucket_prefix
  force_destroy = var.force_destroy
  tags          = var.tags
  lifecycle {
    prevent_destroy = true # Terraform refuses any plan that would destroy a bucket made by this module
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Optional: the on/off switch
resource "aws_s3_bucket_versioning" "this" {
  count  = var.versioning_enabled ? 1 : 0 # which variable switches versioning on?
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ONE policy: the caller's extra statements + the TLS-only Deny, always
data "aws_iam_policy_document" "this" {
  source_policy_documents = var.additional_policy_documents # merged in first

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json

  # Hidden dependency: S3 rejects concurrent changes to public-access settings and policies
  depends_on = [aws_s3_bucket_public_access_block.this]
}