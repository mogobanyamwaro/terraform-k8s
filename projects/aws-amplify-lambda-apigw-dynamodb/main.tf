# =============================================================================
# AWS Stack: Amplify + Lambda + API Gateway + DynamoDB
# =============================================================================
#
# This file defines a full serverless stack:
#   1. DynamoDB  – NoSQL table used as the backend store.
#   2. Lambda    – Node.js function that implements the REST API (POST /add, GET /results).
#   3. API Gateway – HTTP API with two routes only: POST /add and GET /results → Lambda.
#   4. Amplify   – Hosting for the frontend; optionally linked to a Git repo.
#
# Flow: Client → API Gateway → Lambda → DynamoDB. The Amplify app gets the API
# base URL via NEXT_PUBLIC_API_URL so the frontend can call this API.
# =============================================================================

# -----------------------------------------------------------------------------
# DynamoDB table
# -----------------------------------------------------------------------------
# Single table for the app (e.g. "items"). Hash key is configurable (default: id).
# Billing mode can be PAY_PER_REQUEST (default) or PROVISIONED (needs read/write capacity).

resource "aws_dynamodb_table" "main" {
  name         = "${var.project_name}-${var.dynamodb_table_name}"
  billing_mode = var.dynamodb_billing_mode
  hash_key     = var.dynamodb_hash_key

  # Only the hash key attribute is declared; other attributes are schema-less.
  attribute {
    name = var.dynamodb_hash_key
    type = "S"
  }

  tags = {
    Name    = "${var.project_name}-${var.dynamodb_table_name}"
    Project = var.project_name
  }
}

# -----------------------------------------------------------------------------
# Lambda: IAM role and policy
# -----------------------------------------------------------------------------
# Lambda runs under this role. The role must be allowed to:
#   - Write logs to CloudWatch (so you can debug).
#   - Read/write the DynamoDB table (Scan, GetItem, PutItem, etc.).

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role"

  # Only the Lambda service can assume this role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = { Project = var.project_name }
}

resource "aws_iam_role_policy" "lambda" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch Logs: required for Lambda to create log streams and write logs.
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      },
      # DynamoDB: full read/write on the table (and its items via the /* ARN).
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem", "dynamodb:Scan", "dynamodb:Query", "dynamodb:BatchGetItem", "dynamodb:BatchWriteItem"]
        Resource = [aws_dynamodb_table.main.arn, "${aws_dynamodb_table.main.arn}/*"]
      }
    ]
  })
}

# Used in the policy above to scope logs and in Lambda env for the table name.
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# Lambda: package and function
# -----------------------------------------------------------------------------
# The handler code lives in lambda_src/ and uses AWS SDK v3 (bundled via npm).
# Run npm install in lambda_src before zipping so node_modules is included
# (Node 18+ Lambda runtimes no longer include the legacy aws-sdk).

resource "null_resource" "lambda_npm" {
  triggers = {
    package = filemd5("${path.module}/lambda_src/package.json")
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

resource "aws_lambda_function" "api" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-api"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = var.lambda_runtime

  # Injected into the Lambda process; lambda_src reads process.env.TABLE_NAME.
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.main.name
    }
  }

  tags = {
    Name    = "${var.project_name}-api"
    Project = var.project_name
  }
}

# -----------------------------------------------------------------------------
# API Gateway HTTP API + Lambda integration
# -----------------------------------------------------------------------------
# HTTP API (v2) with exactly two routes: POST /add and GET /results. Both invoke
# the same Lambda. CORS is enabled so browser-based frontends (e.g. Amplify) can call the API.

resource "aws_apigatewayv2_api" "http" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
  description   = "API for ${var.project_name}"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["*"]
  }

  tags = { Project = var.project_name }
}

# Every request to these routes is forwarded to the Lambda (payload format 2.0).
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

# Only two endpoints: POST /add and GET /results.
resource "aws_apigatewayv2_route" "post_add" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /add"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_results" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /results"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Stage (e.g. "default") determines the base path and URL. auto_deploy
# pushes route/config changes to this stage without a separate deployment step.
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = var.api_gateway_stage_name
  auto_deploy = true

  tags = { Project = var.project_name }
}

# Without this, API Gateway is not allowed to invoke the Lambda. The source_arn
# restricts the permission to this API's execution role so only this API can call the function.
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

# -----------------------------------------------------------------------------
# Amplify app (optional Git repo connection)
# -----------------------------------------------------------------------------
# Amplify hosts the frontend. If amplify_repository is set, the app is linked
# to that repo; aws_amplify_branch (below) creates the branch to build/deploy.
# NEXT_PUBLIC_API_URL is set so the frontend can call the API Gateway URL.
# build_spec defines how Amplify builds the app (here: npm ci + npm run build, output .next).

resource "aws_amplify_app" "main" {
  name        = var.project_name
  description = "Amplify app for ${var.project_name}"

  # Optional: set in tfvars to connect a Git repo; leave empty to connect later in the Console.
  repository = var.amplify_repository != "" ? var.amplify_repository : null

  enable_auto_branch_creation = var.amplify_enable_auto_branch_creation
  auto_branch_creation_patterns = var.amplify_enable_auto_branch_creation ? ["feature/*", "develop"] : []

  # Exposed to the build and at runtime; frontend uses this as the API base URL.
  environment_variables = {
    NEXT_PUBLIC_API_URL = aws_apigatewayv2_stage.default.invoke_url
  }

  # Amplify build steps and output (tuned for Next.js). Change baseDirectory/commands for other frameworks.
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands: []
        build:
          commands:
            - npm ci
            - npm run build
      artifacts:
        baseDirectory: .next
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
    EOT

  tags = {
    Name    = var.project_name
    Project = var.project_name
  }
}

# Only created when a repository is set. Links the Git branch to the Amplify app
# so pushes to that branch trigger a build and deploy. stage = PRODUCTION enables
# branch-specific URLs (e.g. main.xxx.amplifyapp.com).
resource "aws_amplify_branch" "main" {
  count = var.amplify_repository != "" ? 1 : 0

  app_id      = aws_amplify_app.main.id
  branch_name = var.amplify_branch
  framework   = "Next.js - SSR"
  stage       = "PRODUCTION"
}
