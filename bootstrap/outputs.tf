output "tfstate_bucket_name" {
  description = "Name of the S3 bucket holding Terraform state"
  value       = module.tfstate.name
}