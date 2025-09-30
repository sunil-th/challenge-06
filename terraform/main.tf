# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 5.0"
#     }
#     tls = {
#       source  = "hashicorp/tls"
#       version = "~> 4.0"
#     }
#   }

#   required_version = ">= 1.6.0"
# }

# provider "aws" {
#   region = var.aws_region
# }

# # Generate a new SSH key
# resource "tls_private_key" "ci_key" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "aws_key_pair" "generated" {
#   key_name   = "ci-key"
#   public_key = tls_private_key.ci_key.public_key_openssh
# }

# # Fetch default VPC
# data "aws_vpc" "default" {
#   default = true
# }

# # Fetch default Security Group (no modification!)
# data "aws_security_group" "default" {
#   filter {
#     name   = "group-name"
#     values = ["default"]
#   }
#   vpc_id = data.aws_vpc.default.id
# }

# # Lookup latest Amazon Linux 2 AMI
# data "aws_ami" "amazon_linux" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }
# }

# # Lookup latest Ubuntu 22.04 AMI (Canonical)
# data "aws_ami" "ubuntu" {
#   most_recent = true
#   owners      = ["099720109477"]

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
#   }
# }

# # EC2 Instances
# resource "aws_instance" "c8" {
#   ami                    = data.aws_ami.amazon_linux.id
#   instance_type          = "t2.micro"
#   key_name               = aws_key_pair.generated.key_name
#   vpc_security_group_ids = [data.aws_security_group.default.id]

#   tags = {
#     Name = "c8.local"
#   }
# }

# resource "aws_instance" "u21" {
#   ami                    = data.aws_ami.ubuntu.id
#   instance_type          = "t2.micro"
#   key_name               = aws_key_pair.generated.key_name
#   vpc_security_group_ids = [data.aws_security_group.default.id]

#   tags = {
#     Name = "u21.local"
#   }
# }

# # Outputs
# output "c8_public_ip" {
#   value = aws_instance.c8.public_ip
# }

# output "u21_public_ip" {
#   value = aws_instance.u21.public_ip
# }

# output "private_key_pem" {
#   value     = tls_private_key.ci_key.private_key_pem
#   sensitive = true
# }






# Generate a new SSH key
resource "tls_private_key" "ci_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated" {
  key_name   = "ci-key"
  public_key = tls_private_key.ci_key.public_key_openssh
}

# Fetch default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch default Security Group (no modification)
data "aws_security_group" "default" {
  filter {
    name   = "group-name"
    values = ["default"]
  }
  vpc_id = data.aws_vpc.default.id
}

# Lookup latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Lookup latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# EC2: Amazon Linux (frontend)
resource "aws_instance" "c8" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.generated.key_name
  vpc_security_group_ids = [data.aws_security_group.default.id]

  tags = {
    Name = "c8.local"
  }
}

# EC2: Ubuntu (backend)
resource "aws_instance" "u21" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.generated.key_name
  vpc_security_group_ids = [data.aws_security_group.default.id]

  tags = {
    Name = "u21.local"
  }
}
