# variable "instance_type" {
#   default = "t2.micro"
# }

# variable "key_name" {
#   description = "SSH key pair name"
#   default     = "rock"
# }




variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region to deploy resources in"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "EC2 instance type"
}

variable "ami_c8" {
  type        = string
  default     = "ami-0c2b8ca1dad447f8a" # Amazon Linux 2 (us-east-1)
  description = "AMI for Amazon Linux instance"
}

variable "ami_u21" {
  type        = string
  default     = "ami-04b70fa74e45c3917" # Ubuntu 21.04 (us-east-1)
  description = "AMI for Ubuntu 21.04 instance"
}

variable "ssh_allowed_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDRs allowed to connect via SSH"
}

