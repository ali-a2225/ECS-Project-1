terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "6.11.0" }
    null = {source  = "hashicorp/null", version = "3.2.4"}
  }
    backend "s3" {
      bucket = "terraform-state-aws-ali"
      key    = "terraform.tfstate"
      region = "eu-west-2"
      use_lockfile = true
      encrypt = true
    }
}
provider "aws" { region = "eu-west-2"}