# Must-Know AWS Services for Platform / DevOps / SRE Engineers

A practical reference for engineers who build, deploy, operate, and secure workloads on AWS. Focus is on services you touch weekly—not every service in the catalog.

Pair this with hands-on projects in [`CURRICULUM.md`](CURRICULUM.md) and local practice on [Floci](../lean-floci/README.md).

---

## How to Use This Guide

| Priority      | Meaning                                      |
| ------------- | -------------------------------------------- |
| **Core**      | Know cold for interviews and day-to-day work |
| **Important** | Common in production; know when and why      |
| **Awareness** | Know it exists and what problem it solves    |

| Floci       | Meaning                                                             |
| ----------- | ------------------------------------------------------------------- |
| **Yes**     | Practice fully on localhost:4566                                    |
| **Partial** | Core workflows work; some prod edge cases need real AWS             |
| **No**      | Org/global services — learn conceptually, practice on AWS free tier |

---

## 1. Identity & Access (Core) ([YouTube](https://www.youtube.com/watch?v=hAk-7ImN6iM))

Everything in AWS starts with **who** can do **what**.

### IAM

- Users, groups, roles, policies (identity-based + resource-based)
- Trust policies for cross-service and cross-account access
- **DevOps use:** CI/CD roles, Lambda execution roles, EKS IRSA, break-glass admin separate from daily ops

### STS (Security Token Service) ([YouTube](https://www.youtube.com/watch?v=T2Nj4BYNMxM))

- Temporary credentials via `AssumeRole`
- **Pattern:** GitHub OIDC → IAM role (no long-lived keys in CI)

### Organizations + IAM Identity Center (Awareness → Important at scale)([YouTube](https://www.youtube.com/watch?v=bQ2EtLnN6KQ))

- Multi-account structure, SCPs, centralized SSO ([YouTube](https://www.youtube.com/watch?v=FR36p7iiRkU)(https://www.youtube.com/watch?v=dCSKJ2XXENw))
- **Floci:** No — graduation project on real AWS

### Key concepts to memorize

```text
Principal → Action → Resource → Condition
Example: lambda.amazonaws.com → sts:AssumeRole → role/app-lambda → aws:SourceAccount=123
```

| Service             | Floci |
| ------------------- | ----- |
| IAM                 | Yes   |
| STS                 | Yes   |
| Organizations / SSO | No    |

**Project:** [`projects/01-iam-foundation.md`](projects/01-iam-foundation.md)

---

## 2. Networking (Core)

Most platform incidents involve networking. Know these deeply.

### VPC([YouTube](https://www.youtube.com/watch?v=43tIX7901Gs))

- CIDR, subnets (public/private), route tables, IGW, NAT gateway, NACLs
- **Design rule:** private workloads, controlled egress, no public DBs

### Security Groups + NACLs([YouTube](https://www.youtube.com/watch?v=J4t2vBf9cOo))

- SG: stateful, instance/ENI level (primary tool)
- NACL: stateless, subnet level (coarse guard)

### Elastic Load Balancing (ALB / NLB)([YouTube](https://www.youtube.com/watch?v=znQsN8KzF_o))

- ALB: L7, path/host routing, target groups
- NLB: L4, high performance
- **EKS pattern:** ALB Ingress Controller / AWS Load Balancer Controller

### Route 53([YouTube](https://www.youtube.com/watch?v=JRZiQFVWpi8&t=353s))

- Public/private hosted zones, health checks, routing policies
- **Platform use:** service discovery, failover, weighted routing

### VPC Endpoints (PrivateLink)([YouTube](https://www.youtube.com/watch?v=vzTKr035ORQ))

- Private access to S3, DynamoDB, ECR, etc. without internet egress

### VPN / Direct Connect (Awareness)

- Hybrid connectivity to on-prem

| Service                 | Floci   |
| ----------------------- | ------- |
| VPC, EC2 networking, SG | Yes     |
| ELB (ALB/NLB)           | Yes     |
| Route 53                | Yes     |
| NAT / VPN edge behavior | Partial |

**Project:** [`projects/02-vpc-three-tier.md`](projects/02-vpc-three-tier.md)

---

## 3. Compute (Core)

### Elastic beanStalk ([Youtube](https://www.youtube.com/watch?v=Ht1COADOsNI))

### EC2 + Auto Scaling ([YouTube](https://www.youtube.com/watch?v=fwfkSxb1T-s))

- Instances, AMIs, launch templates, ASG
- **SRE use:** baseline capacity, mixed instances, health checks

### Lambda ([YouTube](https://www.youtube.com/watch?v=XFGSuj83wdc))

- Event-driven functions, layers, concurrency, DLQ([YouTube](https://www.youtube.com/watch?v=-ResiAcM8pg))
- **Platform use:** glue automation, webhooks, lightweight APIs

### ECS / Fargate ([Youtube](https://www.youtube.com/watch?v=86Ys0LnMSnY))

- Container orchestration without managing control plane
- **When:** simpler than EKS, AWS-native task scheduling

### EKS ([YouTube](https://www.youtube.com/watch?v=aRXg75S5DWA&list=PLiMWaCMwGJXnKY6XmeifEpjIfkWRo9v2l))

- Managed Kubernetes control plane; you manage node groups / add-ons
- **Platform essentials:** IRSA, Cluster Autoscaler/Karpenter, EBS/EFS CSI, ALB controller, CoreDNS, metrics

| Service                 | Floci   |
| ----------------------- | ------- |
| EC2, Lambda, ECS        | Yes     |
| EKS                     | Yes     |
| Fargate billing nuances | Partial |

**Projects:** [`03-serverless-api`](projects/03-serverless-api.md), [`06-eks-platform`](projects/06-eks-platform.md)

---

## 4. Storage (Core)

### S3

- Buckets, versioning, lifecycle, encryption, policies, static website hosting
- **DevOps:** Terraform remote state, artifacts, logs, static assets

### EBS / EFS ([Youtube](https://www.youtube.com/watch?v=aAOC6oS445s))

- Block vs shared file storage for EC2/EKS

### ECR

- Private OCI registry; scan on push; lifecycle policies
- **EKS pattern:** pull via node/instance role or IRSA

| Service          | Floci   |
| ---------------- | ------- |
| S3               | Yes     |
| EBS/EFS concepts | Partial |
| ECR              | Yes     |

**Projects:** Phase 0 state bucket, [`09-static-delivery`](projects/09-static-delivery.md)

---

## 5. Databases & Messaging (Important → Core for SRE)

### RDS / Aurora

- Managed relational DB; Multi-AZ, read replicas, backups
- **Platform:** provision via Terraform; connect via private subnet + SG

### DynamoDB

- Serverless NoSQL; on-demand vs provisioned; GSIs; streams

### ElastiCache (Redis/Memcached)

- Session cache, rate limiting, pub/sub

### SQS / SNS

- Queues (standard/FIFO), fan-out, DLQ, visibility timeout
- **SRE pattern:** decouple, absorb spikes, alert routing

### EventBridge ([YouTube](https://www.youtube.com/watch?v=_yC_Jn9rttY))

- Event bus, rules, schedules, cross-account routing

### Kinesis / MSK (Awareness → Important for data platforms)

- Streaming ingestion at scale

| Service                    | Floci |
| -------------------------- | ----- |
| RDS, DynamoDB, ElastiCache | Yes   |
| SQS, SNS, EventBridge      | Yes   |
| Kinesis, MSK               | Yes   |

**Projects:** [`03-serverless-api`](projects/03-serverless-api.md), [`08-event-driven`](projects/08-event-driven.md)

---

## 6. Infrastructure as Code & Automation (Core)

### CloudFormation

- Native AWS declarative IaC; stacks, drift detection, StackSets (awareness)

### Terraform (`aws` provider)

- Multi-cloud IaC; remote state in S3 + DynamoDB lock
- **Must know:** provider auth (OIDC), `aws` endpoints for Floci/local

### Systems Manager (SSM) ([Youtube](https://www.youtube.com/watch?v=B2MecqC5nJA))

- Parameter Store, Session Manager (no SSH keys), Run Command, Patch Manager

### Cloud Control API

- Unified CRUD for many AWS resources (used by some tools/operators)

| Service         | Floci                     |
| --------------- | ------------------------- |
| CloudFormation  | Yes                       |
| Terraform apply | Yes (via local endpoints) |
| SSM             | Yes                       |

**Projects:** [`07-terraform-pipeline`](projects/07-terraform-pipeline.md), [`learn-terraform`](../learn-terraform/README.md)

---

## 7. CI/CD & Delivery (Core)

You will wire pipelines constantly as a platform engineer.

### CodePipeline + CodeBuild + CodeDeploy ([Youtube](https://www.youtube.com/watch?v=iGCJ-N7bPX0))

- Native AWS delivery chain; artifact buckets in S3

### GitHub Actions / GitLab CI (with AWS)

- OIDC to IAM role — preferred over static keys

### Typical pipeline

```text
Commit → Build → Test → Scan → Push ECR → Deploy (EKS/ECS/Lambda) → Smoke test
```

| Service                             | Floci                                      |
| ----------------------------------- | ------------------------------------------ |
| CodePipeline, CodeBuild, CodeDeploy | Yes                                        |
| GitHub Actions                      | Runs on GitHub; targets Floci via env vars |

**Project:** [`07-terraform-pipeline`](projects/07-terraform-pipeline.md)

---

## 8. Observability (Core)

You can't operate what you can't see.

### CloudWatch ([Youtube](https://www.youtube.com/watch?v=Yxl7e88cTAQ))

- Metrics, logs, dashboards, alarms, composite alarms
- **SRE:** SLI/SLO dashboards, error budget burn alerts

### CloudWatch Logs

- Log groups/streams; subscription filters to Lambda/Kinesis

### X-Ray (Important) ([Youtube](https://www.youtube.com/watch?v=V1Fj8uEyp-E))

- Distributed tracing for Lambda, API Gateway, ECS, EKS apps

### CloudTrail ([Youtube](https://www.youtube.com/watch?v=CXbdsp9ThvM))

- API audit trail — who changed what in the account

| Service                        | Floci   |
| ------------------------------ | ------- |
| CloudWatch metrics/logs/alarms | Yes     |
| CloudTrail                     | Yes     |
| X-Ray                          | Partial |

**Project:** [`04-observe-operate`](projects/04-observe-operate.md)

---

## 9. Security & Secrets (Core) ([Youtube](https://www.youtube.com/watch?v=TS0UhSfzy_4))

### KMS

- Encryption keys; envelope encryption; key policies vs IAM policies

### Secrets Manager / SSM Parameter Store

- Secret rotation, versioning, reference from Lambda/EKS/ECS

### AWS Config ([Youtube](https://www.youtube.com/watch?v=qHdFoYSrUvk))

- Resource compliance rules; config snapshots

### GuardDuty / Security Hub (Important at scale)

- Threat detection, centralized findings

### WAF + Shield (Important for edge)

- L7 firewall at ALB/CloudFront

| Service              | Floci |
| -------------------- | ----- |
| KMS, Secrets Manager | Yes   |
| Config, GuardDuty    | Yes   |
| WAF                  | Yes   |

**Project:** [`05-secrets-kms`](projects/05-secrets-kms.md)

---

## 10. Governance & Cost (Important)

### AWS Organizations

- OUs, SCPs, consolidated billing

### Cost Explorer + Budgets + CUR

- Cost allocation tags, anomaly detection, chargeback

### Service Control Policies

- Guardrails: deny public S3, restrict regions, require encryption

| Service                     | Floci   |
| --------------------------- | ------- |
| Organizations, Budgets      | No      |
| Tagging, Cost Explorer APIs | Partial |

**Capstone:** [`10-platform-capstone`](projects/10-platform-capstone.md) (conceptual + real AWS graduation)

---

## 11. Edge & Content Delivery (Important)

### CloudFront

- CDN, OAC/OAI with private S3, caching, geo restrictions

### S3 static hosting + CloudFront

- Common pattern for SPAs and asset delivery

| Service         | Floci                                 |
| --------------- | ------------------------------------- |
| CloudFront      | Yes                                   |
| Amplify Hosting | No (use existing project on real AWS) |

**Projects:** [`09-static-delivery`](projects/09-static-delivery.md), [`../projects/aws-s3-cloudfront`](../projects/aws-s3-cloudfront/)

---

## The Platform Engineer Starter Pack

If you're preparing for a role or cert, prioritize in this order:

1. **IAM + STS + least-privilege roles**
2. **VPC, SG, ALB, Route53, private endpoints**
3. **EKS or ECS** (match your target job) + **ECR**
4. **S3 + Secrets Manager + KMS**
5. **CloudWatch + CloudTrail + alarms**
6. **Terraform + pipeline (GitHub Actions or CodePipeline)**
7. **SQS/EventBridge + Lambda** for automation
8. **Organizations + tagging + budgets** (real AWS graduation)

---

## Common Interview & On-Call Scenarios

| Scenario                          | Services involved                                           |
| --------------------------------- | ----------------------------------------------------------- |
| Deploy app to EKS with private DB | EKS, ECR, RDS, SG, Secrets Manager, ALB                     |
| Zero-trust internal API           | Private subnets, ALB/internal NLB, IAM auth                 |
| GitOps / platform delivery        | EKS, ECR, CodePipeline or GitHub Actions, CloudWatch        |
| Multi-account landing zone        | Organizations, SCPs, SSO, shared VPC/TGW                    |
| Secure CI/CD without secrets      | GitHub OIDC → IAM role → ECR/EKS deploy                     |
| Central logging                   | CloudWatch Logs, CloudTrail, S3 archive, Athena (awareness) |
| Incident: Lambda timeouts         | CloudWatch Logs, X-Ray, DLQ, concurrency limits             |

---

## Summary Map

```text
Identity (IAM, STS, roles)
    ↓
Network (VPC, SG, ALB, Route53, endpoints)
    ↓
Compute (EKS/ECS/Lambda/EC2)
    ↓
Data (S3, RDS, DynamoDB, SQS/SNS/EventBridge)
    ↓
Security (KMS, Secrets Manager, Config, WAF)
    ↓
Observability (CloudWatch, CloudTrail)
    ↓
Automation (Terraform/CFN, CodePipeline, SSM)
    ↓
Governance (Organizations, tags, budgets)
```

---

_See [`CURRICULUM.md`](CURRICULUM.md) for the project sequence that wires these services together._
