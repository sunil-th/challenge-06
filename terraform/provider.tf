terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
    tls = { source = "hashicorp/tls" }
    random = { source = "hashicorp/random" }
    local = { source = "hashicorp/local" }
  }
}

provider "aws" {
  region = var.aws_region
}
