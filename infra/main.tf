# Data lake: raw grid data, the source of truth — versioned, never force-destroyed
module "datalake" {
  source             = "../modules/secure_bucket"
  bucket_prefix      = "watt-next-datalake-"
  force_destroy      = false # explicit on purpose: precious data
  versioning_enabled = true
  tags               = { DataClassification = "public" }
}