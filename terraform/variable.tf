variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ssh_allowed_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
  description = "CIDRs allowed to SSH (narrow for production!)"
}

# If you prefer to fix AMIs explicitly per-region, override these.
variable "ami_c8" {
  type    = string
  default = "" # optional override; leave empty to use an AMI lookup
}

variable "ami_u21" {
  type    = string
  default = "" # optional override; leave empty to use an AMI lookup
}
