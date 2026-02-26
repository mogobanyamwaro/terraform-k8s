# Topic 1: Terraform Basics
# Your first resource - no cloud account needed!
#
# Run: terraform init
#      terraform plan
#      terraform apply

terraform {
  required_version = ">= 1.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

resource "local_file" "hello" {
  filename = "${path.module}/hello.txt"
  content  = "Hello, Terraform! You ran your first apply."
}
