# Topic 1: Terraform Basics

## What You'll Learn

- The Terraform workflow: init → plan → apply
- Provider configuration
- Resource blocks
- Basic CLI commands

## Steps

### 1. Initialize Terraform

```bash
cd topic-01-basics
terraform init
```

**What it does:** Downloads the provider plugins, prepares backend. Run this first in any new Terraform directory.

### 2. Plan (Preview)

```bash
terraform plan
```

**What it does:** Shows what Terraform _would_ do without making changes. Look for "Plan: 1 to add".

### 3. Apply (Create)

```bash
terraform apply
```

Type `yes` when prompted. Terraform creates `hello.txt`.

### 4. Verify

```bash
cat hello.txt
```

### 5. Destroy (Clean up)

```bash
terraform destroy
```

Type `yes` when prompted. Removes the file and updates state.

---

## Exam Tip

**Order matters:** `init` → `plan` → `apply`. You cannot `plan` or `apply` without running `init` first.

## Practice

Add a second `local_file` resource that creates `goodbye.txt` with content "Goodbye!". Run `plan` and `apply` again.
