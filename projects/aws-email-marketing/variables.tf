variable "aws_region" {
  description = "AWS region (SES must be in a supported region, e.g. us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key_id" {
  description = "AWS access key (optional; uses env if empty)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret key (optional; uses env if empty)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "project_name" {
  description = "Project label for resource names"
  type        = string
  default     = "email-marketing"
}

# -----------------------------------------------------------------------------
# SES
# -----------------------------------------------------------------------------

variable "ses_from_email" {
  description = "Verified sender email address (must be verified in SES). Used as From for campaigns."
  type        = string
}

variable "ses_reply_to" {
  description = "Optional Reply-To address"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# S3
# -----------------------------------------------------------------------------

variable "s3_bucket_prefix" {
  description = "Prefix for S3 bucket name (account ID is appended for uniqueness)"
  type        = string
  default     = "email-marketing"
}

# -----------------------------------------------------------------------------
# Lambda
# -----------------------------------------------------------------------------

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "nodejs20.x"
}

# -----------------------------------------------------------------------------
# EventBridge
# -----------------------------------------------------------------------------

variable "eventbridge_s3_prefix" {
  description = "S3 prefix that triggers Lambda (e.g. lists/). Only objects under this prefix trigger the rule."
  type        = string
  default     = "lists/"
}
