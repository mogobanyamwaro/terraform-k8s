# Email Marketing Application (Terraform)

Creates an AWS stack for simple email campaigns:

- **SES** – Verified sender identity; Lambda sends email via SES.
- **S3** – Bucket for campaign lists (CSV) and optional templates. Upload a CSV under `lists/` to trigger a send.
- **Lambda** – Reads the CSV from S3 and sends one email per row via SES.
- **EventBridge** – Rule that runs when an object is created in S3 under `lists/`; invokes the Lambda.
- **IAM** – Role and policies for Lambda (S3 read, SES send, CloudWatch Logs); permission for EventBridge to invoke Lambda.

## Prerequisites

- Terraform >= 1.0
- AWS credentials with permissions for S3, Lambda, SES, EventBridge, IAM, CloudWatch
- **SES**: In sandbox, verify both the sender email and each recipient (or move out of sandbox for production).

## Usage

1. **Copy and set variables**

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

   Set `ses_from_email` to an address you will **verify in the SES console** (e.g. AWS Console → SES → Verified identities → Create identity → Email).

2. **Apply**

   ```bash
   cd projects/aws-email-marketing
   terraform init
   terraform plan
   terraform apply
   ```

3. **Verify the sender in SES**

   If the identity is new, open **SES → Verified identities**, find the email, and complete verification (click the link in the email AWS sends).

4. **Run a campaign**

   - Create a CSV with at least an `email` column; optional `name` for personalization:
     ```csv
     email,name
     user1@example.com,Alice
     user2@example.com,Bob
     ```
   - Upload it to S3 under the `lists/` prefix:
     ```bash
     aws s3 cp campaign.csv s3://$(terraform output -raw s3_bucket_name)/lists/campaign.csv
     ```
   - EventBridge will receive the S3 event and invoke the Lambda; the Lambda will read the CSV and send one email per row via SES.

## CSV format

- Header row required; must include an **email** column (case-insensitive).
- Optional **name** column; used in the body as “Hi {name}, …”.
- Other columns are ignored.

## Customizing the email

Edit `lambda_src/index.js`: change `DEFAULT_SUBJECT` and `DEFAULT_BODY_TEXT`, or add logic to read an HTML/text template from S3 (e.g. from a `templates/` prefix) and use it in the Lambda.

## Cost notes

- **SES**: Pay per email sent; free tier available.
- **S3**: Storage and requests; free tier available.
- **Lambda**: Invocations and duration; free tier available.
- **EventBridge**: Events ingested; free tier available.
