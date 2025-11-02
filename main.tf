provider "aws" {
  region = "var.region"
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = file(var.public_key_path) # Adjust path to your public SSH key
}

resource "aws_security_group" "nginx_sg" {
  name        = "nginx-sg"
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_instance" "nginx_host" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.nginx_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              curl -O https://bootstrap.pypa.io/get-pip.py
              python3 get-pip.py
              pip3 install docker

              echo '
import docker
client = docker.from_env()
client.containers.run("nginx", detach=True, ports={"80/tcp": 80})
print("Nginx container started")
              ' > /home/ec2-user/nginx_start.py

              python3 /home/ec2-user/nginx_start.py
            EOF

  tags = {
    Name = "nginx-docker-instance"
  }
}
