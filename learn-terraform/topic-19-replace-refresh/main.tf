# Topic 19: terraform apply -replace and terraform refresh
#
# -replace: Force replacement of a specific resource
# -refresh-only: Update state from real infra without applying changes
#
# Run: terraform init
#      terraform apply -auto-approve
#      terraform apply -replace="local_file.demo" -auto-approve
#      terraform plan -refresh-only

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
  filename = "${path.module}/replace-demo.txt"
  content  = "Original content. Use -replace to force recreate."
}

output "content_hash" {
  value = filesha256("${path.module}/replace-demo.txt")
}
