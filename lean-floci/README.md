# Lean Floci — Local Multi-Cloud Stack

Run AWS, Azure, and GCP locally with a web console. No cloud accounts, billing, or real credentials required.

This folder wraps the official [floci-ui](https://github.com/floci-io/floci-ui) Docker Compose stack (AWS + Azure + GCP emulators + web UI).

## What's running

| Service | URL | Purpose |
|---------|-----|---------|
| **Web UI** | http://localhost:4500 | AWS Console–style dashboard |
| **API** | http://localhost:4501 | Backend for the UI |
| **Floci AWS** | http://localhost:4566 | 75 AWS services (S3, Lambda, DynamoDB, EKS, …) |
| **Floci Azure** | http://localhost:4577 | Blob, Queue, Table, Key Vault, … |
| **Floci GCP** | http://localhost:4588 | GCS, Pub/Sub, Firestore, GKE, … |

On first start, seed scripts create sample resources you can browse immediately in the UI:

- **AWS:** S3 buckets (`my-app-bucket`, `logs-bucket`, `static-assets`), SQS queues (`orders-queue`, `notifications-queue`, `dead-letter-queue`)
- **Azure:** containers (`azure-app-container`, `azure-logs-container`, `azure-static-assets`) with sample blobs
- **GCP:** buckets (`gcp-app-bucket`, `gcp-logs-bucket`, `gcp-static-assets`) with sample objects

## Prerequisites

- Docker Desktop (running)
- Optional but useful: [floci CLI](https://floci.io) (`brew install floci-io/floci/floci`), AWS CLI, Azure CLI, gcloud

## Quick start

From this directory:

```bash
make up        # build and start the full stack (background)
make status    # list running containers
make health    # probe all endpoints
make logs      # follow container logs
make down      # stop everything
```

Or use Docker Compose directly:

```bash
cd floci-ui
docker compose --profile multicloud up -d --build
docker compose --profile multicloud down
```

Open the UI: **http://localhost:4500**

Switch clouds from the cloud selector in the sidebar (AWS / Azure / GCP).

## Using the Web UI

1. Open http://localhost:4500
2. Pick a cloud (AWS, Azure, or GCP) from the header/sidebar
3. Use **Console Home** for runtime status and service overview
4. Use **Cloud Explorer** to browse and manage resources by category:

| Category | AWS | Azure | GCP |
|----------|-----|-------|-----|
| Storage | S3 buckets + object browser | Blob containers | Cloud Storage buckets |
| Compute | EC2 instances, AMIs | VMs | — |
| Serverless | Lambda (invoke supported) | coming soon | Cloud Functions |
| Database | RDS | Cosmos DB NoSQL | Firestore / NoSQL |
| k8s Engine | EKS | — | GKE |
| Networking | VPC, subnets, SGs | — | — |
| Secrets | Secrets Manager (dedicated page) | Key Vault | — |

The UI shows only real data from your local emulators — no fake demo rows.

## CLI usage

### AWS (port 4566)

```bash
# If you have floci CLI installed:
eval $(floci env)

# Or set manually:
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

# Examples
aws s3 ls
aws s3 mb s3://demo-bucket
aws sqs create-queue --queue-name my-queue
aws dynamodb create-table \
  --table-name users \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

**S3 tip:** If virtual-hosted-style URLs fail, add path-style addressing to `~/.aws/config`:

```ini
[default]
s3 =
  addressing_style = path
```

Or run `floci doctor --fix` if you use the floci CLI.

### Azure (port 4577)

```bash
export AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:4577/devstoreaccount1;"

az storage container list
az storage container create --name demo-container
echo "hello" > hello.txt
az storage blob upload -c demo-container -f hello.txt -n hello.txt
```

If you have the floci CLI: `eval $(floci az env)`

### GCP (port 4588)

```bash
export CLOUDSDK_API_ENDPOINT_OVERRIDES_STORAGE=http://localhost:4588/
export CLOUDSDK_API_ENDPOINT_OVERRIDES_PUBSUB=http://localhost:4588/
export CLOUDSDK_CORE_PROJECT=floci-local

gcloud storage buckets list
gcloud storage buckets create gs://demo-bucket
echo "hello" > hello.txt
gcloud storage cp hello.txt gs://demo-bucket/
```

If you have the floci CLI: `eval $(floci gcp env)`

## Terraform / IaC

Point provider endpoints at localhost before applying:

**AWS provider:**

```hcl
provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3  = "http://localhost:4566"
    iam = "http://localhost:4566"
    # add other services as needed
  }
}
```

**Azure provider** — use the connection string above or `storage_use_azuread = false` with the dev account endpoint.

**GCP provider** — set custom endpoints via environment variables or provider `storage_custom_endpoint` / `pubsub_custom_endpoint`.

Always run `terraform plan` against Floci first to catch errors before touching a real account.

## Architecture

```text
Browser (localhost:4500)
  → floci-api (localhost:4501)
    → floci AWS   (localhost:4566)
    → floci-az    (localhost:4577)
    → floci-gcp   (localhost:4588)
```

Compose file: `floci-ui/docker-compose.yml`  
Persistent AWS state: `floci-ui/data/` (bind-mounted into the AWS emulator)

## Troubleshooting

**Port already in use**

Stop any standalone Floci containers first:

```bash
floci stop          # if floci CLI is installed
docker stop floci floci-ui 2>/dev/null
make down
make up
```

**UI loads but shows "Not connected"**

Check the API and backends:

```bash
make health
curl http://localhost:4501/api/clouds/aws/status
curl http://localhost:4501/api/clouds/azure/status
curl http://localhost:4501/api/clouds/gcp/status
```

**Rebuild after pulling UI changes**

```bash
cd floci-ui && git pull
make restart
```

**Reset all local state**

```bash
make down
rm -rf floci-ui/data/*
make up
```

## References

- [Floci](https://floci.io) — emulator suite
- [floci-ui](https://github.com/floci-io/floci-ui) — web console (cloned in `floci-ui/`)
- [floci-cli](https://github.com/floci-io/floci-cli) — optional lifecycle CLI
