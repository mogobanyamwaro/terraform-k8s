output "s3_bucket_name" {
  description = "S3 bucket name for NEXT_AWS_S3_BUCKET_NAME"
  value       = aws_s3_bucket.uploads.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.uploads.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain (e.g. d1234abcd.cloudfront.net)"
  value       = aws_cloudfront_distribution.uploads.domain_name
}

output "cloudfront_url" {
  description = "Base URL for uploaded files – use for NEXT_CLOUDFRONT_URL (no trailing slash)"
  value       = "https://${aws_cloudfront_distribution.uploads.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation if needed)"
  value       = aws_cloudfront_distribution.uploads.id
}
