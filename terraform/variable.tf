variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "public_key" {
  description = "Public SSH key content (used to create AWS key pair). Set in CI from generated key."
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "vpc_security_group_ids" {
  type    = list(string)
  default = [] # optional: provide SG IDs via CI / var file. If empty we create a security group in main.tf
}
