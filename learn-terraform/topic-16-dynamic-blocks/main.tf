# Topic 16: Dynamic Blocks
#
# Generate repeated nested blocks from a list or map.
# Classic use: security group ingress/egress rules.
#
# Run: source ../../aws.cred
#      terraform init
#      terraform apply -auto-approve

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "ingress_rules" {
  type = list(object({
    port     = number
    protocol = string
    cidr     = string
  }))
  default = [
    { port = 80, protocol = "tcp", cidr = "0.0.0.0/0" },
    { port = 443, protocol = "tcp", cidr = "0.0.0.0/0" },
    { port = 22, protocol = "tcp", cidr = "0.0.0.0/0" }
  ]
}

# Minimal VPC for the security group
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "dynamic-block-vpc" }
}

# Dynamic block: creates one "ingress" block per item in var.ingress_rules
resource "aws_security_group" "main" {
  name        = "dynamic-block-sg"
  description = "SG with dynamic ingress rules"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = [ingress.value.cidr]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "dynamic-block-sg" }
}
