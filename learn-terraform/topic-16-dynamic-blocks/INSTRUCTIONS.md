# Topic 16: Dynamic Blocks

## What You'll Learn

- **dynamic** – repeat a nested block for each item in a list/map
- **for_each** – iterable (like in resources)
- **content** – the block body to repeat
- **iterator** – default `dynamic_block_name` (e.g. `ingress.key`, `ingress.value`)

## Syntax

```hcl
dynamic "block_name" {
  for_each = var.list_or_map
  content {
    # Block attributes; use iterator.value or iterator.key
  }
}
```

## Steps

### 1. Apply

```bash
source ../../aws.cred
cd topic-16-dynamic-blocks
terraform init
terraform apply -auto-approve
```

### 2. Verify

In AWS Console: VPC → Security Groups → `dynamic-block-sg` – 3 ingress rules.

### 3. Destroy when done

```bash
terraform destroy -auto-approve
```

---

## Exam Tips

| Concept      | Key Point                                       |
| ------------ | ----------------------------------------------- |
| **dynamic**  | Inside a resource; generates nested blocks      |
| **for_each** | List or map to iterate over                     |
| **content**  | Required; body of each generated block          |
| **iterator** | `iterator = "ing"` → use `ing.key`, `ing.value` |
| **nesting**  | Can nest dynamic blocks                         |

## Add a 4th rule

Add to `var.ingress_rules`:

```hcl
{ port = 8080, protocol = "tcp", cidr = "0.0.0.0/0" }
```

Run plan – 1 ingress rule to add.

## Practice

1. Add `iterator = "rule"` and change `ingress.value` to `rule.value`.
2. Add a second dynamic block for tags from a variable.
