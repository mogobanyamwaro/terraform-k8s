# Topic 10: count and for_each
#
# Create multiple instances of a resource.
# count  = number (0, 1, 2, ...)
# for_each = map or set (each key = one instance)
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

# count – creates 3 files: file-0.txt, file-1.txt, file-2.txt
resource "local_file" "count_demo" {
  count    = 3
  filename = "${path.module}/count-file-${count.index}.txt"
  content  = "File ${count.index + 1} of 3"
}

# for_each with map – each key becomes an instance
resource "local_file" "for_each_demo" {
  for_each = {
    dev  = "Development environment"
    prod = "Production environment"
    staging = "Staging environment"
  }
  filename = "${path.module}/env-${each.key}.txt"
  content  = each.value
}

output "count_files" {
  value = local_file.count_demo[*].filename
}

output "for_each_files" {
  value = [for f in local_file.for_each_demo : f.filename]
}
