# Topic 5: Data Sources
#
# Data sources READ existing resources – they don't create anything.
# Use them to reference infrastructure outside your config.
#
# Requires AWS credentials. Run: source ../../aws.cred
# Then: terraform init
#       terraform apply -auto-approve

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Reads current caller – no resources to create first
data "aws_caller_identity" "current" {}

# Reads current region from provider config
data "aws_region" "current" {}

output "account_id" {
  description = "AWS account ID of the caller"
  value       = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  description = "ARN of the IAM user/role running Terraform"
  value       = data.aws_caller_identity.current.arn
}

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}
