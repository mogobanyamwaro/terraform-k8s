# Topic 5: Data Sources

## What You'll Learn

- `data` block – read existing resources (no create/update/delete)
- Data sources vs resources: `data` = read-only, `resource` = managed
- Referencing: `data.type.name.attribute`
- Common AWS data sources for exam: `aws_caller_identity`, `aws_region`, `aws_ami`, etc.

## Steps

### 1. Set AWS credentials

```bash
source "../../aws.cred"   # From sectionOne folder
# Or: cd to sectionOne and source aws.cred, then cd learn-terraform/topic-05-data-sources
```

### 2. Apply

```bash
cd topic-05-data-sources
terraform init
terraform apply -auto-approve
```

**Note:** Data sources don't create resources. Plan shows "0 to add" – Terraform just fetches the data.

### 3. View outputs

```bash
terraform output
```

You'll see your AWS account ID, caller ARN, and region.

---

## Exam Tips

| Concept                 | Key Point                                          |
| ----------------------- | -------------------------------------------------- |
| **data block**          | `data "type" "name" { ... }` – read-only           |
| **Refresh**             | Data sources are refreshed during plan/apply       |
| **depends_on**          | Use in data block if it depends on other resources |
| **aws_caller_identity** | Returns account_id, arn, user_id                   |
| **aws_region**          | Returns name, endpoint, etc.                       |

## Practice

1. Add `data "aws_availability_zones" "available" {}`.
2. Add an output for `data.aws_availability_zones.available.names`.
3. Run apply and confirm you see the AZ list.
