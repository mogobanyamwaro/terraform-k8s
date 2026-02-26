# Topic 23: null_resource
#
# A resource that does nothing by itself. Used for:
# - Running provisioners without a real resource
# - Creating dependency chains
# - Triggering on changes (triggers = {})
#
# Run: terraform init
#      terraform apply -auto-approve

terraform {
  required_version = ">= 1.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

resource "local_file" "config" {
  filename = "${path.module}/config.txt"
  content  = "Config that other steps depend on"
}

# null_resource - no real infrastructure; just for provisioners/dependencies
resource "null_resource" "post_create" {
  depends_on = [local_file.config]

  # Re-run when these change (replaces null_resource)
  triggers = {
    config_content = local_file.config.content
  }

  provisioner "local-exec" {
    command = "echo 'Config ready. Content: $(cat ${path.module}/config.txt)' >> ${path.module}/null-log.txt"
  }
}

output "null_resource_id" {
  value = null_resource.post_create.id
}
