provider "aws" {
  region = var.aws_region
  # No `profile` here on purpose: credentials come from the chain (AWS_PROFILE locally, OIDC in CI).

  default_tags {
    tags = local.common_tags
  }
}