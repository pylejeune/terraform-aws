provider "aws" {
  region = "eu-west-3"
}

provider "aws" {
    alias = "us-east-1"
    region = "us-east-1"
}


resource "aws_s3_bucket" "bucket_myst2" {
  bucket = "myst2"
}

resource "aws_s3_bucket" "bucket_replication-test12" {
  bucket = "replication-test12"
  force_destroy = true
}

resource "null_resource" "empty_bucket_replication-test12" {
  provisioner "local-exec" {
    command = "aws s3 rm s3://replication-test12 --recursive --region eu-west-3"
  }
}

resource "aws_s3_bucket" "bucket_replucation-test-b" {
  bucket = "replucation-test-b"  
  force_destroy = true
}


resource "aws_s3_bucket" "bucket_elasticbeanstalk-us-east-1-155701083344" {
  bucket = "elasticbeanstalk-us-east-1-155701083344"
  provider = aws.us-east-1
}

resource "aws_s3_bucket" "bucket_speetch" {
  bucket = "speetch"
  provider = aws.us-east-1
}