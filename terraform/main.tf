# Use default VPC
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Default security group of default VPC
data "aws_security_group" "default" {
  filter {
    name   = "group-name"
    values = ["default"]
  }
  vpc_id = data.aws_vpc.default.id
}

# Amazon Linux VM
resource "aws_instance" "c8" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2 (us-east-1)
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [data.aws_security_group.default.id]
  key_name               = var.key_name

  tags = {
    Name = "c8.local"
  }
}

# Ubuntu 21.04 VM (may need 20.04/22.04 if 21.04 is unavailable)
resource "aws_instance" "u21" {
  ami                    = "ami-08c40ec9ead489470" # Ubuntu 21.04 (us-east-1, check availability)
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[1]
  vpc_security_group_ids = [data.aws_security_group.default.id]
  key_name               = var.key_name

  tags = {
    Name = "u21.local"
  }
}

# Generate dynamic Ansible inventory
resource "local_file" "inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content = templatefile("${path.module}/inventory.tpl", {
    c8_ip  = aws_instance.c8.public_ip
    u21_ip = aws_instance.u21.public_ip
  })
}
