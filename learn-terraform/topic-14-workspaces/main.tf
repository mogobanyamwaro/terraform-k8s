# Topic 14: Workspaces
#
# Workspaces = separate state per environment (dev, staging, prod).
# Each workspace has its own terraform.tfstate.
#
# Run: terraform workspace list
#      terraform workspace new dev
#      terraform workspace select dev
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

# terraform.workspace = current workspace name ("default", "dev", "prod", etc.)
resource "local_file" "workspace_demo" {
  filename = "${path.module}/output-${terraform.workspace}.txt"
  content  = "Deployed to workspace: ${terraform.workspace}"
}

output "current_workspace" {
  value = terraform.workspace
}

output "file_path" {
  value = local_file.workspace_demo.filename
}
