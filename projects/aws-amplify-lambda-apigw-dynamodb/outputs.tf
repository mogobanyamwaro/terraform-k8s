output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.main.name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.main.arn
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.api.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.api.arn
}

output "api_gateway_invoke_url" {
  description = "API Gateway HTTP API invoke URL (use this as your API base URL)"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "api_gateway_id" {
  description = "API Gateway HTTP API ID"
  value       = aws_apigatewayv2_api.http.id
}

output "amplify_app_id" {
  description = "Amplify app ID"
  value       = aws_amplify_app.main.id
}

output "amplify_app_default_domain" {
  description = "Amplify app default domain (after first deploy)"
  value       = "https://${var.amplify_branch}.${aws_amplify_app.main.default_domain}"
}

output "amplify_app_url" {
  description = "Amplify app URL for the main branch"
  value       = var.amplify_repository != "" ? "https://${var.amplify_branch}.${aws_amplify_app.main.default_domain}" : "Set repository and run first deploy in Amplify Console"
}
