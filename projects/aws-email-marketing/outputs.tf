output "s3_bucket_name" {
  description = "S3 bucket for campaign lists (upload CSV files under lists/ to trigger sends)"
  value       = aws_s3_bucket.campaigns.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.campaigns.arn
}

output "lambda_function_name" {
  description = "Lambda function that sends emails from CSV"
  value       = aws_lambda_function.sender.function_name
}

output "ses_sender_email" {
  description = "SES verified sender email (must be verified in SES console if new)"
  value       = aws_ses_email_identity.sender.email
}

output "eventbridge_rule_name" {
  description = "EventBridge rule that triggers Lambda on S3 upload"
  value       = aws_cloudwatch_event_rule.s3_upload.name
}
