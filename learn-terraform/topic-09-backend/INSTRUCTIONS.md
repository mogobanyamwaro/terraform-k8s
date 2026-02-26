# Topic 9: Backend

## What You'll Learn

- **Backend** – where Terraform stores state (local file, S3, Terraform Cloud, etc.)
- **backend block** – inside `terraform { }`
- **Partial config** – backend settings can be passed via `-backend-config` or CLI
- **Migration** – `terraform init -migrate-state` when changing backends

## Steps

### 1. Apply with local backend

```bash
cd topic-09-backend
terraform init
terraform apply -auto-approve
```

State is written to `terraform.tfstate` (local backend default).

### 2. Inspect state location

```bash
ls -la terraform.tfstate
terraform state list
```

---

## Backend Types (Exam)

| Backend     | Use Case                                                     |
| ----------- | ------------------------------------------------------------ |
| **local**   | Default; state in current directory                          |
| **s3**      | Production; state in S3 (with optional DynamoDB for locking) |
| **remote**  | Terraform Cloud / Enterprise                                 |
| **azurerm** | Azure Blob Storage                                           |
| **gcs**     | Google Cloud Storage                                         |

## S3 Backend Example

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "path/to/state.tfstate"
    region = "us-east-1"
  }
}
```

**Note:** Bucket must exist before `terraform init`. Use `terraform init -reconfigure` when changing backend config.

## Exam Tips

| Concept            | Key Point                                                |
| ------------------ | -------------------------------------------------------- |
| **terraform init** | Initializes backend; run after changing backend config   |
| **-migrate-state** | Migrates existing state to new backend when switching    |
| **-reconfigure**   | Ignores existing config; use when backend config changed |
| **State locking**  | S3 + DynamoDB; prevents concurrent runs                  |
| **Partial config** | Backend args in CLI: `-backend-config="key=value"`       |

## Practice

1. Remove the `backend "local"` block (or comment it out) and run `terraform init`. State uses default local backend.
2. Add the block back and run `terraform init` – no migration needed since both are local.
