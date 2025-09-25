# generate an SSH key pair locally (private in a file)
resource "tls_private_key" "ansible_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_key_pair" "ansible" {
  key_name   = "ci-ansible-key-${random_id.suffix.hex}"
  public_key = tls_private_key.ansible_key.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.ansible_key.private_key_pem
  filename        = "${path.module}/ansible_key.pem"
  file_permission = "0600"
}

# default VPC/subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# Frontend SG (allow SSH, HTTP)
resource "aws_security_group" "frontend_sg" {
  name        = "frontend-sg-${random_id.suffix.hex}"
  description = "frontend sg"
  vpc_id      = data.aws_vpc.default.id

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

# Backend SG (allow SSH, allow 19999 from frontend SG)
resource "aws_security_group" "backend_sg" {
  name        = "backend-sg-${random_id.suffix.hex}"
  description = "backend sg"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 19999
    to_port         = 19999
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
    description     = "allow netdata from frontend"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# AMI lookups
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_ami" "ubuntu2104" {
  most_recent = true
  owners      = ["099720109477"] # Canonical owner
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-kinetic-21.04-amd64-server-*"]
  }
}

locals {
  ubuntu_ami = length(var.ubuntu_ami_id) > 0 ? var.ubuntu_ami_id : data.aws_ami.ubuntu2104.id
}

# Instance: c8.local (Amazon Linux)
resource "aws_instance" "c8" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ansible.key_name
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  subnet_id              = data.aws_subnet_ids.default.ids[0]
  tags = { Name = "c8.local" }

  user_data = <<-EOF
              #!/bin/bash
              hostnamectl set-hostname c8.local
              EOF
}

# Instance: u21.local (Ubuntu 21.04)
resource "aws_instance" "u21" {
  ami                    = local.ubuntu_ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ansible.key_name
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  subnet_id              = data.aws_subnet_ids.default.ids[0]
  tags = { Name = "u21.local" }

  user_data = <<-EOF
              #!/bin/bash
              hostnamectl set-hostname u21.local
              EOF
}
