# Topic 18: terraform validate and terraform fmt

## What You'll Learn

- **terraform validate** – syntax and consistency check
- **terraform fmt** – reformat .tf files
- When to run each (before commit, in CI)

## terraform validate

### What it checks

- Valid HCL syntax
- Provider config consistency
- Variable references
- Internal consistency (references exist, types match)

### Does NOT check

- Whether resources actually exist in cloud
- Provider credentials
- Remote state accessibility

### Steps

```bash
cd topic-18-validate-fmt
terraform init
terraform validate
```

Success: "Success! The configuration is valid."

### Introduce an error

Change `local_file` to `local_fil` (typo). Run `terraform validate` – fails.

---

## terraform fmt

### What it does

- Indent with 2 spaces
- Align `=` in blocks
- Normalize newlines

### Steps

```bash
terraform fmt           # Format files in current dir
terraform fmt -recursive   # Include subdirs
terraform fmt -check      # Exit 1 if formatting needed (CI)
terraform fmt -diff       # Show diff of what would change
```

### Practice

1. Mess up indentation in main.tf (extra spaces, wrong alignment).
2. Run `terraform fmt` – file is reformatted.

---

## Exam Tips

| Command              | Purpose                         |
| -------------------- | ------------------------------- |
| **validate**         | Config validity; run after init |
| **fmt**              | Style; safe to run anytime      |
| **fmt -check**       | CI: fail if not formatted       |
| **fmt -recursive**   | Format all .tf in subdirs       |
| **fmt -write=false** | Dry run; don't write            |

## Order in workflow

```bash
terraform fmt
terraform init
terraform validate
terraform plan
terraform apply
```
