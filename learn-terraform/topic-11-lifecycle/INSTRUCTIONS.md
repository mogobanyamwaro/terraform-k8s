# Topic 11: Lifecycle Blocks

## What You'll Learn

- **create_before_destroy** – create replacement before destroying old
- **prevent_destroy** – block `terraform destroy` (plan fails)
- **ignore_changes** – don't update these attributes (ignore drift)
- **replace_triggered_by** – replace when another resource changes (Terraform 1.2+)

## Steps

### 1. Apply

```bash
cd topic-11-lifecycle
terraform init
terraform apply -auto-approve
```

### 2. Test ignore_changes

Edit `ignore-demo.txt` manually (add a line). Run `terraform plan` – no changes. Terraform ignores content changes.

### 3. Test create_before_destroy

Change the `content` of `lifecycle-demo.txt` in main.tf and run `terraform apply`. Terraform creates the new file, then removes the old one.

### 4. Test prevent_destroy (optional)

Uncomment the `local_file.protected` block, apply, then run `terraform destroy` – it will fail.

---

## Exam Tips

| Argument                  | Purpose                                                      |
| ------------------------- | ------------------------------------------------------------ |
| **create_before_destroy** | New resource first, then destroy old; minimizes downtime     |
| **prevent_destroy**       | Fails destroy; protects critical resources                   |
| **ignore_changes**        | List of attributes to ignore; e.g. `ignore_changes = [tags]` |
| **replace_triggered_by**  | Force replace when referenced resource changes               |

## Example: ignore_changes with tags

```hcl
lifecycle {
  ignore_changes = [
    tags,
    tags["auto-updated"]
  ]
}
```

## Practice

1. Add `ignore_changes = [content]` to the first resource, change content manually, run plan – no update.
2. Remove the lifecycle block and run plan – Terraform wants to update (revert your manual change).
