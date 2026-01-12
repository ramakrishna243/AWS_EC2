terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # CloudShell inherits your console region automatically.
  # If you want to pin a region, uncomment the next line:
  # region = "us-west-2"
}
