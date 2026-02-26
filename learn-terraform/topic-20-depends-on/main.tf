# Topic 20: depends_on
#
# Explicit dependency when Terraform can't infer from references.
# Use when: resource A must exist before B, but B doesn't reference A.
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

# Resource A – creates first file
resource "local_file" "first" {
  filename = "${path.module}/first.txt"
  content  = "Created first (no dependencies)"
}

# Resource B – creates second file
# Implicit dependency: content references local_file.first (Terraform infers order)
resource "local_file" "second" {
  filename = "${path.module}/second.txt"
  content  = "Created after first. First file content: ${local_file.first.content}"

  # Explicit depends_on – use when there's NO reference but order matters
  # Example: DB must exist before app, but app config doesn't use DB ID
  depends_on = [local_file.first]
}

# Resource C – no reference to first/second, but must run after both
resource "local_file" "final" {
  filename = "${path.module}/final.txt"
  content  = "Runs last – explicit depends_on only (no attribute reference)"

  depends_on = [local_file.first, local_file.second]
}
