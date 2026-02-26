# Terraform Learning Path (Exam Focused)

Hands-on topics aligned with Terraform Associate certification.

## Topics

| #   | Topic                                        | Folder                | Exam Relevance   |
| --- | -------------------------------------------- | --------------------- | ---------------- |
| 1   | **Basics** – First resource, init/plan/apply | topic-01-basics       | Core workflow    |
| 2   | **State** – Understanding tfstate            | topic-02-state        | State management |
| 3   | **Variables** – Reusable config              | topic-03-variables    | Configuration    |
| 4   | **Outputs** – Exposing values                | topic-04-outputs      | Configuration    |
| 5   | **Data Sources** – Read existing resources   | topic-05-data-sources | Providers        |
| 6   | **VPC** – Networking                         | topic-06-vpc          | AWS resources    |
| 7   | **EC2** – Compute                            | topic-07-ec2          | AWS resources    |
| 8   | **Modules** – Reusable blocks                | topic-08-modules      | Modules          |
| 9   | **Backend** – Remote state                   | topic-09-backend      | State            |

## How to Use

1. `cd` into each topic folder
2. Read the comments in the `.tf` files
3. Run the commands shown
4. Complete the practice exercise before moving on

## Commands You Must Know (Exam)

```bash
terraform init      # Initialize providers, backend
terraform plan      # Preview changes (dry run)
terraform apply     # Create/update resources
terraform destroy   # Remove all managed resources
terraform fmt       # Format .tf files
terraform validate  # Check syntax
terraform output    # Show output values
```
