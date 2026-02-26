# Topic 8: Modules

## What You'll Learn

- **Module** – folder of `.tf` files with inputs (variables) and outputs
- **module block** – `module "name" { source = "..."; ... }`
- **Source types** – local path, Terraform Registry, Git
- **Referencing** – `module.name.output_name`

## Structure

```
topic-08-modules/
├── main.tf              # Calls the module twice
└── modules/
    └── file-module/
        ├── main.tf      # Creates local_file
        ├── variables.tf # Inputs
        └── outputs.tf   # Outputs
```

## Steps

### 1. Apply

```bash
cd topic-08-modules
terraform init
terraform apply -auto-approve
```

Terraform creates `file-a.txt` and `file-b.txt` via the module.

### 2. Inspect

```bash
terraform output
ls modules/file-module/
```

---

## Exam Tips

| Concept            | Key Point                                                                       |
| ------------------ | ------------------------------------------------------------------------------- |
| **source**         | Required: local `./path`, registry `hashicorp/consul/aws`, Git `github.com/...` |
| **module inputs**  | Pass via variables: `filename = "x"`                                            |
| **module outputs** | Reference: `module.name.output_name`                                            |
| **terraform init** | Required when adding/changing modules (downloads or copies)                     |
| **Root module**    | The directory where you run terraform; others are child modules                 |

## Practice

1. Add a third `module "file_c"` call with different content.
2. Add a variable `prefix` to the module and use it in the filename: `"${var.prefix}-${var.filename}"`.
