provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_instance" "example" {
  ami = "ami-088b486f20fab3f0e"
  instance_type = "t2.micro"

  tags = {
    Name = "shiozawa-exaple"
  }
}