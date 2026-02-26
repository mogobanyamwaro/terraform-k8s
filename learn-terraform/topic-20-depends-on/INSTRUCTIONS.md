# Topic 20: depends_on

## What You'll Learn

- **depends_on** – explicit dependency between resources
- When to use: no attribute reference, but order matters
- Implicit vs explicit dependencies

## When Terraform Infers Dependencies

Terraform infers dependency when one resource **references** another:

```hcl
resource "b" "x" {
  value = resource.a.x.id   # B depends on A (implicit)
}
```

## When to Use depends_on

Use when:

- B must run after A
- B does NOT reference any attribute of A
- Example: IAM role must exist before EC2 instance (instance uses role, but role creation order matters for other reasons)
- Example: DB must exist before app starts; app reads connection string from somewhere else

## Syntax

```hcl
resource "b" "x" {
  # ...
  depends_on = [resource.a.x]
}

# Multiple dependencies
depends_on = [resource.a, resource.b, module.c]
```

## Steps

### 1. Apply

```bash
cd topic-20-depends-on
terraform init
terraform apply -auto-approve
```

### 2. Verify order

Terraform creates: first → second → final (due to dependencies).

---

## Exam Tips

| Concept           | Key Point                                         |
| ----------------- | ------------------------------------------------- |
| **Implicit**      | From references (e.g. `resource.a.id`)            |
| **Explicit**      | `depends_on = [resource.a]`                       |
| **Module**        | `depends_on` in module block affects whole module |
| **Data source**   | Can use `depends_on` if refresh order matters     |
| **Don't overuse** | Prefer implicit; use depends_on only when needed  |

## Practice

1. Remove the reference from `local_file.second` (the `local_file.first.content` part) but keep `depends_on` – same order, now fully explicit.
2. Add a fourth resource with `depends_on = [local_file.final]` – runs last.
