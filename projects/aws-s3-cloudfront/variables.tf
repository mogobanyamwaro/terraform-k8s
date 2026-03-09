variable "aws_region" {
  description = "AWS region for S3 and CloudFront"
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

variable "bucket_name_prefix" {
  description = "Prefix for S3 bucket name; account ID is appended for uniqueness (e.g. myapp-uploads -> myapp-uploads-123456789012)"
  type        = string
  default     = "myapp-uploads"
}

variable "project_name" {
  description = "Project label for resource names"
  type        = string
  default     = "uploads"
}
