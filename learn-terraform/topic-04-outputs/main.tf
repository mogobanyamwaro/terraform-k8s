# Topic 4: Outputs
#
# Outputs expose values after apply. Use: terraform output
#
# Run: terraform init
#      terraform apply -auto-approve
#      terraform output

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
  filename = "${path.module}/output-demo.txt"
  content  = "Terraform outputs expose values from your configuration."
}

output "file_path" {
  description = "Full path to the created file"
  value       = local_file.demo.filename
}

output "file_content_length" {
  description = "Number of characters in the file"
  value       = length(local_file.demo.content)
}
