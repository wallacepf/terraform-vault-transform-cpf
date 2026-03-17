terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "vault" {}

# O provider AWS só é utilizado quando create_rds = true.
provider "aws" {
  region = var.aws_region
}
