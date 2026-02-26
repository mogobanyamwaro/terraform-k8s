# Topic 22: Provisioners

## What You'll Learn

- **local-exec** – run command on the machine running Terraform
- **remote-exec** – run command on the created resource (SSH/WinRM)
- **when = destroy** – run on destroy instead of create
- **Why to avoid** – non-declarative, hard to debug, use alternatives

## Types

| Provisioner     | Runs on                  | Use case                            |
| --------------- | ------------------------ | ----------------------------------- |
| **local-exec**  | Terraform machine        | Logging, trigger webhook, call API  |
| **remote-exec** | New resource (EC2, etc.) | Bootstrap; prefer user_data instead |

## Syntax

```hcl
provisioner "local-exec" {
  command = "echo hello"
  # environment = { VAR = "value" }
  # working_dir = "/path"
}

provisioner "local-exec" {
  when    = destroy
  command = "echo destroyed"
}
```

## Steps

### 1. Apply

```bash
cd topic-22-provisioners
terraform init
terraform apply -auto-approve
```

### 2. Verify

```bash
cat provisioner-log.txt
```

### 3. Destroy

```bash
terraform destroy -auto-approve
cat provisioner-log.txt   # Destroy message appended
```

---

## Exam Tips

| Concept            | Key Point                                       |
| ------------------ | ----------------------------------------------- |
| **local-exec**     | Runs locally; command, environment, working_dir |
| **remote-exec**    | Needs connection (ssh, winrm)                   |
| **when = destroy** | Runs on destroy; `when = create` is default     |
| **Failure**        | Provisioner failure = resource marked tainted   |
| **null_resource**  | Common placeholder for provisioner-only logic   |

## Better Alternatives

| Instead of         | Use                         |
| ------------------ | --------------------------- |
| remote-exec on EC2 | user_data, cloud-init       |
| Complex setup      | Ansible, Chef, Packer image |
| API calls          | Separate CI/CD step         |

## Practice

1. Change the command to write a different message.
2. Add `environment = { FOO = "bar" }` and use `$FOO` in the command.
