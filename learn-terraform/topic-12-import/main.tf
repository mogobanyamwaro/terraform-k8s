# Topic 12: terraform import
#
# Import brings EXISTING infrastructure into Terraform state.
# Config must exist first; import only updates state (doesn't modify the resource).
#
# Steps:
# 1. Create a file manually: echo "I was created outside Terraform" > import-demo.txt
# 2. terraform init
# 3. terraform import local_file.imported "$(pwd)/import-demo.txt"
# 4. terraform plan (may show content drift - update config to match, or apply)

terraform {
  required_version = ">= 1.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Resource block must exist BEFORE import
# Terraform matches by ID; config can differ (plan will show updates)
resource "local_file" "imported" {
  filename = "${path.module}/import-demo.txt"
  content  = "I was created outside Terraform"
}
