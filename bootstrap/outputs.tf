output "tfstate_bucket_name" {
  description = "Name of the S3 bucket holding Terraform state"
  value       = module.tfstate.name
}

output "ci_plan_role_arn" {
  description = "Role GitHub Actions assumes to run terraform plan on pull requests (goes in the workflow)"
  value       = aws_iam_role.ci_plan.arn
}

output "ci_apply_role_arn" {
  description = "Role GitHub Actions assumes to apply, from the protected production environment"
  value       = aws_iam_role.ci_apply.arn
}