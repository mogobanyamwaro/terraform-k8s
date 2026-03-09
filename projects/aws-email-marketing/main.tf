# =============================================================================
# Email Marketing Application: SES + Lambda + S3 + EventBridge + IAM
# =============================================================================
#
# Flow:
#   1. Upload a CSV (email, name, ...) to S3 under the lists/ prefix.
#   2. EventBridge receives S3 Object Created and invokes Lambda.
#   3. Lambda reads the CSV from S3 and sends one email per row via SES.
#
# Resources: S3 bucket, Lambda (with IAM role), SES identity, EventBridge rule.
# =============================================================================

data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# S3 bucket for campaign lists and optional templates
# -----------------------------------------------------------------------------

locals {
  bucket_name = "${var.s3_bucket_prefix}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "campaigns" {
  bucket        = local.bucket_name
  force_destroy = true

  tags = {
    Name    = local.bucket_name
    Project = var.project_name
  }
}

resource "aws_s3_bucket_public_access_block" "campaigns" {
  bucket = aws_s3_bucket.campaigns.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets  = true
}

# Send S3 object events to EventBridge (required for the rule below).
resource "aws_s3_bucket_notification" "campaigns" {
  bucket = aws_s3_bucket.campaigns.id

  eventbridge = true

  depends_on = [aws_s3_bucket_public_access_block.campaigns]
}

# -----------------------------------------------------------------------------
# SES – verified sender identity (you must verify this email in SES)
# -----------------------------------------------------------------------------

resource "aws_ses_email_identity" "sender" {
  email = var.ses_from_email
}

# -----------------------------------------------------------------------------
# IAM – Lambda execution role (S3 read, SES send, CloudWatch Logs)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })

  tags = { Project = var.project_name }
}

data "aws_region" "current" {}

resource "aws_iam_role_policy" "lambda" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.campaigns.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail", "ses:SendRawEmail"]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Lambda – package and function
# -----------------------------------------------------------------------------

resource "null_resource" "lambda_npm" {
  triggers = {
    package  = filemd5("${path.module}/lambda_src/package.json")
    lockfile = fileexists("${path.module}/lambda_src/package-lock.json") ? filemd5("${path.module}/lambda_src/package-lock.json") : ""
  }
  provisioner "local-exec" {
    command = "cd ${path.module}/lambda_src && npm ci"
  }
}

data "archive_file" "lambda_zip" {
  depends_on  = [null_resource.lambda_npm]
  type        = "zip"
  source_dir  = "${path.module}/lambda_src"
  output_path = "${path.module}/build/lambda.zip"
}

resource "aws_lambda_function" "sender" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-sender"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = 60

  environment {
    variables = {
      BUCKET_NAME   = aws_s3_bucket.campaigns.id
      FROM_EMAIL    = var.ses_from_email
      REPLY_TO_EMAIL = var.ses_reply_to != "" ? var.ses_reply_to : var.ses_from_email
    }
  }

  tags = {
    Name    = "${var.project_name}-sender"
    Project = var.project_name
  }
}

# -----------------------------------------------------------------------------
# EventBridge – rule: S3 Object Created → Lambda
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "s3_upload" {
  name        = "${var.project_name}-s3-upload"
  description = "Trigger Lambda when a CSV is uploaded to S3 lists/"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    "detail-type" = ["Object Created"]
    detail = {
      bucket = { name = [aws_s3_bucket.campaigns.id] }
      object = { key = [{ prefix = var.eventbridge_s3_prefix }] }
    }
  })

  tags = { Project = var.project_name }
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.s3_upload.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.sender.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sender.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_upload.arn
}
