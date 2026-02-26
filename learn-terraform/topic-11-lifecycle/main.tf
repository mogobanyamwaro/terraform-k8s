# Topic 11: Lifecycle Blocks
#
# Control how Terraform creates, updates, and destroys resources.
# create_before_destroy, prevent_destroy, ignore_changes
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

# create_before_destroy – create new before destroying old (reduces downtime)
resource "local_file" "create_before" {
  filename = "${path.module}/lifecycle-demo.txt"
  content  = "Updated content - new resource created first, then old destroyed"

  lifecycle {
    create_before_destroy = true
  }
}

# ignore_changes – Terraform won't revert manual changes to these attributes
resource "local_file" "ignore_changes" {
  filename = "${path.module}/ignore-demo.txt"
  content  = "If you edit this file manually, Terraform won't overwrite it,i have tested this and it works"

  lifecycle {
    ignore_changes = [content]
  }
}

# prevent_destroy – blocks destroy (uncomment to test; will fail on destroy)
resource "local_file" "protected" {
  filename = "${path.module}/protected.txt"
  content  = "Cannot destroy this resource"

  lifecycle {
    prevent_destroy = true
  }
}
