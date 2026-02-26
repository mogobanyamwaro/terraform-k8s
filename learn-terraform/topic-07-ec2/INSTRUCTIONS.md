# Topic 7: EC2 (Terraform Focus)

## Terraform Concepts Here

- **Implicit dependencies** – EC2 references subnet and SG; Terraform creates them in order
- **Referencing resources** – `aws_subnet.main.id`, `aws_security_group.allow_ssh.id`
- **Data source for AMI** – `data.aws_ami.ubuntu` (no hardcoded AMI IDs)
- **Heredoc for user_data** – `<<-EOF` for multi-line strings
- **List attribute** – `vpc_security_group_ids = [aws_security_group.allow_ssh.id]`

## Steps

### 1. Apply

```bash
source ../../aws.cred
cd topic-07-ec2
terraform init
terraform apply -auto-approve
```

### 2. Check outputs

```bash
terraform output public_ip
```

(You’d need a key pair to SSH; instance runs nginx.)

### 3. Destroy when done

```bash
terraform destroy -auto-approve
```

**Note:** EC2 charges by the hour. Run destroy when finished.

---

## Exam Tips

| Concept            | Key Point                                                         |
| ------------------ | ----------------------------------------------------------------- |
| **depends_on**     | Use when Terraform can't infer dependency from references         |
| **user_data**      | Script runs at first boot; use `<<-EOF` for heredoc               |
| **data "aws_ami"** | Look up AMI by name/owner instead of hardcoding ID                |
| **Implicit deps**  | Referencing `resource.x.y` creates dependency automatically       |
| **count/for_each** | Create multiple instances; `count` = number, `for_each` = map/set |

## Practice

1. Add `count = 2` to `aws_instance.web` and update the output to show both IPs with `[*].public_ip`.
2. Add `depends_on = [aws_internet_gateway.main]` to the instance and run plan – no change, dependency already implicit.
