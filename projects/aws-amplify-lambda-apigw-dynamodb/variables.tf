variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key_id" {
  description = "AWS access key (optional; uses AWS_ACCESS_KEY_ID env if empty)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret key (optional; uses AWS_SECRET_ACCESS_KEY env if empty)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "project_name" {
  description = "Project label for resource names"
  type        = string
  default     = "app"
}

# -----------------------------------------------------------------------------
# DynamoDB
# -----------------------------------------------------------------------------

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "items"
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode: PROVISIONED or PAY_PER_REQUEST"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "dynamodb_hash_key" {
  description = "DynamoDB table hash key attribute name"
  type        = string
  default     = "id"
}

# -----------------------------------------------------------------------------
# Lambda
# -----------------------------------------------------------------------------

variable "lambda_runtime" {
  description = "Lambda runtime (e.g. nodejs20.x, python3.12)"
  type        = string
  default     = "nodejs20.x"
}

variable "lambda_handler" {
  description = "Lambda handler entrypoint (e.g. index.handler)"
  type        = string
  default     = "index.handler"
}

# -----------------------------------------------------------------------------
# API Gateway
# -----------------------------------------------------------------------------

variable "api_gateway_stage_name" {
  description = "API Gateway deployment stage name"
  type        = string
  default     = "default"
}

# -----------------------------------------------------------------------------
# Amplify
# -----------------------------------------------------------------------------

variable "amplify_repository" {
  description = "Amplify Git repository URL (e.g. https://github.com/user/repo or git@github.com:user/repo.git). Leave empty to create app without repo."
  type        = string
  default     = ""
}

variable "amplify_branch" {
  description = "Amplify branch to build and deploy (e.g. main)"
  type        = string
  default     = "main"
}

variable "amplify_enable_auto_branch_creation" {
  description = "Enable automatic branch creation for Amplify"
  type        = bool
  default     = false
}
