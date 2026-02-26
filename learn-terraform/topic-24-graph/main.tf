# Topic 24: terraform graph
#
# Visualize resource dependencies as a graph.
# Output: DOT format (use Graphviz to render)
#
# Run: terraform init
#      terraform graph
#      terraform graph | dot -Tpng -o graph.png

terraform {
  required_version = ">= 1.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

resource "local_file" "a" {
  filename = "${path.module}/a.txt"
  content  = "First"
}

resource "local_file" "b" {
  filename = "${path.module}/b.txt"
  content  = "Depends on A: ${local_file.a.content}"
}

resource "local_file" "c" {
  filename = "${path.module}/c.txt"
  content  = "Depends on A and B"

  depends_on = [local_file.a, local_file.b]
}
