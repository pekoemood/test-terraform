provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_db_instance" "mysql" {
  identifier_prefix   = "terraform-up-and-running"
  engine              = "mysql"
  allocated_storage   = 20
  instance_class      = "db.t3.micro"
  skip_final_snapshot = true
  db_name             = "mysql_database"
  username            = var.db_username
  password            = var.db_password
}

terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-state"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "ap-northeast-1"

    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }

}