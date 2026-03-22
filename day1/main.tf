provider "aws" {
  region = "ap-northeast-1"
}

# resource "aws_instance" "example" {
#   ami                    = "ami-088b486f20fab3f0e"
#   instance_type          = "t2.micro"
#   vpc_security_group_ids = [aws_security_group.secgp.id]

#   user_data = <<-EOF
#     #!/bin/bash
#     sudo dnf install -y httpd
#     echo "Hello, World" > /var/www/html/index.html
#     sudo systemctl start httpd
#   EOF

#   user_data_replace_on_change = true

#   tags = {
#     Name = "shiozawa-exaple"
#   }
# }

resource "aws_security_group" "secgp" {
  name = "terraform-shiozawa-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "server_port" {
  description = "port番号"
  type        = number
  default     = 80
}

# output "public_ip" {
#   value       = aws_instance.example.public_ip
#   description = "webサーバーのpublic IPアドレス"
# }

resource "aws_launch_template" "shio_aws_launch" {
  image_id               = "ami-088b486f20fab3f0e"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.secgp.id]

  user_data = base64encode(
    <<-EOF
    #!/bin/bash
    sudo dnf install -y httpd
    echo "こんにちは！塩澤さん！！" > /var/www/html/index.html
    sudo systemctl start httpd
  EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "scaling_shiozawa" {
  launch_template {
    id      = aws_launch_template.shio_aws_launch.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  # launch_configuration = aws_launch_template.shio_aws_launch.name
  vpc_zone_identifier = data.aws_subnets.default.ids
  min_size            = 4
  max_size            = 10

  tag {
    key                 = "Name"
    value               = "teraform-asg-shiozawa"
    propagate_at_launch = true
  }
}

data "aws_vpc" "default" {
  //　引数は検索フィルターのイメージ
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_lb" "shio_lb" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.shio_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404:page not found"
      status_code  = 404
    }
  }
}

resource "aws_security_group" "alb_sg" {
  name = "terraform-example-alb"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

output "alb_dns_name" {
  value       = aws_lb.shio_lb.dns_name
  description = "albのDNS名を返す"
}