# Topic 24: terraform graph

## What You'll Learn

- **terraform graph** – output dependency graph in DOT format
- **Graphviz** – tool to render DOT as image
- Use for: understanding dependencies, debugging ordering

## Steps

### 1. Generate graph

```bash
cd topic-24-graph
terraform init
terraform apply -auto-approve
terraform graph
```

Output is DOT (nodes and edges). Example:

```
digraph {
  "local_file.a" -> "local_file.b"
  "local_file.a" -> "local_file.c"
  "local_file.b" -> "local_file.c"
}
```

### 2. Render as image (requires Graphviz)

```bash
terraform graph | dot -Tpng -o graph.png
open graph.png
```

Or as SVG:

```bash
terraform graph | dot -Tsvg -o graph.svg
```

### 3. Plan-only graph

```bash
terraform graph -type=plan
```

Shows plan-time dependencies (default).

### 4. Destroy graph

```bash
terraform graph -type=destroy
```

Shows destroy order (reverse of create).

---

## Exam Tips

| Flag              | Purpose                             |
| ----------------- | ----------------------------------- |
| **-type=plan**    | Default; create/update dependencies |
| **-type=apply**   | Same as plan for graph purposes     |
| **-type=destroy** | Destroy order                       |
| **-draw-cycles**  | Highlight circular dependencies     |
| **-module-depth** | Limit module depth in output        |

## Graphviz Install

```bash
# macOS
brew install graphviz

# Ubuntu/Debian
apt install graphviz
```

## Practice

1. Add a fourth resource with dependencies; run graph and see the new edges.
2. Run `terraform graph -type=destroy` and compare to plan graph.
