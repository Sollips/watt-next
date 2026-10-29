# Deny ANY request to the datalake bucket that isn't over HTTPS
data "aws_iam_policy_document" "datalake_tls_only" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.datalake.arn,        # the bucket itself (ListBucket, etc.)
      "${aws_s3_bucket.datalake.arn}/*", # every object in it (GetObject, PutObject…)
    ]

    principals {
      type        = "*"
      identifiers = ["*"] # everyone, admins included
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"] # i.e. the request did NOT use TLS
    }
  }
}

resource "aws_s3_bucket_policy" "datalake" {
  bucket = aws_s3_bucket.datalake.id
  policy = data.aws_iam_policy_document.datalake_tls_only.json
}

# Deny ANY request to the athena bucket that isn't over HTTPS
data "aws_iam_policy_document" "athena_tls_only" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.athena.arn,        # the bucket itself (ListBucket, etc.)
      "${aws_s3_bucket.athena.arn}/*", # every object in it (GetObject, PutObject…)
    ]

    principals {
      type        = "*"
      identifiers = ["*"] # everyone, admins included
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"] # i.e. the request did NOT use TLS
    }
  }
}

resource "aws_s3_bucket_policy" "athena" {
  bucket = aws_s3_bucket.athena.id
  policy = data.aws_iam_policy_document.athena_tls_only.json
}