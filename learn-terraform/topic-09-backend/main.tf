# Topic 9: Backend
#
# Backend = where Terraform stores state.
# Default: local (terraform.tfstate in current dir)
#
# Run: terraform init
#      terraform apply -auto-approve

terraform {
  required_version = ">= 1.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

  # Backend config – where state is stored
  backend "local" {
    path = "terraform.tfstate"
  }
}

resource "local_file" "demo" {
  filename = "${path.module}/backend-demo.txt"
  content  = "State is stored according to backend config."
}

output "backend_note" {
  value = "Check terraform.tfstate – backend controls where this lives"
}
