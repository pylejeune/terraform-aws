provider "aws" {
  region = "eu-west-1"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "mon-premier-bucket-terraform-123456"
}