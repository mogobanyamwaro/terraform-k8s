# Topic 25: Sensitive Values

## What You'll Learn

- **variable { sensitive = true }** – value hidden in plan/apply output
- **output { sensitive = true }** – value hidden; shown as "(sensitive)"
- **terraform output** – by default, sensitive outputs are still shown (redacted in logs)
- **terraform output -json** – sensitive values are redacted

## Steps

### 1. Apply

```bash
cd topic-25-sensitive
terraform init
terraform apply -auto-approve
```

In the plan output, `var.api_key` and the api_key output show as `(sensitive)`.

### 2. Query outputs

```bash
terraform output api_key        # Shows value (user has access)
terraform output -json api_key  # Value redacted in JSON
```

### 3. Sensitive in logs

When TF_LOG=1 or similar, sensitive values are redacted in logs.

---

## Exam Tips

| Concept                | Key Point                                                          |
| ---------------------- | ------------------------------------------------------------------ |
| **variable sensitive** | Hides in plan; still in state (state can contain secrets)          |
| **output sensitive**   | Hides in plan/apply; `output -json` redacts                        |
| **nonsensitive()**     | Expose sensitive value: `nonsensitive(var.secret)` – use with care |
| **State**              | Sensitive values ARE in state; protect state file                  |
| **Not encryption**     | Sensitive = hide in UI/logs; doesn't encrypt                       |

## nonsensitive()

Forces a sensitive value to be displayed. Use when you need to pass it somewhere that requires non-sensitive:

```hcl
output "forced" {
  value = nonsensitive(var.api_key)  # Will show in plan
}
```

## Practice

1. Run `terraform plan` and confirm api_key shows as (sensitive).
2. Add `sensitive = true` to a non-secret variable and see the effect.
