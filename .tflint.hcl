# .tflint.hcl: shared by every Terraform folder in the repo
plugin "terraform" {
  enabled = true
  preset  = "recommended"   # unused declarations, missing version pins, naming…
}

plugin "aws" {
  enabled = true
  version = "0.50.0"        # pinned; verify the latest on the ruleset's releases page
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}