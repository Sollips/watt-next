# Buckets that must refuse non-HTTPS requests. Keys are names WE choose (known at plan time).
locals {
  tls_only_buckets = {
    datalake = aws_s3_bucket.datalake
  }
}

data "aws_iam_policy_document" "tls_only" {
  for_each = local.tls_only_buckets # one policy document per bucket

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [each.value.arn, "${each.value.arn}/*"] # each.value = that bucket

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

resource "aws_s3_bucket_policy" "tls_only" {
  for_each = local.tls_only_buckets

  bucket = each.value.id
  policy = data.aws_iam_policy_document.tls_only[each.key].json # the matching document, by key
}