# Topic 19: terraform apply -replace and terraform refresh

## What You'll Learn

- **terraform apply -replace** – force replacement of a specific resource
- **terraform plan -refresh-only** – update state from real infra (no apply)
- **terraform apply -refresh-only** – apply the refresh (update state)
- Replaces deprecated `terraform taint`

## terraform apply -replace

### Purpose

Force Terraform to destroy and recreate a resource, even if config hasn't changed.

### Use cases

- Corrupted resource
- Need to rotate/regenerate
- Recover from failed state

### Steps

```bash
cd topic-19-replace-refresh
terraform init
terraform apply -auto-approve
```

Then force replacement:

```bash
terraform apply -replace="local_file.demo" -auto-approve
```

Terraform destroys and recreates the file.

### Syntax

```bash
terraform apply -replace="resource_type.name"
terraform apply -replace="module.x.resource_type.name"   # In a module
```

---

## terraform refresh / plan -refresh-only

### What it does

Compares real infrastructure with state; updates state to match reality (drift detection).

### plan -refresh-only

```bash
terraform plan -refresh-only
```

Shows what would change in state. Does NOT update state.

### apply -refresh-only

```bash
terraform apply -refresh-only
```

Applies the refresh – updates state to match real infra.

### Note

`terraform refresh` (standalone) is deprecated; use `plan -refresh-only` + `apply -refresh-only`.

---

## Exam Tips

| Concept                 | Key Point                                     |
| ----------------------- | --------------------------------------------- |
| **-replace**            | Force recreate one resource; use full address |
| **taint**               | Deprecated; use -replace                      |
| **-refresh-only**       | Update state from reality; no config changes  |
| **plan -refresh-only**  | Preview refresh; no state update              |
| **apply -refresh-only** | Actually update state                         |

## Practice

1. Edit `replace-demo.txt` manually (drift).
2. Run `terraform plan` – Terraform wants to revert.
3. Run `terraform plan -refresh-only` – would update state to match file.
4. Run `terraform apply -refresh-only` – state now matches reality.
