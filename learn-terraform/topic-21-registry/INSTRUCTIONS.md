# Topic 21: Terraform Registry

## What You'll Learn

- **Terraform Registry** – registry.terraform.io
- **Module source** – `namespace/name/provider` or full URL
- **Version constraint** – pin modules like providers
- **terraform init** – downloads modules (and providers)

## Registry URL Format

```
registry.terraform.io/<namespace>/<name>/<provider>
```

Example: `terraform-aws-modules/vpc/aws`

- Namespace: terraform-aws-modules
- Name: vpc
- Provider: aws

## Short vs Full Source

```hcl
# Short (defaults to registry.terraform.io)
source  = "terraform-aws-modules/vpc/aws"
version = "5.0.0"

# Full URL
source = "registry.terraform.io/terraform-aws-modules/vpc/aws"
```

## Steps

### 1. Apply

```bash
source ../../aws.cred
cd topic-21-registry
terraform init
terraform apply -auto-approve
```

### 2. Verify

Check `.terraform/modules/` – module is cached locally.

### 3. Destroy when done

```bash
terraform destroy -auto-approve
```

---

## Exam Tips

| Concept              | Key Point                                              |
| -------------------- | ------------------------------------------------------ |
| **Registry**         | Public modules at registry.terraform.io                |
| **version**          | Pin modules: `version = ">= 1.0, < 2.0"`               |
| **init**             | Required when adding/changing module source            |
| **Private registry** | Use full URL; may need credentials                     |
| **Git source**       | `source = "git::https://..."` or `github.com/org/repo` |

## Other Source Types

```hcl
# Git
source = "git::https://github.com/org/repo.git?ref=v1.0"

# GitHub shorthand
source = "github.com/org/repo"

# Local
source = "./modules/vpc"

# S3
source = "s3::https://bucket.s3.amazonaws.com/path/to/module.zip"
```

## Practice

1. Run `terraform init -upgrade` – upgrades modules to latest within constraints.
2. Change version to `"~> 4.0"` and run init – downloads different version.
