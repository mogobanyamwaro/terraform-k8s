# Topic 12: terraform import

## What You'll Learn

- **terraform import** – add existing resource to state (adopt infrastructure)
- Import does NOT update config – you must write the resource block
- Import does NOT modify the resource – only updates state
- Format: `terraform import <address> <id>`

## Steps

### 1. Create a resource outside Terraform

```bash
cd topic-12-import
echo "I was created outside Terraform" > import-demo.txt
```

### 2. Add the resource block

The `main.tf` already has a `local_file.imported` block. The resource must exist in config before import.

### 3. Import

```bash
terraform init
terraform import local_file.imported "$(pwd)/import-demo.txt"
```

For local_file, the ID is the file path. Other resources use different IDs (e.g. AWS: `id` or `arn`).

### 4. Verify

```bash
terraform plan
```

If config matches the file, plan shows no changes. If content differs, plan shows an update.

### 5. Optional: terraform import -help

```bash
terraform import -help
```

---

## Exam Tips

| Concept            | Key Point                                            |
| ------------------ | ---------------------------------------------------- |
| **Purpose**        | Adopt existing resources; don't create duplicates    |
| **Config first**   | Resource block must exist; import only touches state |
| **ID format**      | Depends on resource type; check provider docs        |
| **No modify**      | Import reads into state; doesn't change the resource |
| **terraform plan** | After import, run plan; may need to adjust config    |

## AWS Import Example

```bash
terraform import aws_instance.web i-0123456789abcdef0
```

## Practice

1. Delete `import-demo.txt` and run `terraform destroy` – removes from state and deletes.
2. Create the file again manually, run `terraform import` again – re-adopts it.
