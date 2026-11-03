terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0" # a module states its MINIMUM; the root config pins the exact version
    }
  }
}