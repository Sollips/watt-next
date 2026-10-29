# Deny ANY request to the state bucket that isn't over HTTPS
data "aws_iam_policy_document" "tfstate_tls_only" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.tfstate.arn,        # the bucket itself (ListBucket, etc.)
      "${aws_s3_bucket.tfstate.arn}/*", # every object in it (GetObject, PutObject…)
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

resource "aws_s3_bucket_policy" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  policy = data.aws_iam_policy_document.tfstate_tls_only.json
}