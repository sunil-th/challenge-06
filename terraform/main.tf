# --- Generate SSH Key Pair ---
resource "tls_private_key" "ci_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ci" {
  key_name   = "ci-key"
  public_key = tls_private_key.ci_key.public_key_openssh
}

# --- Default VPC & Subnets ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- Security Group ---
resource "aws_security_group" "ci_sg" {
  name   = "ci-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Netdata"
    from_port   = 19999
    to_port     = 19999
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

# --- Amazon Linux Instance ---
resource "aws_instance" "c8" {
  ami           = var.ami_c8
  instance_type = var.instance_type
  key_name      = aws_key_pair.ci.key_name
  subnet_id     = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.ci_sg.id]

  tags = {
    Name = "c8.local"
  }
}

# --- Ubuntu 21.04 Instance ---
resource "aws_instance" "u21" {
  ami           = var.ami_u21
  instance_type = var.instance_type
  key_name      = aws_key_pair.ci.key_name
  subnet_id     = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.ci_sg.id]

  tags = {
    Name = "u21.local"
  }
}

# --- Dynamic Ansible Inventory ---
resource "local_file" "ansible_inventory" {
  content = <<EOT
[frontend]
c8.local ansible_host=${aws_instance.c8.public_ip} ansible_user=ec2-user

[backend]
u21.local ansible_host=${aws_instance.u21.public_ip} ansible_user=ubuntu
EOT

  filename = "${path.module}/../ansible/inventory.ini"
}
