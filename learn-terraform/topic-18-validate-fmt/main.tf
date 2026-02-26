# Topic 18: terraform validate and terraform fmt
#
# validate – Check config syntax and internal consistency
# fmt – Format .tf files to canonical style
#
# Run: terraform init
#      terraform validate
#      terraform fmt

terraform {
  required_version = ">= 1.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

resource "local_file" "demo" {
  filename = "${path.module}/demo.txt"
  content  = "terraform validate checks syntax; terraform fmt fixes formatting"
}
