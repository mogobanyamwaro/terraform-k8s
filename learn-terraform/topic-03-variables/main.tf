# Topic 3: Variables
#
# Variables make your config reusable. No hardcoded values!
#
# Run: terraform init
#      terraform apply                    # uses default
#      terraform apply -var="filename=myfile.txt"
#      terraform apply -var-file="custom.tfvars"

terraform {
  required_version = ">= 1.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

variable "filename" {
  description = "Path for the file to create"
  type        = string
  default     = "output.txt"
}

variable "content" {
  description = "Content to write to the file"
  type        = string
  # No default = required! Must provide via tfvars or -var
}

resource "local_file" "demo" {
  filename = "${path.module}/${var.filename}"
  content  = var.content
}
