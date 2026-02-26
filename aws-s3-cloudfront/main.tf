# -----------------------------------------------------------------------------
# S3 bucket for file and image uploads (private; access via CloudFront only)
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  bucket_name = "${var.bucket_name_prefix}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "uploads" {
  bucket        = local.bucket_name
  force_destroy = true  # allow terraform destroy to empty and delete bucket

  tags = {
    Name    = local.bucket_name
    Project = var.project_name
  }
}

# Block all public access; CloudFront will serve via OAC
resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Object ownership: bucket owner enforced (required for OAC; ACLs disabled)
resource "aws_s3_bucket_ownership_controls" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# CORS for browser/Next.js uploads and frontend access
resource "aws_s3_bucket_cors_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

# -----------------------------------------------------------------------------
# CloudFront Origin Access Control (OAC) – recommended over legacy OAI
# -----------------------------------------------------------------------------

resource "aws_cloudfront_origin_access_control" "uploads" {
  name                              = "${var.project_name}-s3-oac"
  description                       = "Grant CloudFront access to S3 bucket ${local.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Bucket policy: allow only this CloudFront distribution to read objects
data "aws_iam_policy_document" "cloudfront_oac" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.uploads.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.uploads.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  policy = data.aws_iam_policy_document.cloudfront_oac.json

  depends_on = [
    aws_s3_bucket_public_access_block.uploads,
    aws_s3_bucket_ownership_controls.uploads,
  ]
}

# -----------------------------------------------------------------------------
# CloudFront distribution (free tier eligible)
# -----------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "uploads" {
  enabled             = true
  is_ipv6_enabled      = true
  comment              = "S3 uploads for ${var.project_name}"
  default_root_object  = ""
  price_class          = "PriceClass_100" # US, Canada, Europe – keeps free tier friendly

  origin {
    domain_name              = aws_s3_bucket.uploads.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.uploads.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.uploads.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.uploads.id}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name    = "${var.project_name}-uploads"
    Project = var.project_name
  }
}
