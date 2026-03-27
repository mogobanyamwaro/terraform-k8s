<!-- https://github.com/devenes/HashiCorp-Certified-Terraform-Associate -->
<!-- https://github.com/anuvindhs/Terraform-exam-StudyNotes?tab=readme-ov-file -->

## 🎯 Top Terraform Commands for Exam (80% Coverage)

Based on exam patterns, these are the commands you MUST practice. Focus on these for the highest yield.

---

## 1. **Core Workflow Commands** (35% of exam)

```bash
# INITIALIZATION
terraform init                      # Initialize working directory
terraform init -upgrade             # Upgrade modules and plugins
terraform init -reconfigure         # Reconfigure backend (ignore existing config)
terraform init -backend=false       # Skip backend initialization

# VALIDATION & FORMATTING
terraform fmt                       # Format code (auto-fix)
terraform fmt -check                # Check formatting without changing
terraform fmt -recursive            # Format all subdirectories
terraform validate                  # Validate configuration syntax
terraform validate -json            # JSON output for CI/CD

# PLANNING
terraform plan                      # Show execution plan
terraform plan -out=FILE            # Save plan to file
terraform plan -destroy             # Plan for destruction
terraform plan -refresh=false       # Skip refresh
terraform plan -target=resource     # Plan specific resource
terraform plan -var-file=FILE       # Use variable file
terraform plan -detailed-exitcode   # Exit code: 0=no changes, 1=error, 2=changes

# APPLYING
terraform apply                     # Apply changes
terraform apply -auto-approve       # Apply without confirmation
terraform apply FILE.tfplan         # Apply saved plan
terraform apply -destroy            # Destroy all resources
terraform apply -target=resource    # Apply specific resource
terraform apply -refresh-only       # Update state without changing infrastructure

# DESTROYING
terraform destroy                   # Destroy all resources
terraform destroy -target=resource  # Destroy specific resource
terraform destroy -auto-approve     # Destroy without confirmation
```

---

## 2. **State Management Commands** (25% of exam)

```bash
# STATE INSPECTION
terraform state list                # List all resources in state
terraform state list module.vpc     # List resources in module
terraform state show aws_instance.web  # Show resource details
terraform state show -no-color      # Show without color codes

# STATE MANIPULATION
terraform state mv aws_instance.old aws_instance.new  # Rename resource
terraform state mv module.old module.new              # Move to module
terraform state rm aws_instance.web                   # Remove from state
terraform state pull                 # Download state to stdout
terraform state push                 # Upload local state to backend

# STATE ADVANCED
terraform refresh                    # Sync state with real resources (deprecated)
terraform apply -refresh-only        # Modern refresh (preferred)
terraform state replace-provider "registry.terraform.io/-/aws" "hashicorp/aws"

# IMPORTING
terraform import aws_instance.web i-1234567890abcdef0   # Import existing resource
terraform import module.vpc.aws_vpc.main vpc-12345     # Import into module
```

---

## 3. **Workspace Commands** (15% of exam)

```bash
# WORKSPACE MANAGEMENT
terraform workspace list             # List all workspaces
terraform workspace show             # Show current workspace
terraform workspace new dev          # Create new workspace
terraform workspace new -state=path  # Create with existing state
terraform workspace select dev       # Switch workspace
terraform workspace delete dev       # Delete workspace

# WORKSPACE IN ACTION
terraform workspace select staging
terraform plan -out=staging.tfplan
terraform apply staging.tfplan
```

---

## 4. **Module Commands** (10% of exam)

```bash
# MODULE MANAGEMENT
terraform get                        # Download modules
terraform get -update                # Update modules
terraform init -upgrade              # Upgrade modules (alternative)

# MODULE SOURCING
# In config:
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
}
```

---

## 5. **Output Commands** (5% of exam)

```bash
terraform output                     # Show all outputs
terraform output instance_id         # Show specific output
terraform output -json               # JSON format
terraform output -raw                # Raw string (no quotes)
```

---

## 6. **Graph & Debug Commands** (5% of exam)

```bash
# GRAPH
terraform graph                      # Generate dependency graph (DOT format)
terraform graph | dot -Tpng > graph.png   # Visualize graph

# DEBUGGING
export TF_LOG=DEBUG                  # Enable debug logging
export TF_LOG_PATH=terraform.log     # Log to file
export TF_LOG=TRACE                  # Most verbose
export TF_LOG=ERROR                  # Only errors

# VERSION & HELP
terraform version                    # Show version
terraform version -json              # JSON format
terraform providers                  # Show provider requirements
terraform providers schema -json     # Show provider schemas
terraform -help                      # General help
terraform plan -help                 # Command-specific help
```

---

## 7. **Variable & Output Commands** (5% of exam)

```bash
# VARIABLE FILES
terraform plan -var="instance_type=t2.micro"              # Single variable
terraform plan -var-file="prod.tfvars"                    # Variable file
terraform plan -var-file="prod.tfvars" -var-file="secrets.tfvars"

# AUTO-LOADING (no command needed)
# Files auto-loaded: terraform.tfvars, terraform.tfvars.json, *.auto.tfvars
```

---

## 📊 **Exam Command Priority Matrix**

| Priority        | Command                | Frequency      | Why Important                    |
| --------------- | ---------------------- | -------------- | -------------------------------- |
| 🔴 **Critical** | `terraform init`       | Every run      | First command always             |
| 🔴 **Critical** | `terraform plan`       | Every change   | Understand before apply          |
| 🔴 **Critical** | `terraform apply`      | Every deploy   | Execute changes                  |
| 🔴 **Critical** | `terraform state list` | Debugging      | Know what's managed              |
| 🟠 **High**     | `terraform validate`   | Before plan    | Catch syntax errors              |
| 🟠 **High**     | `terraform fmt`        | Before commit  | Code style                       |
| 🟠 **High**     | `terraform destroy`    | Cleanup        | Remove infrastructure            |
| 🟠 **High**     | `terraform workspace`  | Multi-env      | Environment isolation            |
| 🟡 **Medium**   | `terraform import`     | Existing infra | Bring resources under management |
| 🟡 **Medium**   | `terraform state mv`   | Refactoring    | Rename/move resources            |
| 🟡 **Medium**   | `terraform output`     | After apply    | Get resource values              |
| 🟢 **Low**      | `terraform graph`      | Visualization  | Understand dependencies          |
| 🟢 **Low**      | `terraform refresh`    | Sync state     | Deprecated, use refresh-only     |

---

## 🎯 **Exam Scenario Practice**

### Scenario 1: First Time Setup

```bash
# 1. Write configuration
vim main.tf

# 2. Format code
terraform fmt

# 3. Initialize
terraform init

# 4. Validate
terraform validate

# 5. Plan
terraform plan -out=plan.tfplan

# 6. Apply
terraform apply plan.tfplan
```

### Scenario 2: After Code Change

```bash
# 1. Format and validate
terraform fmt -check
terraform validate

# 2. Plan to see changes
terraform plan

# 3. Apply if good
terraform apply
```

### Scenario 3: Multi-Environment

```bash
# 1. Create workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# 2. Deploy to dev
terraform workspace select dev
terraform apply -var-file="dev.tfvars"

# 3. Deploy to staging
terraform workspace select staging
terraform apply -var-file="staging.tfvars"

# 4. List workspaces
terraform workspace list
```

### Scenario 4: Debugging

```bash
# 1. Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=debug.log

# 2. Run command
terraform plan

# 3. Check log
cat debug.log

# 4. Disable debug
unset TF_LOG
```

### Scenario 5: State Recovery

```bash
# 1. Backup current state
terraform state pull > backup.tfstate

# 2. List resources
terraform state list

# 3. Fix state (remove broken resource)
terraform state rm aws_instance.broken

# 4. Import resource if needed
terraform import aws_instance.fixed i-12345

# 5. Verify
terraform plan
```

---

## 📝 **Quick Reference Card**

```bash
# MOST COMMON WORKFLOW
terraform init && terraform validate && terraform plan && terraform apply

# STATE COMMANDS
terraform state list                    # What's managed?
terraform state show <resource>         # Show details
terraform state mv <old> <new>          # Rename
terraform state rm <resource>           # Remove from management

# WORKSPACES
terraform workspace new <name>          # Create
terraform workspace select <name>       # Switch
terraform workspace list                # List all

# DEBUGGING
export TF_LOG=DEBUG                     # Enable debug
terraform plan                          # Run with debug
unset TF_LOG                            # Disable debug

# PLAN WITH DETAILS
terraform plan -detailed-exitcode       # Check for changes (0,1,2)
terraform plan -refresh-only            # Detect drift only
terraform plan -out=plan.tfplan         # Save plan
```

---

## ✅ **Exam Tips**

1. **Always `init` first** - Before any plan/apply
2. **Always `validate` before `plan`** - Catch syntax errors early
3. **Always `plan` before `apply`** - Know what will change
4. **Use `-out` flag** - Save plans for audit
5. **Workspace commands** - Know how to create and switch
6. **State commands** - Know `list`, `show`, `mv`, `rm`
7. **`-refresh-only`** - New way to sync state (not `refresh`)
8. **Exit codes** - Know `plan -detailed-exitcode` outputs

---

**Practice these commands daily - they cover 80% of exam questions!** 🎯

## 🎯 Most Common Terraform Variables in Exams

---

## 1. **Variable Declaration Types** (Critical for Exam)

### Basic Variable Types

```hcl
# STRING - Most common
variable "instance_type" {
  type    = string
  default = "t2.micro"
}

# NUMBER
variable "instance_count" {
  type    = number
  default = 3
}

# BOOLEAN
variable "enable_monitoring" {
  type    = bool
  default = true
}

# LIST
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

# MAP
variable "tags" {
  type    = map(string)
  default = {
    Environment = "dev"
    Team        = "platform"
  }
}

# OBJECT (Complex type)
variable "instance_config" {
  type = object({
    name    = string
    type    = string
    volume  = number
    tags    = map(string)
  })
  default = {
    name   = "web-server"
    type   = "t2.micro"
    volume = 20
    tags   = { Env = "dev" }
  }
}
```

---

## 2. **Variable Input Methods** (Exam Heavy)

### Method 1: Command Line

```bash
# Simple variable
terraform plan -var="instance_type=t2.large"

# Multiple variables
terraform apply -var="instance_type=t2.large" -var="instance_count=5"

# Boolean
terraform apply -var="enable_monitoring=true"
```

### Method 2: Variable Files (.tfvars)

```bash
# dev.tfvars
instance_type      = "t2.micro"
instance_count     = 1
enable_monitoring  = false
environment        = "dev"

# prod.tfvars
instance_type      = "t2.large"
instance_count     = 5
enable_monitoring  = true
environment        = "prod"

# Usage
terraform apply -var-file="prod.tfvars"
terraform apply -var-file="dev.tfvars" -var-file="secrets.tfvars"
```

### Method 3: Environment Variables

```bash
# Prefix with TF_VAR_
export TF_VAR_instance_type="t2.micro"
export TF_VAR_instance_count=3
export TF_VAR_tags='{"Name":"web","Env":"prod"}'

terraform apply  # Automatically picks up environment variables
```

### Method 4: Auto-loaded Files

```bash
# Files automatically loaded (no -var-file needed)
terraform.tfvars          # Always loaded
terraform.tfvars.json     # JSON format
*.auto.tfvars            # Any .auto.tfvars files
*.auto.tfvars.json       # Any .auto.tfvars.json files

# Priority (higher overrides lower):
# 1. Command line (-var)
# 2. Environment variables (TF_VAR_)
# 3. terraform.tfvars
# 4. *.auto.tfvars
# 5. Variable defaults
```

---

## 3. **Variable Validation** (Exam Critical)

```hcl
variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_type" {
  type = string

  validation {
    condition     = can(regex("^t[2-3]\\.[a-z]+$", var.instance_type))
    error_message = "Instance type must be t2 or t3 family."
  }
}

variable "instance_count" {
  type = number

  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "tags" {
  type = map(string)

  validation {
    condition = alltrue([
      for k, v in var.tags : length(k) > 0 && length(v) > 0
    ])
    error_message = "All tag keys and values must be non-empty."
  }
}

variable "cidr_block" {
  type = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "CIDR block must be valid."
  }
}
```

---

## 4. **Sensitive Variables**

```hcl
# Mark variable as sensitive (won't show in logs/outputs)
variable "db_password" {
  type      = string
  sensitive = true
}

variable "api_key" {
  type      = string
  sensitive = true
  default   = "default-key"  # Not recommended to have default
}

# Usage
resource "aws_db_instance" "database" {
  password = var.db_password  # Will be marked sensitive in logs
}

# Output marked as sensitive
output "db_password" {
  value     = var.db_password
  sensitive = true  # Won't show in console
}
```

---

## 5. **Common Variable Patterns in Resources**

### Pattern 1: String Variables

```hcl
variable "instance_name" {
  type    = string
  default = "web-server"
}

variable "ami_id" {
  type    = string
  default = "ami-0c55b159cbfafe1f0"
}

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type  # from another var
  tags = {
    Name = var.instance_name
  }
}
```

### Pattern 2: Number Variables

```hcl
variable "instance_count" {
  type    = number
  default = 3
}

variable "root_volume_size" {
  type    = number
  default = 20
}

resource "aws_instance" "web" {
  count = var.instance_count

  root_block_device {
    volume_size = var.root_volume_size
  }
}
```

### Pattern 3: List Variables

```hcl
variable "subnet_ids" {
  type    = list(string)
  default = ["subnet-abc", "subnet-def"]
}

variable "security_groups" {
  type    = list(string)
  default = ["sg-123", "sg-456"]
}

resource "aws_instance" "web" {
  count                  = length(var.subnet_ids)
  subnet_id              = var.subnet_ids[count.index]
  vpc_security_group_ids = var.security_groups
}
```

### Pattern 4: Map Variables

```hcl
variable "instance_tags" {
  type = map(string)
  default = {
    Environment = "production"
    Team        = "platform"
    CostCenter  = "engineering"
  }
}

variable "environment_config" {
  type = map(object({
    instance_type = string
    instance_count = number
    enable_backup = bool
  }))
  default = {
    dev = {
      instance_type  = "t2.micro"
      instance_count = 1
      enable_backup  = false
    }
    prod = {
      instance_type  = "t2.large"
      instance_count = 5
      enable_backup  = true
    }
  }
}

resource "aws_instance" "web" {
  instance_type = var.environment_config[var.environment].instance_type
  count         = var.environment_config[var.environment].instance_count
  tags          = var.instance_tags
}
```

---

## 6. **Local Values vs Variables** (Common Confusion)

```hcl
# Variables - Input from outside
variable "environment" {
  type    = string
  default = "dev"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

# Locals - Derived values, reusable expressions
locals {
  # Derived from variables
  full_name = "${var.environment}-server"

  # Complex logic
  is_production = var.environment == "prod"

  # Map lookup
  instance_config = {
    dev  = "t2.micro"
    prod = "t2.large"
  }

  # Computed value
  instance_type = local.instance_config[var.environment]

  # Conditional
  backup_enabled = var.environment == "prod" ? true : false
}

resource "aws_instance" "web" {
  instance_type = local.instance_type
  tags = {
    Name = local.full_name
  }
}
```

---

## 7. **Variable Precedence** (Exam Critical)

```bash
# Priority Order (Highest to Lowest):
# 1. Command line -var
terraform apply -var="instance_type=t2.nano"

# 2. Environment variables
export TF_VAR_instance_type="t2.small"

# 3. terraform.tfvars
instance_type = "t2.medium"

# 4. *.auto.tfvars
# dev.auto.tfvars: instance_type = "t2.micro"

# 5. Variable defaults
variable "instance_type" {
  default = "t2.large"
}
```

---

## 8. **Complex Variable Examples**

### Example 1: List of Objects

```hcl
variable "instances" {
  type = list(object({
    name         = string
    instance_type = string
    subnet_id    = string
  }))
  default = [
    {
      name          = "web-1"
      instance_type = "t2.micro"
      subnet_id     = "subnet-abc"
    },
    {
      name          = "web-2"
      instance_type = "t2.micro"
      subnet_id     = "subnet-def"
    }
  ]
}

resource "aws_instance" "web" {
  count         = length(var.instances)
  instance_type = var.instances[count.index].instance_type
  subnet_id     = var.instances[count.index].subnet_id
  tags = {
    Name = var.instances[count.index].name
  }
}
```

### Example 2: Map of Objects with For Each

```hcl
variable "instances" {
  type = map(object({
    instance_type = string
    ami           = string
    subnet_id     = string
  }))
  default = {
    web = {
      instance_type = "t2.micro"
      ami           = "ami-123"
      subnet_id     = "subnet-abc"
    }
    app = {
      instance_type = "t2.small"
      ami           = "ami-456"
      subnet_id     = "subnet-def"
    }
  }
}

resource "aws_instance" "instances" {
  for_each      = var.instances
  instance_type = each.value.instance_type
  ami           = each.value.ami
  subnet_id     = each.value.subnet_id
  tags = {
    Name = each.key
  }
}
```

### Example 3: Optional Variables

```hcl
variable "backup_config" {
  type = object({
    enabled            = bool
    retention_days     = optional(number, 30)  # Default 30 if not set
    backup_window      = optional(string, "03:00-04:00")
    snapshot_identifier = optional(string)      # No default
  })
  default = {
    enabled = true
    # retention_days uses default 30
    # backup_window uses default
    # snapshot_identifier is null
  }
}

resource "aws_db_instance" "database" {
  backup_retention_period = var.backup_config.enabled ? var.backup_config.retention_days : 0
  backup_window          = var.backup_config.backup_window
  final_snapshot_identifier = var.backup_config.snapshot_identifier
}
```

---

## 9. **Variable Functions** (Exam Common)

```hcl
# can() - Check if expression works
variable "optional_value" {
  type    = string
  default = null
}

locals {
  # Use default if variable is null
  value = can(var.optional_value) ? var.optional_value : "default-value"
}

# try() - Safe access with fallback
locals {
  subnet_id = try(var.subnet_ids[0], "subnet-default")
  region    = try(var.region, "us-east-1")
}

# coalesce() - First non-null value
locals {
  instance_type = coalesce(var.instance_type, local.default_type, "t2.micro")
}

# lookup() - Safe map lookup
variable "config" {
  type = map(string)
  default = {
    dev  = "small"
    prod = "large"
  }
}

locals {
  size = lookup(var.config, var.environment, "small")
}
```

---

## 10. **Exam Scenario Practice**

### Scenario 1: Multi-Environment Deployment

```hcl
# variables.tf
variable "environment" {
  type = string
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Invalid environment"
  }
}

variable "instance_sizes" {
  type = map(string)
  default = {
    dev     = "t2.micro"
    staging = "t2.small"
    prod    = "t2.large"
  }
}

# main.tf
resource "aws_instance" "web" {
  instance_type = var.instance_sizes[var.environment]
  tags = {
    Environment = var.environment
  }
}

# Usage
terraform apply -var="environment=prod"
```

### Scenario 2: Conditional Resources

```hcl
variable "create_db" {
  type    = bool
  default = true
}

variable "db_config" {
  type = object({
    instance_class = string
    storage        = number
  })
  default = {
    instance_class = "db.t2.micro"
    storage        = 20
  }
}

resource "aws_db_instance" "database" {
  count = var.create_db ? 1 : 0

  instance_class = var.db_config.instance_class
  allocated_storage = var.db_config.storage
}
```

### Scenario 3: List of Subnets

```hcl
variable "private_subnets" {
  type = list(string)
  description = "List of private subnet IDs"
}

variable "instance_count" {
  type    = number
  default = 1
}

resource "aws_instance" "web" {
  count = var.instance_count

  # Distribute instances across subnets
  subnet_id = var.private_subnets[count.index % length(var.private_subnets)]
}

# Usage
terraform apply -var='private_subnets=["subnet-1","subnet-2","subnet-3"]' -var="instance_count=5"
```

---

## 📊 **Exam Variable Quick Reference**

| Variable Type | Declaration            | Access           | When to Use                   |
| ------------- | ---------------------- | ---------------- | ----------------------------- |
| **String**    | `type = string`        | `var.name`       | Simple values, names, IDs     |
| **Number**    | `type = number`        | `var.count`      | Counts, sizes, ports          |
| **Bool**      | `type = bool`          | `var.enabled`    | Feature flags, conditionals   |
| **List**      | `type = list(string)`  | `var.list[0]`    | Multiple values of same type  |
| **Map**       | `type = map(string)`   | `var.map["key"]` | Lookup tables, configurations |
| **Object**    | `type = object({...})` | `var.obj.field`  | Complex structured data       |

---

## ✅ **Exam Tips for Variables**

1. **Always validate inputs** - Use `validation` blocks
2. **Use sensitive for secrets** - Passwords, keys, tokens
3. **Know precedence** - CLI > Env > tfvars > auto.tfvars > default
4. **Use locals for derived values** - Not for user input
5. **Type constraints** - Always specify types
6. **Map vs Object** - Map for homogeneous, Object for heterogeneous
7. **Optional attributes** - Use `optional()` for flexible objects
8. **Lookup vs direct access** - Use `lookup()` for safe map access

**These variable patterns cover 80% of exam questions!** 🎯

## 🔒 Lock-Related Commands for Exam

---

### **Lock Detection**

```bash
terraform plan                    # Shows lock error if locked
terraform apply                   # Shows lock error if locked
```

### **Lock Bypass**

```bash
terraform plan -lock=false        # Skip lock check
terraform apply -lock=false       # Skip lock acquisition
```

### **Force Unlock**

```bash
terraform force-unlock <LOCK_ID>          # Unlock state
terraform force-unlock -force <LOCK_ID>   # Unlock without confirmation
```

### **Lock Timeout**

```bash
terraform apply -lock-timeout=5m          # Wait 5 minutes for lock
terraform plan -lock-timeout=30s          # Wait 30 seconds
```

### **Backend Lock Configuration (S3)**

```bash
# In backend.tf
dynamodb_table = "terraform-locks"        # Enables locking
# No dynamodb_table = no locking
```

### **Check Lock Status (S3)**

```bash
aws dynamodb get-item --table-name terraform-locks --key '{"LockID":{"S":"bucket/key"}}'
```

---

## ✅ **Exam Quick Reference**

| Command                  | Purpose          |
| ------------------------ | ---------------- |
| `terraform plan`         | Shows lock error |
| `-lock=false`            | Skip locking     |
| `-lock-timeout=5m`       | Wait for lock    |
| `terraform force-unlock` | Release lock     |
| `dynamodb_table`         | Enable locking   |

**Key Point:** Only `force-unlock` is the dedicated unlock command. Everything else is automatic or flags.
