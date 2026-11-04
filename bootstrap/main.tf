module "tfstate" {
  source             = "../modules/secure_bucket" # same relative path as from infra/
  bucket_prefix      = "watt-next-tfstate-"
  versioning_enabled = true
  force_destroy      = false # explicit: Terraform's memory must never be force-deleted
}