# Simple module: creates a local file
# Modules are reusable Terraform config in a subfolder

resource "local_file" "content" {
  filename = "${path.module}/${var.filename}"
  content  = var.content
}
