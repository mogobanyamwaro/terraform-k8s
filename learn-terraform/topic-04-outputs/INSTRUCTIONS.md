# Topic 4: Outputs

## What You'll Learn

- `output` block – expose values after apply
- `terraform output` – view output values
- Referencing resource attributes: `resource_type.name.attribute`
- `sensitive = true` – hide values in plan/apply (still in state)

## Steps

### 1. Apply and view outputs

```bash
cd topic-04-outputs
terraform init
terraform apply -auto-approve
```

Outputs are printed at the end of apply.

### 2. Query outputs later

```bash
terraform output
terraform output file_path           # Single output (with quotes by default)
terraform output -raw file_path     # Raw value, no quotes
```

### 3. Output as JSON

```bash
terraform output -json
```

Useful for scripts and automation.

---

## Exam Tips

| Concept              | Key Point                                                   |
| -------------------- | ----------------------------------------------------------- |
| **output block**     | `output "name" { value = expression }`                      |
| **description**      | Optional, shown in `terraform output`                       |
| **sensitive**        | `sensitive = true` – hidden in plan, shown as "(sensitive)" |
| **depends_on**       | Outputs can have `depends_on` for explicit ordering         |
| **terraform output** | Fails if no outputs; use `-json` for scripting              |

## Practice

1. Add an output `file_exists` with value `fileexists(local_file.demo.filename)`.
2. Run `terraform apply` and `terraform output`.
3. Add `sensitive = true` to one output, run apply again – notice it’s masked in the plan.
