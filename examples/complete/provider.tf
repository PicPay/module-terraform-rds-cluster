provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  profile = "picpay-lab"
}

terraform {
  backend "s3" {
    bucket = "035267315123-terraform-state"
    key =  "module-terraform-rds-cluster/terraform.tfstate"
    profile = "picpay-lab"
    region = "us-east-1"
  }
}