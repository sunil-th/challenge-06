locals {
  ssh_key_name_prefix = "ci-key"
  sg_name_prefix      = "ci-default-sg"
}

# Unique suffix to avoid collisions in CI
resource "random_string" "suffix" {
  length  = 6
  upper   = false
   numeric  = true
  special = false
}

# Generate SSH keypair locally and upload public key to AWS
resource "tls_private_key" "ci_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ci" {
  key_name   = "${local.ssh_key_name_prefix}-${random_string.suffix.result}"
  public_key = tls_private_key.ci_key.public_key_openssh
}

# Use default VPC and its subnets
data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Lookup the default security group of that VPC
data "aws_security_group" "default" {
  filter {
    name   = "group-name"
    values = ["default"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Add ingress rules into the default security group (SSH, HTTP, Netdata)
resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_allowed_cidrs
  security_group_id = data.aws_security_group.default.id
}

resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.default.id
}

resource "aws_security_group_rule" "allow_netdata" {
  type              = "ingress"
  from_port         = 19999
  to_port           = 19999
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.default.id
}

# AMI lookups (if you passed ami_* variables they will override)
data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# data "aws_ami" "ubuntu_2104" {
#   most_recent = true
#   owners      = ["099720109477"] # Canonical
#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-*-21.04-amd64-server-*"]
#   }
# }


data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}



# Instance: Amazon Linux (c8.local)
resource "aws_instance" "c8" {
  ami                    = length(var.ami_c8) > 0 ? var.ami_c8 : data.aws_ami.amazon_linux2.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ci.key_name
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [data.aws_security_group.default.id]
  associate_public_ip_address = true

  tags = {
    Name = "c8.local"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -eux
              hostnamectl set-hostname c8.local
              # Bootstrap python3 so Ansible can run normally
              yum -y update
              yum -y install python3
              # Ensure python3 path exists
              ln -sfn /usr/bin/python3 /usr/bin/python3 || true
              EOF
}

# Instance: Ubuntu 21.04 (u21.local)
resource "aws_instance" "u21" {
  ami                    = length(var.ami_u21) > 0 ? var.ami_u21 : data.aws_ami.ubuntu_2204.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ci.key_name
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [data.aws_security_group.default.id]
  associate_public_ip_address = true

  tags = {
    Name = "u21.local"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -eux
              hostnamectl set-hostname u21.local
              apt-get update -y
              apt-get install -y python3 python3-apt
              ln -sfn /usr/bin/python3 /usr/bin/python3 || true
              EOF
}

# Generate Ansible inventory (dynamic)
resource "local_file" "ansible_inventory" {
  depends_on = [aws_instance.c8, aws_instance.u21]
  filename   = "${path.module}/../ansible/inventory.ini"
  content    = templatefile("${path.module}/templates/ansible_inventory.tpl", {
    c8_ip  = aws_instance.c8.public_ip,
    u21_ip = aws_instance.u21.public_ip
  })
}
