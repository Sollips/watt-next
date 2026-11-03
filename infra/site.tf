# ── Public page: private bucket (warehouse) behind CloudFront (shop) ──────────
locals {
  site_origin_id = "site-bucket" # a name WE choose, used to link origin and cache behavior
}

# Site: rebuilt from Git, so force_destroy is safe; CloudFront access is added to the module's policy
module "site" {
  source                      = "../modules/secure_bucket"
  bucket_prefix               = "watt-next-site-"
  force_destroy               = true
  additional_policy_documents = [data.aws_iam_policy_document.site_cloudfront.json]
}

data "aws_iam_policy_document" "site_cloudfront" {
  statement {
    sid       = "AllowCloudFrontRead"
    actions   = ["s3:GetObject"]
    resources = ["${module.site.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition { # only THIS distribution (confused-deputy protection)
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn] # the distribution's ARN
    }

  }
}



# OAC: CloudFront signs its requests to S3 (replaces the legacy OAI)
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${local.name_prefix}-site"
  description                       = "CloudFront access to the private site bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# AWS-managed cache policy, looked up by name (a data source: read, never created)
data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "watt-next public page"
  default_root_object = "index.html"
  price_class         = "PriceClass_100" # cheapest: edges in Europe and North America

  origin {
    origin_id                = local.site_origin_id
    domain_name              = module.site.regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id       = local.site_origin_id # must match the origin's id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.optimized.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # https://xxxx.cloudfront.net, no custom domain (free)
  }
}

# The page itself, uploaded from Git
resource "aws_s3_object" "index" {
  bucket        = module.site.name
  key           = "index.html"
  source        = "${path.module}/../site/index.html"
  source_hash   = filemd5("${path.module}/../site/index.html") # file changes → re-upload
  content_type  = "text/html; charset=utf-8"
  cache_control = "max-age=300" # future page edits reach visitors within 5 minutes
}