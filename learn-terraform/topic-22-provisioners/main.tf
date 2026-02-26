# Topic 22: Provisioners
#
# Run scripts during resource create/destroy.
# local-exec: runs on machine running Terraform
# remote-exec: runs on the created resource (e.g. EC2)
#
# Best practice: Avoid provisioners; use user_data, config mgmt, or separate tooling.
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

resource "local_file" "demo" {
  filename = "${path.module}/provisioner-demo.txt"
  content  = "Provisioner runs after this resource is created"

  provisioner "local-exec" {
    command = "echo 'Resource created at $(date)' >> ${path.module}/provisioner-log.txt"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Resource destroyed at $(date)' >> ${path.module}/provisioner-log.txt"
  }
}
