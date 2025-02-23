provider "aws" {
  region = "eu-west-1"
}


resource "aws_s3_bucket" "my_bucket_1" {
  bucket = "bucket-terraform-1-py"
}

resource "aws_s3_bucket" "my_bucket_2" {
  bucket = "bucket-terraform-2-py"
}

resource "aws_s3_bucket" "my_bucket_3" {
  bucket = "ajout-py"
}