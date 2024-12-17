resource "aws_instance" "nginx-server" {
  count         = 2
  ami           = "ami-0453ec754f44f9a4a"
  instance_type = "t2.micro"

  tags = {
    Name        = "Upb-Nginx-${count.index}"
    Environment = "test"
    Owner       = "jhosiasmauricio@gmail.com"
    Team        = "DevOps"
    Project     = "webinar"
  }

  user_data = <<-EOF
              #!/bin/bash
              # Install Nginx
              sudo yum install -y nginx
              sudo systemctl enable nginx
              sudo systemctl start nginx
              EOF

  vpc_security_group_ids = [aws_security_group.nginx-server.id]
}

resource "aws_security_group" "nginx-server" {
  name        = "nginx-server"
  description = "Security group allowing SSH and HTTP access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

resource "aws_elb" "nginx-elb" {
  name               = "nginx-elb"
  availability_zones = ["us-east-1a", "us-east-1b"]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  instances = aws_instance.nginx-server[*].id

  tags = {
    Name = "nginx-elb"
  }
}
