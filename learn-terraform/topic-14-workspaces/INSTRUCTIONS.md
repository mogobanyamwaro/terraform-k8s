# Topic 14: Workspaces

## What You'll Learn

- **terraform workspace** – multiple states per config (dev, prod, etc.)
- **terraform.workspace** – built-in value = current workspace name
- `list`, `select`, `new`, `delete` commands
- State isolation – each workspace has separate state

## Steps

### 1. List workspaces

```bash
cd topic-14-workspaces
terraform init
terraform workspace list
```

`*` marks the current workspace. Default is `default`.

### 2. Create and switch

```bash
terraform workspace new dev
terraform workspace select dev
terraform apply -auto-approve
```

Creates `output-dev.txt`.

### 3. Create another workspace

```bash
terraform workspace new prod
terraform apply -auto-approve
```

Creates `output-prod.txt`. Dev resources remain (different state).

### 4. Switch and verify

```bash
terraform workspace select dev
terraform state list
terraform workspace select prod
terraform state list
```

Each workspace has its own state.

---

## Exam Tips

| Concept                 | Key Point                                            |
| ----------------------- | ---------------------------------------------------- |
| **terraform.workspace** | Built-in; current workspace name                     |
| **State isolation**     | Each workspace = separate state; no shared resources |
| **default**             | Created automatically; cannot be deleted             |
| **workspace new**       | Creates and selects                                  |
| **workspace select**    | Switches workspace                                   |

## Local Backend + Workspaces

With local backend, state files live in:
`terraform.tfstate.d/<workspace>/terraform.tfstate`

## Practice

1. Run `terraform workspace delete prod` (switch to another workspace first if prod is selected).
2. Create workspace `staging`, apply, then list the files – you'll see `output-staging.txt`.
