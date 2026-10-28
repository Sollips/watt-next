provider "aws" {
  region = "eu-west-3"
  # No `profile` here on purpose: credentials come from the chain (AWS_PROFILE locally, OIDC in CI).

  default_tags { # applied to every taggable resource this provider creates
    tags = {
      Project     = "watt-next"
      Environment = "dev"
      ManagedBy   = "terraform"
      Repository  = "Sollips/watt-next"
    }
  }
}