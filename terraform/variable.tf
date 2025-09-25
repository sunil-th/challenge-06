variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

# If your region doesn't have Ubuntu 21.04, put an AMI id here
variable "ubuntu_ami_id" {
  type    = string
  default = ""
}
