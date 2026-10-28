terraform {
  backend "s3" {
    bucket       = "watt-next-tfstate-312ed0895b5791b105bba3b716" # LITERAL: backend blocks can't use variables or references
    key          = "watt-next/dev/infra.tfstate" # one key per environment/component
    region       = "eu-west-3"
    encrypt      = true # SSE on the state object
    use_lockfile = true # native S3 locking — no DynamoDB
  }
}