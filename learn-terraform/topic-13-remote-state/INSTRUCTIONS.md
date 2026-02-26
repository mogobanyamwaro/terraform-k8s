# Topic 13: terraform_remote_state

## What You'll Learn

- **data "terraform_remote_state"** – read outputs from another config's state
- Use case: shared infrastructure (VPC ID, DB endpoint) across configs
- Backend config – where the other state lives (local, S3, etc.)
- Referencing: `data.terraform_remote_state.name.outputs.output_name`

## Steps

### 1. Apply upstream (produces state with outputs)

```bash
cd topic-13-remote-state/upstream
terraform init
terraform apply -auto-approve
```

### 2. Apply consumer (reads upstream state)

```bash
cd ..
terraform init
terraform apply -auto-approve
```

### 3. Verify

```bash
terraform output
cat consumer.txt
```

---

## Architecture

```
upstream/                    consumer (main.tf)
├── main.tf  → state with    └── data "terraform_remote_state"
│   outputs                    reads upstream outputs
└── terraform.tfstate
```

## Exam Tips

| Concept           | Key Point                                                                |
| ----------------- | ------------------------------------------------------------------------ |
| **backend**       | Where the other state lives: local, s3, etc.                             |
| **config**        | Backend-specific: path (local), bucket/key (s3)                          |
| **outputs**       | `data.terraform_remote_state.x.outputs.output_name`                      |
| **Workspaces**    | Can specify `workspace` for remote backend                               |
| **No dependency** | Consumer doesn't depend on upstream in graph; ensure upstream runs first |

## S3 Backend Example

```hcl
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "my-state"
    key    = "vpc/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## Practice

1. Add a new output in upstream's main.tf, run apply there.
2. Reference it in consumer: `data.terraform_remote_state.upstream.outputs.new_output`
3. Run apply in consumer – it reads the new output.
