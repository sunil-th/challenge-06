# # Make a security group if none provided
# resource "aws_vpc" "default" {
#   cidr_block = "10.0.0.0/16"
#   tags = { Name = "ci-vpc" }
# }

# resource "aws_subnet" "default" {
#   vpc_id            = aws_vpc.default.id
#   cidr_block        = "10.0.1.0/24"
#   availability_zone = "${var.aws_region}a"
#   tags = { Name = "ci-subnet" }
# }

# resource "aws_internet_gateway" "gw" {
#   vpc_id = aws_vpc.default.id
# }

# resource "aws_route_table" "r" {
#   vpc_id = aws_vpc.default.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.gw.id
#   }
# }

# resource "aws_route_table_association" "r_assoc" {
#   subnet_id      = aws_subnet.default.id
#   route_table_id = aws_route_table.r.id
# }

# resource "aws_security_group" "allow_ssh_http_netdata" {
#   name   = "ci-sg"
#   vpc_id = aws_vpc.default.id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "SSH"
#   }

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "HTTP"
#   }

#   ingress {
#     from_port   = 19999
#     to_port     = 19999
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Netdata"
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = { Name = "ci-sg" }
# }

# # Key pair created from public key passed in variable
# resource "aws_key_pair" "ci_key" {
#   key_name   = "ci_key_${random_id.rnd.hex}"
#   public_key = var.public_key
# }

# resource "random_id" "rnd" {
#   byte_length = 4
# }

# # AMI lookup - Amazon Linux 2 and Ubuntu 21.04 (by name pattern)
# data "aws_ami" "amazon_linux" {
#   most_recent = true
#   owners      = ["amazon"]
#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }
# }




# data "aws_ami" "ubuntu_2104" {
#   most_recent = true
#   owners      = ["099720109477"] # Canonical
#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
#   }
# }



# resource "aws_instance" "c8" {
#   ami                    = data.aws_ami.amazon_linux.id
#   instance_type          = var.instance_type
#   subnet_id              = aws_subnet.default.id
#   key_name               = aws_key_pair.ci_key.key_name
#   vpc_security_group_ids = [aws_security_group.allow_ssh_http_netdata.id]
#    associate_public_ip_address = true   # ✅ this enables public IP
#   tags = {
#     Name     = "c8.local"
#     Hostname = "c8.local"
#   }

#   user_data = <<-EOF
#               #!/bin/bash
#               hostnamectl set-hostname c8.local
#               EOF
# }

# resource "aws_instance" "u21" {
#   ami                    = data.aws_ami.ubuntu_2104.id
#   instance_type          = var.instance_type
#   subnet_id              = aws_subnet.default.id
#   key_name               = aws_key_pair.ci_key.key_name
#   vpc_security_group_ids = [aws_security_group.allow_ssh_http_netdata.id]
#    associate_public_ip_address = true   # ✅ add this
#   tags = {
#     Name     = "u21.local"
#     Hostname = "u21.local"
#   }

#   user_data = <<-EOF
#               #!/bin/bash
#               hostnamectl set-hostname u21.local
#               EOF
# }

# # outputs
# output "c8_public_ip" {
#   value = aws_instance.c8.public_ip
# }

# output "c8_private_ip" {
#   value = aws_instance.c8.private_ip
# }

# output "u21_public_ip" {
#   value = aws_instance.u21.public_ip
# }

# output "u21_private_ip" {
#   value = aws_instance.u21.private_ip
# }

# output "ssh_private_key_path_for_ci" {
#   value = aws_key_pair.ci_key.key_name
#   description = "Key name used in AWS - CI keeps private key locally (generated in CI)."
# }




# Use default VPC
data "aws_vpc" "default" {
  default = true
}

# Use default subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Use default security group of the default VPC
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}

# Key pair created from public key passed in variable
resource "aws_key_pair" "ci_key" {
  key_name   = "ci_key_${random_id.rnd.hex}"
  public_key = var.public_key
}

resource "random_id" "rnd" {
  byte_length = 4
}

# AMI lookup - Amazon Linux 2 and Ubuntu 22.04
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_ami" "ubuntu_2104" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
}

# Launch instances in default subnet and default security group
resource "aws_instance" "c8" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]  # pick the first default subnet
  key_name               = aws_key_pair.ci_key.key_name
  vpc_security_group_ids = [data.aws_security_group.default.id]
  associate_public_ip_address = true

  tags = {
    Name     = "c8.local"
    Hostname = "c8.local"
  }

  user_data = <<-EOF
              #!/bin/bash
              hostnamectl set-hostname c8.local
              EOF
}

resource "aws_instance" "u21" {
  ami                    = data.aws_ami.ubuntu_2104.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]  # pick the first default subnet
  key_name               = aws_key_pair.ci_key.key_name
  vpc_security_group_ids = [data.aws_security_group.default.id]
  associate_public_ip_address = true

  tags = {
    Name     = "u21.local"
    Hostname = "u21.local"
  }

  user_data = <<-EOF
              #!/bin/bash
              hostnamectl set-hostname u21.local
              EOF
}

# Outputs
output "c8_public_ip" {
  value = aws_instance.c8.public_ip
}

output "c8_private_ip" {
  value = aws_instance.c8.private_ip
}

output "u21_public_ip" {
  value = aws_instance.u21.public_ip
}

output "u21_private_ip" {
  value = aws_instance.u21.private_ip
}

output "ssh_private_key_path_for_ci" {
  value       = aws_key_pair.ci_key.key_name
  description = "Key name used in AWS - CI keeps private key locally (generated in CI)."
}



