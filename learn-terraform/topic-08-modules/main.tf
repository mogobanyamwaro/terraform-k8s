# Topic 8: Modules
#
# Modules = reusable blocks of Terraform config.
# Source: local path, registry, or Git.
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
}

# module block – calls the module
module "file_a" {
  source = "./modules/file-module"

  filename = "file-a.txt"
  content  = "Content from module A"
}

module "file_b" {
  source = "./modules/file-module"

  filename = "file-b.txt"
  content  = "Content from module B"
}

output "file_a_path" {
  value = module.file_a.file_path
}

output "file_b_path" {
  value = module.file_b.file_path
}
