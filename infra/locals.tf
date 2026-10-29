locals {
  project = "watt-next"

  # For NEW resources' names from Nugget 15 on. Existing buckets keep their names (see Lab B).
  name_prefix = "${local.project}-${var.environment}" # → "watt-next-dev"

  common_tags = {
    Project     = local.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Repository  = "Sollips/watt-next"
  }
}