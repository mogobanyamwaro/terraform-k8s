# Amplify + Lambda + API Gateway + DynamoDB (Terraform)

Creates an AWS stack:

- **DynamoDB** – table with configurable name and hash key (default: `id`)
- **Lambda** – Node.js function that serves CRUD-style API (GET/POST `/items`) using the table
- **API Gateway** – HTTP API with proxy integration to Lambda; CORS enabled
- **Amplify** – app (optionally connected to a Git repo) with env var `NEXT_PUBLIC_API_URL` set to the API URL

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- AWS credentials with permissions for:
  - DynamoDB, Lambda, API Gateway, Amplify, IAM, CloudWatch Logs

Set credentials before running Terraform, e.g.:

```bash
export AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... AWS_REGION=us-east-1
```

## Usage

1. **Copy and edit variables**

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

   Edit `project_name`, `dynamodb_*`, and optionally `amplify_repository` / `amplify_branch`.

2. **Apply**

   ```bash
   cd projects/aws-amplify-lambda-apigw-dynamodb
   terraform init
   terraform plan
   terraform apply
   ```

3. **Use the API**

   After apply, use the invoke URL from outputs:

   ```bash
   export API_URL=$(terraform output -raw api_gateway_invoke_url)

   # List items
   curl "$API_URL/items"

   # Create item
   curl -X POST "$API_URL/items" -H "Content-Type: application/json" -d '{"name":"First"}'
   ```

4. **Amplify**

   - If you set `amplify_repository`, the app is linked to that repo and branch; trigger a deploy from the Amplify Console or push to the branch.
   - If you leave `amplify_repository` empty, create the app first with Terraform, then connect a repository in the Amplify Console.
   - Your frontend gets `NEXT_PUBLIC_API_URL` from Amplify environment variables (set by this Terraform).

## Lambda API (default handler)

- `GET /items` – list all items (Scan)
- `GET /items/{id}` – get one item by `id`
- `POST /items` – create item (body: JSON; `id` optional, generated if missing)

Table hash key is configurable via `dynamodb_hash_key` (default `id`).

## Outputs

- `dynamodb_table_name` / `dynamodb_table_arn`
- `lambda_function_name` / `lambda_function_arn`
- `api_gateway_invoke_url` – base URL for the API
- `amplify_app_id` / `amplify_app_default_domain` / `amplify_app_url`

## Customizing

- **Lambda code**: Edit `lambda_src/index.js`, then run `terraform apply` again (zip is rebuilt).
- **Amplify build**: Adjust `build_spec` in `main.tf` for your framework (e.g. different build command or output directory).
- **DynamoDB**: Add GSIs or change billing in `main.tf` and `variables.tf`.

## Cost notes

- DynamoDB: `PAY_PER_REQUEST` (default) charges per request and storage.
- Lambda: free tier includes 1M requests/month.
- API Gateway HTTP API: lower cost than REST API; free tier available.
- Amplify: charges for build minutes and hosting; check current pricing.
