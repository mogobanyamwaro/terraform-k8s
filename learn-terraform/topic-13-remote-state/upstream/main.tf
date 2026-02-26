# Upstream config – produces state with outputs
# Run: terraform init && terraform apply -auto-approve

terraform {
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.0" }
  }
}

resource "local_file" "shared" {
  filename = "${path.module}/shared-output.txt"
  content  = "Data from upstream config"
}

output "shared_value" {
  value = local_file.shared.content
}

output "file_path" {
  value = local_file.shared.filename
}
