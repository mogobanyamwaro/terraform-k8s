# Topic 15: Built-in Functions
#
# Terraform has many functions for strings, numbers, collections, etc.
# Docs: https://developer.hashicorp.com/terraform/language/functions
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

locals {
  items = ["apple", "banana", "cherry"]
  tags  = { env = "dev", app = "web" }
}

resource "local_file" "demo" {
  filename = "${path.module}/functions-demo.txt"
  content  = <<-EOT
    join:     ${join(", ", local.items)}
    length:   ${length(local.items)}
    element:  ${element(local.items, 0)}
    lookup:   ${lookup(local.tags, "env")}
    coalesce: ${coalesce("", "default-value")}
    trimspace: ${trimspace("  hello  ")}
  EOT
}

output "join_result" {
  value = join("-", local.items)
}

output "substring" {
  value = substr("hello", 0, 3)
}

output "upper" {
  value = upper("terraform")
}
