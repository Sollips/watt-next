provider "aws" {
  region = var.aws_region
  # No `profile` here on purpose: credentials come from the chain (AWS_PROFILE locally, OIDC in CI).

  default_tags { # applied to every taggable resource this provider creates
    tags = {
      Project     = "watt-next"
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "Sollips/watt-next"
    }
  }
}