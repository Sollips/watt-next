terraform {
  required_version = "~> 1.16" # any 1.x from 1.16 up

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # any 6.x, never 7.x
    }
  }
}