provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_instance" "shio_instance" {
  ami = "ami-088b486f20fab3f0e"
  instance_type = "t2.micro"
}

terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-state"
    key = "workspace-shio/terraform.tfstate"
    region = "ap-northeast-1"

    dynamodb_table = "terraform-up-and-running-locks"
    encrypt = true
  }
}