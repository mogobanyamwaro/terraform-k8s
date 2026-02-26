# Topic 13: terraform_remote_state
#
# Read outputs from ANOTHER Terraform config's state.
# Use for: shared VPC ID, database endpoint, etc.
#
# Prereq: cd upstream && terraform init && terraform apply -auto-approve
# Then: terraform init && terraform apply -auto-approve

terraform {
  required_version = ">= 1.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

data "terraform_remote_state" "upstream" {
  backend = "local"

  config = {
    path = "${path.module}/upstream/terraform.tfstate"
  }
}

# Use outputs from upstream state
resource "local_file" "consumer" {
  filename = "${path.module}/consumer.txt"
  content  = "I read: ${data.terraform_remote_state.upstream.outputs.shared_value}"
}

output "upstream_shared_value" {
  value = data.terraform_remote_state.upstream.outputs.shared_value
}

output "upstream_file_path" {
  value = data.terraform_remote_state.upstream.outputs.file_path
}
