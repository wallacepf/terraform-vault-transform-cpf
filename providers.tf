terraform {
  required_version = ">= 1.14.0"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "vault" {}

# O provider AWS só é utilizado quando create_rds = true.
provider "aws" {
  region = var.aws_region
}
