# Topic 25: Sensitive Values
#
# Hide values in plan/apply output.
# variable: sensitive = true
# output: sensitive = true
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

variable "api_key" {
  description = "Secret API key"
  type        = string
  sensitive   = true
  default     = "sk-secret-12345"
}

variable "public_name" {
  default = "my-app"
}

resource "local_file" "config" {
  filename = "${path.module}/config.txt"
  content  = "API endpoint for ${var.public_name}" # Don't put secrets in content!
}

output "api_key" {
  value     = var.api_key
  sensitive = true
}

output "public_info" {
  value = "App: ${var.public_name}"
}
