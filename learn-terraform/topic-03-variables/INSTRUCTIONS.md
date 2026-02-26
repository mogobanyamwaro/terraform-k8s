# Topic 3: Variables

## What You'll Learn

- `variable` block – declare variables with type, description, default
- `terraform.tfvars` – auto-loaded file for variable values
- `-var` and `-var-file` – override values at runtime
- Referencing: `var.variable_name`

## Steps

### 1. Apply with defaults + tfvars

```bash
cd topic-03-variables
terraform init
terraform apply -auto-approve
```

- `filename` uses default: `output.txt`
- `content` comes from `terraform.tfvars`

### 2. Override with -var

```bash
terraform apply -auto-approve -var="filename=custom-name.txt"
```

Creates `custom-name.txt` instead of `output.txt`.

### 3. Override with -var-file

Create `dev.tfvars`:

```hcl
filename = "dev-output.txt"
content  = "Dev environment content"
```

Then:

```bash
terraform apply -auto-approve -var-file="dev.tfvars"
```

### 4. Variable priority (highest wins)

1. `-var` flag
2. `-var-file`
3. `terraform.tfvars` (or `*.auto.tfvars`)
4. Environment: `TF_VAR_filename` (e.g. `export TF_VAR_filename=env.txt`)
5. Default in variable block

---

## Exam Tips

| Concept            | Key Point                                           |
| ------------------ | --------------------------------------------------- |
| **variable block** | `variable "name" { type, default, description }`    |
| **Types**          | string, number, bool, list, map, object, etc.       |
| **Required**       | Omit `default` = variable is required               |
| **Sensitive**      | `sensitive = true` hides value in plan/apply output |
| **TF*VAR***        | Env vars: `TF_VAR_myvar` sets `var.myvar`           |

## Practice

1. Add a variable `suffix` (string, default = "v1").
2. Use it in the filename: `"${var.filename}-${var.suffix}.txt"`.
3. Run apply with `-var="suffix=prod"` and verify the filename.
