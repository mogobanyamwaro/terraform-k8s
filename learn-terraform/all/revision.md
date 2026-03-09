Below is a **comprehensive 30-minute final revision guide** for the **HashiCorp Certified: Terraform Associate** exam.
The goal is to **review the highest-yield topics that appear most frequently**, so you can refresh everything right before the test.

I organized it as a **30-minute timeline** so you can quickly scan it before the exam.

---

# 30-Minute Terraform Associate Final Revision Guide

---

# Minute 0–5: Terraform Core Concepts

## What Terraform Is

Terraform is an **Infrastructure as Code (IaC)** tool used to:

- Define infrastructure using **declarative configuration**
- Manage infrastructure lifecycle
- Track resources using **state**

Terraform configuration language is **HCL (HashiCorp Configuration Language)**.

---

## Terraform Architecture

Terraform consists of:

1. **Terraform Core**
   - reads configuration
   - builds dependency graph
   - executes plan

2. **Providers**
   - interact with APIs

Example:

```hcl
provider "aws" {
  region = "us-east-1"
}
```

Providers are downloaded from the **Terraform Registry**.

---

## Terraform Workflow (MEMORIZE)

1️⃣ Write configuration

2️⃣ Initialize project

```
terraform init
```

3️⃣ Review execution plan

```
terraform plan
```

4️⃣ Apply infrastructure

```
terraform apply
```

5️⃣ Destroy infrastructure

```
terraform destroy
```

---

# Minute 5–10: Terraform State (VERY IMPORTANT)

Terraform tracks infrastructure using:

```
terraform.tfstate
```

State maps:

```
Terraform resource → real infrastructure
```

Example:

```
aws_instance.web -> i-02a33fa
```

---

## Why State Matters

Terraform uses state to:

- track resource metadata
- detect drift
- determine what to create/change/destroy
- enable dependency graph

Without state:

Terraform may **recreate existing infrastructure**.

---

## Remote State Benefits

Remote state enables:

- collaboration
- state locking
- secure storage

Common setup:

| Component     | Service  |
| ------------- | -------- |
| state storage | S3       |
| state locking | DynamoDB |

Example backend:

```hcl
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key = "prod/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-lock"
  }
}
```

---

## State Commands

Important commands:

```
terraform state list
```

List resources in state

```
terraform state show RESOURCE
```

Show resource details

```
terraform state rm RESOURCE
```

Remove from state only

```
terraform import
```

Import existing infrastructure.

---

# Minute 10–15: Providers and Modules

## Providers

Providers enable Terraform to manage resources.

Example:

```hcl
provider "aws" {
  region = "us-east-1"
}
```

Provider requirements:

```hcl
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

---

## Provider Lock File

```
terraform.lock.hcl
```

Purpose:

- locks provider versions
- ensures reproducible builds

Commit this file to Git.

---

# Modules

Modules allow **reusable infrastructure code**.

Example:

```hcl
module "network" {
  source = "./modules/vpc"
}
```

Module sources include:

- local path
- Git repository
- Terraform Registry
- HTTP

---

## Module Outputs

Example:

```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}
```

Access in root module:

```
module.network.vpc_id
```

---

# Minute 15–20: Variables, Locals, Outputs

## Input Variables

Variables make configurations reusable.

Example:

```hcl
variable "region" {
  type = string
}
```

Reference:

```
var.region
```

---

## Variable Loading Priority (IMPORTANT)

Highest → lowest:

1. CLI `-var`
2. CLI `-var-file`
3. `*.auto.tfvars`
4. `terraform.tfvars`
5. environment variables
6. defaults

---

## Environment Variables

Example:

```
TF_VAR_region=us-east-1
```

Sets:

```
var.region
```

---

## Local Values

Used for reusable expressions.

Example:

```hcl
locals {
  name_prefix = "prod"
}
```

Reference:

```
local.name_prefix
```

---

## Outputs

Outputs display resource data.

Example:

```hcl
output "public_ip" {
  value = aws_instance.web.public_ip
}
```

Retrieve with:

```
terraform output
```

---

# Minute 20–25: Terraform Language & Meta Arguments

## Count

Creates multiple instances.

Example:

```hcl
resource "aws_instance" "web" {
  count = 3
}
```

Access instance:

```
aws_instance.web[0]
```

---

## For_each

Better for collections.

Example:

```hcl
for_each = toset(["a","b","c"])
```

Reference:

```
each.key
each.value
```

---

## Lifecycle Rules

Lifecycle meta-arguments modify behavior.

Example:

```hcl
lifecycle {
  prevent_destroy = true
}
```

Prevents accidental deletion.

---

### create_before_destroy

Ensures replacement happens safely.

Example:

```hcl
lifecycle {
  create_before_destroy = true
}
```

Prevents downtime.

---

### ignore_changes

Ignore manual changes.

Example:

```hcl
lifecycle {
  ignore_changes = [tags]
}
```

---

# Minute 25–28: Terraform Cloud & Workspaces

## Terraform Cloud

Terraform Cloud provides:

- remote execution
- remote state
- team collaboration
- policy enforcement

Policy engine used:

```
Sentinel
```

---

## Workspaces

Workspaces manage multiple environments.

Example:

```
terraform workspace new dev
terraform workspace select prod
```

Each workspace has **separate state**.

---

# Minute 28–30: Rapid Exam Cheat Sheet

Memorize these commands.

| Command                | Purpose               |
| ---------------------- | --------------------- |
| `terraform init`       | initialize directory  |
| `terraform plan`       | preview changes       |
| `terraform apply`      | apply changes         |
| `terraform destroy`    | delete infrastructure |
| `terraform fmt`        | format code           |
| `terraform validate`   | validate syntax       |
| `terraform state list` | show state resources  |
| `terraform import`     | import existing infra |

---

## Terraform Execution Model

Terraform builds a:

```
Dependency Graph
```

This allows:

- correct resource order
- parallel execution

Command to visualize:

```
terraform graph
```

---

# Final 10 Exam Reminders

1️⃣ `terraform plan` does NOT change infrastructure

2️⃣ `terraform apply` runs **plan automatically**

3️⃣ state file contains **sensitive data**

4️⃣ `terraform init` required when:

- providers change
- modules change
- backend changes

5️⃣ `for_each` safer than `count` for dynamic resources

6️⃣ `terraform state rm` removes from state only

7️⃣ remote state enables **team collaboration**

8️⃣ module outputs referenced with:

```
module.<name>.<output>
```

9️⃣ environment variables must start with:

```
TF_VAR_
```

🔟 Terraform **does NOT detect resources automatically** unless imported.

---

# Final Mindset Before Exam

Questions usually test:

- **Terraform workflow**
- **state behavior**
- **CLI commands**
- **modules**
- **dependency graph**

Less focus on writing code, more on **understanding Terraform behavior**.

---

If you'd like, I can also give you:

- **The 15 Terraform questions that appear almost every exam**
- **A visual Terraform architecture diagram**
- **A 10-minute cram sheet to memorize everything quickly before the test**.
