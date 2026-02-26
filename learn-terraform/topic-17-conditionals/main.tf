# Topic 17: Conditional Expressions
#
# Ternary: condition ? true_val : false_val
# try(): try(expr, default) – return default on error
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

variable "environment" {
  default = "dev"
}

variable "instance_count" {
  default = 2
}

# Ternary: condition ? true_val : false_val
# Both branches must be same type
locals {
  is_prod    = var.environment == "prod"
  size       = var.environment == "prod" ? "large" : "small"
  multiplier = var.instance_count > 0 ? var.instance_count : 1
}

resource "local_file" "config" {
  filename = "${path.module}/config.txt"
  content  = <<-EOT
    Environment: ${var.environment}
    Size (ternary): ${local.size}
    Is prod: ${local.is_prod}
  EOT
}

# try() – return default if expression errors (e.g. null, missing key)
variable "optional" {
  default = null
}

output "ternary_size" {
  value = local.size
}

output "try_example" {
  value = try(var.optional, "default-when-null")
}

output "try_map_lookup" {
  value = try({ a = 1 }["b"], "key-not-found")
}
