# S3 + CloudFront uploads (Terraform)

Creates an S3 bucket and a CloudFront distribution so you can upload files from your app and serve them via a public CDN URL. The bucket is **private**; only CloudFront can read objects (no Access Denied when using the CloudFront URL).

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) installed
- AWS credentials with:
  - `s3:CreateBucket`, `s3:PutBucket*`, `s3:GetBucket*`, `s3:DeleteBucket`
  - `s3:PutObject`, `s3:GetObject`, `s3:DeleteObject`, `s3:PutObjectAcl` on the bucket
  - `cloudfront:CreateDistribution`, `cloudfront:Get*`, `cloudfront:Update*`, `cloudfront:Delete*`
  - `iam:CreateServiceLinkedRole` (for CloudFront if first time in account)

Set credentials before running Terraform, e.g.:

```bash
source /path/to/aws.cred   # or export AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION
```

## Usage

1. **Copy and edit variables**

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

   Set `bucket_name` to a **globally unique** name (e.g. `myapp-uploads-12345` or include your account id).

2. **Apply**

   ```bash
   cd aws-s3-cloudfront
   terraform init
   terraform plan
   terraform apply
   ```

3. **Use the outputs in your Next.js app**

   After `terraform apply`, use:

   - **NEXT_AWS_S3_BUCKET_NAME** = `terraform output -raw s3_bucket_name`
   - **NEXT_CLOUDFRONT_URL** = `terraform output -raw cloudfront_url` (e.g. `https://d1234abcd.cloudfront.net`)
   - **NEXT_AWS_ACCESS_KEY_ID** / **NEXT_AWS_SECRET_ACCESS_KEY** = same IAM user whose creds you used for Terraform (or an IAM user with the S3 permissions above)

   File URLs: `{NEXT_CLOUDFRONT_URL}/{key}` e.g. `https://d1234abcd.cloudfront.net/homecare/uuid-filename.jpg`

   **Required:** Set `NEXT_CLOUDFRONT_URL` in your Next.js app. If you omit it, your API will return the S3 URL, which returns **403** because the bucket is private. Always use the CloudFront URL for viewing images (e.g. in `<img src={fileUrl} />` or `next/image`).

## 403 on images / “upstream image response failed”

The bucket is private; only CloudFront can read. You must:

1. Set in your Next.js env: `NEXT_CLOUDFRONT_URL=https://d2hw4pefm9etu8.cloudfront.net` (or your distribution URL from `terraform output cloudfront_url`).
2. In the upload API, build the public URL from CloudFront only:  
   `fileUrl = process.env.NEXT_CLOUDFRONT_URL ? \`${process.env.NEXT_CLOUDFRONT_URL.replace(/\/$/, '')}/${result.Key}\` : null`  
   and never use `result.Location` (S3 URL) for public access.
3. Use `fileUrl` from the API response everywhere you display the image (e.g. `<img src={fileUrl} />`). Do not use the S3 URL.

## “API resolved without sending a response”

Ensure your upload API sends exactly one response and returns after it. Use a try/catch and always send a response in every path (success and error), and `return` after each `res.*()` call so the handler doesn’t continue.

## Important: remove `ACL: 'public-read'` from uploads

This bucket uses **bucket owner enforced** object ownership (required for CloudFront OAC). ACLs are disabled, so you must **remove** `ACL: 'public-read'` from your S3 upload call to avoid errors.

**Before:**

```js
await s3.upload({
  Bucket: bucket,
  Key: key,
  ContentType: file.mimetype,
  Body: file.buffer,
  ACL: 'public-read',  // remove this
}).promise();
```

**After:**

```js
await s3.upload({
  Bucket: bucket,
  Key: key,
  ContentType: file.mimetype,
  Body: file.buffer,
}).promise();
```

Files are still publicly readable via the **CloudFront** URL; the bucket itself stays private.

## Avoiding timeouts

- Keep `NEXT_CLOUDFRONT_URL` for serving; don’t use the S3 URL for public access.
- Your existing `timeout` / `connectTimeout` and `maxRetries` in the S3 client are fine; ensure the IAM user has the S3 permissions above so uploads don’t fail with Access Denied.

## CloudFront free tier

- 1 TB data transfer out per month
- 10,000,000 HTTP/HTTPS requests per month

Price class is set to `PriceClass_100` (US, Canada, Europe) to stay within typical free-tier usage.
