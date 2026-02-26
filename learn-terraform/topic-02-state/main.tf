# Topic 2: Understanding Terraform State
#
# State stores the mapping between your config and real resources.
# After apply, inspect: terraform.tfstate (JSON file)
#
# Run: terraform init
#      terraform apply
#      cat terraform.tfstate   # or: terraform show

terraform {
  required_version = ">= 1.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

resource "local_file" "state_demo" {
  filename = "${path.module}/state-demo.txt"
  content  = "This file exists so Terraform tracks it in state."
}
