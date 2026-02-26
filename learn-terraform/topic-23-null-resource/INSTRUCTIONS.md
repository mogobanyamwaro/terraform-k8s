# Topic 23: null_resource

## What You'll Learn

- **null_resource** – placeholder resource; doesn't create cloud infra
- **triggers** – when to replace (re-run provisioners)
- **Use cases** – provisioners, dependency chains, "run after X"

## When to Use

| Use Case          | Example                                    |
| ----------------- | ------------------------------------------ |
| Provisioner only  | Run script after other resources exist     |
| Dependency chain  | Force B to run after A (when no reference) |
| Trigger on change | Re-run when a variable or file changes     |

## triggers

When any value in `triggers` changes, Terraform replaces the null_resource (destroy + create). Provisioners run again.

```hcl
triggers = {
  config = var.config_value
  file   = file("${path.module}/file.txt")
}
```

## Steps

### 1. Apply

```bash
cd topic-23-null-resource
terraform init
terraform apply -auto-approve
```

### 2. Check output

```bash
cat null-log.txt
```

### 3. Trigger replace

Change `local_file.config` content and run apply – null_resource is replaced, provisioner runs again.

---

## Exam Tips

| Concept           | Key Point                                |
| ----------------- | ---------------------------------------- |
| **null_resource** | No real infra; provider = hashicorp/null |
| **triggers**      | Map; any change = replace                |
| **id**            | Random UUID; changes on replace          |
| **depends_on**    | Use for ordering                         |
| **No triggers**   | Runs once on create                      |

## Practice

1. Add a variable; put it in triggers – changing the variable triggers replace.
2. Add `triggers = {}` (empty) – null_resource never replaces unless manually `-replace`.
