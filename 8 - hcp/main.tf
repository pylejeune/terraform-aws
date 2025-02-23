terraform {
  cloud {
    organization = "pylejeune"
    workspaces {
      name = "terraform-hcp"
    }
  }
}


provider "aws" {
  region = "eu-west-3"
}


resource "aws_s3_bucket" "hcp_terraform" {
  bucket = "hcp_terraform"
}
