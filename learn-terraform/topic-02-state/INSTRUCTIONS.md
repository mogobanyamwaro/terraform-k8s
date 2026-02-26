# Topic 2: Terraform State

## What You'll Learn

- What `terraform.tfstate` contains
- Why state is required (Terraform needs it to know what it manages)
- `terraform show` – human-readable state
- How destroy removes resources and updates state

## Steps

### 1. Apply to create state

```bash
cd topic-02-state
terraform init
terraform apply -auto-approve
```

### 2. Inspect the state file

```bash
cat terraform.tfstate
```

You'll see JSON with resource IDs, attributes, metadata. Terraform uses this to map config → real resources.

### 3. Human-readable view

```bash
terraform show
```

Same data, formatted for reading.

### 4. What happens on destroy?

```bash
terraform destroy -auto-approve
cat terraform.tfstate
```

State is updated (resource removed from state). The file still exists but is empty of resources.

---

## Exam Tips

| Concept                  | Key Point                                                                    |
| ------------------------ | ---------------------------------------------------------------------------- |
| **Purpose of state**     | Maps config to real resource IDs; required for Terraform to manage resources |
| **State location**       | Local by default (`terraform.tfstate`); can use remote backends (S3, etc.)   |
| **Never edit manually**  | Use `terraform state` commands instead                                       |
| **terraform state list** | Lists all resources in state                                                 |
| **terraform state show** | Shows one resource: `terraform state show local_file.state_demo`             |

## Practice

1. Run `terraform apply` again.
2. Run `terraform state list` – note the resource address.
3. Run `terraform state show local_file.state_demo` – see full resource details.
