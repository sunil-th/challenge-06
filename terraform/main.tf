# # Use default VPC
# data "aws_vpc" "default" {
#   default = true
# }

# data "aws_subnets" "default" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.default.id]
#   }
# }

# # Default security group of default VPC
# data "aws_security_group" "default" {
#   filter {
#     name   = "group-name"
#     values = ["default"]
#   }
#   vpc_id = data.aws_vpc.default.id
# }

# # Amazon Linux VM
# resource "aws_instance" "c8" {
#   ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2 (us-east-1)
#   instance_type          = var.instance_type
#   subnet_id              = data.aws_subnets.default.ids[0]
#   vpc_security_group_ids = [data.aws_security_group.default.id]
#   key_name               = var.key_name

#   tags = {
#     Name = "c8.local"
#   }
# }

# # Ubuntu 21.04 VM (may need 20.04/22.04 if 21.04 is unavailable)
# resource "aws_instance" "u21" {
#   ami                    = "ami-08c40ec9ead489470" # Ubuntu 21.04 (us-east-1, check availability)
#   instance_type          = var.instance_type
#   subnet_id              = data.aws_subnets.default.ids[1]
#   vpc_security_group_ids = [data.aws_security_group.default.id]
#   key_name               = var.key_name

#   tags = {
#     Name = "u21.local"
#   }
# }

# # Generate dynamic Ansible inventory
# resource "local_file" "inventory" {
#   filename = "${path.module}/../ansible/inventory.ini"
#   content = templatefile("${path.module}/inventory.tpl", {
#     c8_ip  = aws_instance.c8.public_ip
#     u21_ip = aws_instance.u21.public_ip
#   })
# }





terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.4"
}



# --- Generate SSH key pair ---
resource "tls_private_key" "ci_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ci" {
  key_name   = "ci-key"
  public_key = tls_private_key.ci_key.public_key_openssh
}

# --- Get default VPC ---
data "aws_vpc" "default" {
  default = true
}

# --- Get default subnet (first one) ---
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- Security group: allow SSH, HTTP ---
resource "aws_security_group" "ci_sg" {
  name   = "ci-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

# --- Amazon Linux instance ---
resource "aws_instance" "c8" {
  ami           = "ami-0c2b8ca1dad447f8a" # Amazon Linux 2 AMI (us-east-1, update if region differs)
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ci.key_name
  subnet_id     = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.ci_sg.id]

  tags = {
    Name = "c8.local"
  }
}

# --- Ubuntu 21.04 instance ---
resource "aws_instance" "u21" {
  ami           = "ami-04b70fa74e45c3917" # Ubuntu Server 21.04 (check for your region!)
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ci.key_name
  subnet_id     = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.ci_sg.id]

  tags = {
    Name = "u21.local"
  }
}

# --- Inventory file for Ansible ---
resource "local_file" "ansible_inventory" {
  content = <<EOT
[frontend]
c8.local ansible_host=${aws_instance.c8.public_ip} ansible_user=ec2-user

[backend]
u21.local ansible_host=${aws_instance.u21.public_ip} ansible_user=ubuntu
EOT

  filename = "${path.module}/../ansible/inventory.ini"
}

# --- Outputs ---
output "c8_public_ip" {
  value = aws_instance.c8.public_ip
}

output "u21_public_ip" {
  value = aws_instance.u21.public_ip
}

output "private_key_pem" {
  value     = tls_private_key.ci_key.private_key_pem
  sensitive = true
}

