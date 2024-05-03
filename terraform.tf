terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }

  backend "s3" {
    bucket = "statedata-1313"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}