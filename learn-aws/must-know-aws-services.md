# Must-Know AWS Services for Platform / DevOps Engineers

A practical reference for engineers who build, deploy, operate, and secure workloads on AWS. Focus is on services you touch weekly—not every service in the console.

---

## How to Use This Guide

| Priority | Meaning |
| -------- | ------- |
| **Core** | You should know this cold for interviews and day-to-day work |
| **Important** | Common in production; know when and why to use it |
| **Awareness** | Know it exists and what problem it solves |

---

## 1. Identity & Access (Core)

Everything in AWS starts with **who** can do **what**.

### AWS IAM (Identity and Access Management)

- Users, groups, roles, policies (identity-based and resource-based)
- **DevOps use:** CI/CD roles, instance profiles, IRSA for EKS, cross-account access
- **Golden rule:** no long-lived access keys for humans; use SSO + short-lived credentials

### IAM Roles & Policies

- **Role:** assumable identity (EC2, Lambda, GitHub OIDC, EKS pods)
- **Policy:** JSON document defining Allow/Deny on actions/resources
- **Managed policies** vs **inline policies** vs **permission boundaries**

### AWS Organizations

- Multi-account management: OUs, SCPs (Service Control Policies), consolidated billing
- **DevOps pattern:** separate accounts per environment (prod/staging/dev/sandbox)

### AWS IAM Identity Center (formerly AWS SSO)

- Central SSO portal for human access across accounts
- Permission sets mapped to IAM roles per account

### Key concepts to memorize

```
Principal → Action → Resource → Condition
Example: role-ci-cd → s3:PutObject → arn:aws:s3:::artifacts/* → aws:PrincipalTag/Environment=prod
```

---

## 2. Compute (Core)

### Amazon EC2

- IaaS workloads, bastion hosts, legacy apps, GPU instances
- Placement groups, Auto Scaling Groups (ASG), Launch Templates
- Instance types: general (`t3`, `m7i`), compute (`c7i`), memory (`r7i`), GPU (`p4`, `g5`)

### Amazon EKS (Elastic Kubernetes Service)

- Managed Kubernetes control plane; you manage node groups
- **Platform engineer essentials:** managed node groups vs Fargate, cluster autoscaler/Karpenter, VPC CNI, IRSA, EBS/EFS CSI drivers, AWS Load Balancer Controller, CoreDNS, control plane logging
- Upgrades: control plane version + node AMI / managed node group rolling updates

### Amazon ECS & Fargate

- AWS-native container orchestration without Kubernetes
- **Fargate:** serverless tasks—no EC2 to manage
- Good when teams want containers but not K8s complexity

### AWS Lambda

- Event-driven serverless compute
- Triggers: API Gateway, SQS, SNS, S3, EventBridge, DynamoDB Streams
- **DevOps:** deploy via SAM, CDK, Terraform, or container images; use X-Ray and CloudWatch

### AWS Elastic Beanstalk

- PaaS for quick web app deploys (less common in modern platform teams but still seen)

### EC2 Auto Scaling & Application Auto Scaling

- Horizontal scaling for EC2, ECS, DynamoDB, Aurora, etc.
- Target tracking, step scaling, scheduled scaling

---

## 3. Networking (Core)

Networking is where most platform incidents live. Know these deeply.

### Amazon VPC (Virtual Private Cloud)

- Private network boundary in a region
- Subnets (public/private), route tables, Internet Gateway, NAT Gateway
- **Design rule:** public subnets for load balancers/NAT only; apps and data in private subnets

### Security Groups & NACLs

- **Security Groups:** stateful firewall at ENI/instance level (primary tool)
- **NACLs:** stateless subnet-level rules (coarse-grained, rarely changed)

### Elastic Load Balancing (ELB)

| Type | Layer | Use case |
| ---- | ----- | -------- |
| **ALB** | L7 | HTTP/HTTPS routing, host/path rules, EKS Ingress |
| **NLB** | L4 | TCP/UDP, static IPs, extreme performance |
| **GLB** | L3/L4 | Gateway load balancer for third-party appliances |

### Amazon Route 53

- DNS: public hosted zones, private hosted zones, health checks, routing policies (weighted, latency, failover)
- Critical for ingress, multi-region failover, and internal service discovery

### AWS CloudFront

- Global CDN + edge caching + optional WAF integration
- Origin: S3, ALB, custom origins

### AWS WAF & Shield

- **WAF:** application firewall rules for ALB, CloudFront, API Gateway
- **Shield Standard:** free DDoS protection; **Shield Advanced** for enterprise

### VPC Endpoints (Gateway & Interface)

- Private connectivity to AWS services without traversing the public internet
- **Gateway endpoints:** S3, DynamoDB
- **Interface endpoints (PrivateLink):** ECR, STS, Secrets Manager, etc.
- **Security baseline:** ECR, S3, Secrets Manager via VPC endpoints in prod

### AWS VPN & Direct Connect

- **Site-to-Site VPN:** hybrid connectivity over internet
- **Direct Connect:** dedicated private link to AWS

### AWS Transit Gateway

- Hub-and-spoke routing between VPCs and on-premises networks at scale

---

## 4. Storage (Core)

### Amazon S3

- Object storage: backups, artifacts, static sites, Terraform state, logs
- Storage classes: Standard, IA, Glacier, Intelligent-Tiering
- Versioning, lifecycle rules, replication (CRR/SRR), Object Lock
- **DevOps:** remote Terraform state in S3 + DynamoDB locking table

### Amazon EBS

- Block storage for EC2; gp3 (general), io2 (high IOPS)
- Snapshots → AMIs for golden images

### Amazon EFS

- Managed NFS; common for shared persistent volumes in EKS

### Amazon FSx

- Managed Windows (FSx for Windows), Lustre (HPC), NetApp ONTAP, OpenZFS

---

## 5. Containers & Registry (Core)

### Amazon ECR (Elastic Container Registry)

- Private Docker/OCI registry
- Image scanning, lifecycle policies, cross-account/cross-region replication
- **EKS integration:** IAM roles + IRSA or node instance profile with `ecr:GetAuthorizationToken`

### AWS App Runner

- Fully managed container service from source or ECR
- Simple public web apps/APIs without operating Kubernetes

---

## 6. Databases & Messaging (Important)

You don't need to be a DBA, but platform engineers provision and connect these constantly.

### Amazon RDS

- Managed relational: PostgreSQL, MySQL, MariaDB, Oracle, SQL Server
- Multi-AZ, read replicas, automated backups, parameter groups
- **Aurora:** AWS-optimized MySQL/PostgreSQL with fast failover and storage scaling

### Amazon DynamoDB

- Serverless NoSQL key-value/document store
- On-demand vs provisioned capacity; global tables

### Amazon ElastiCache

- Managed Redis or Memcached for caching and session stores

### Amazon MSK (Managed Streaming for Apache Kafka)

- Managed Kafka for event streaming platforms

### Amazon SQS & SNS

- **SQS:** durable message queues (standard, FIFO, DLQ)
- **SNS:** pub/sub fan-out to SQS, Lambda, HTTP endpoints

### Amazon EventBridge

- Event bus for routing events between AWS services and SaaS (successor to CloudWatch Events)

### Amazon MQ

- Managed message broker (ActiveMQ, RabbitMQ) for legacy JMS workloads

---

## 7. Infrastructure as Code & Automation (Core)

### AWS CloudFormation

- Native AWS IaC: stacks, nested stacks, drift detection
- Underlying API for most AWS provisioning

### AWS CDK (Cloud Development Kit)

- Define infrastructure in TypeScript, Python, Go, etc.; synthesizes to CloudFormation
- **Preferred** for native AWS IaC when not using Terraform

### Terraform (`aws` provider)

- Multi-cloud IaC; state in S3 + DynamoDB lock
- Know: provider auth (OIDC from GitHub Actions), IAM roles for CI, `aws` vs `awscc` providers

### AWS CLI & SDK

- Day-to-day automation and troubleshooting
- **Must-know commands:**

```bash
aws sts get-caller-identity
aws configure list-profiles
export AWS_PROFILE=prod
aws ec2 describe-instances --filters "Name=tag:Environment,Values=prod" --query 'Reservations[].Instances[].InstanceId'
aws eks update-kubeconfig --name prod-cluster --region us-east-1
aws s3 ls s3://my-terraform-state/
```

### AWS Systems Manager (SSM)

- **Session Manager:** shell access without SSH keys or bastion hosts
- **Parameter Store / SSM Documents:** config and runbooks
- **Patch Manager:** OS patching at scale

---

## 8. CI/CD & DevOps Tooling (Core)

### AWS CodePipeline / CodeBuild / CodeDeploy

- Native CI/CD: source → build → deploy
- Integrates with GitHub, CodeCommit, ECR, ECS, EKS, Lambda

### GitHub Actions + AWS

- OIDC federation to IAM roles (no long-lived access keys in secrets)
- Common pattern: build → push to ECR → deploy to EKS/ECS/Lambda

### Jenkins / GitLab CI on EC2 or EKS

- Still common; self-hosted runners with IAM instance roles

### Typical pipeline pattern

- Build → test → scan (Trivy/ECR scan) → push to ECR → deploy to EKS/ECS/Lambda
- Manual approvals via CodePipeline or GitHub Environments

---

## 9. Observability (Core)

You can't operate what you can't see.

### Amazon CloudWatch

- Metrics, logs, alarms, dashboards—the central observability layer
- **CloudWatch Logs:** log groups/streams; subscription filters to Lambda/Kinesis
- **CloudWatch Alarms:** SNS, Auto Scaling, EventBridge actions

### CloudWatch Logs Insights

- Query language for log analysis

```
fields @timestamp, @message
| filter @message like /error/
| sort @timestamp desc
| limit 50
```

### AWS X-Ray

- Distributed tracing for Lambda, ECS, EKS, API Gateway

### Amazon Managed Grafana & Managed Prometheus

- Managed observability stack for Kubernetes and microservices
- **AMP:** Prometheus-compatible metrics; **AMG:** Grafana dashboards

### AWS CloudTrail

- API audit trail—who did what, when, from where
- **Security essential:** org-trail in centralized logging account

---

## 10. Security & Secrets (Core)

### AWS Secrets Manager & SSM Parameter Store

- **Secrets Manager:** rotation, RDS integration, cross-account
- **Parameter Store:** simpler config/secrets (Standard free, Advanced paid)
- **Platform patterns:** External Secrets Operator / CSI driver in EKS, Lambda env from Secrets Manager

### AWS KMS (Key Management Service)

- Encryption keys for EBS, S3, RDS, Secrets Manager, EKS secrets
- CMKs: AWS-managed vs customer-managed; key policies matter

### AWS Certificate Manager (ACM)

- Free TLS certs for ALB, CloudFront, API Gateway

### AWS Config

- Resource configuration tracking and compliance rules
- **DevOps:** config rules as guardrails; remediation via SSM

### AWS Security Hub & GuardDuty

- **Security Hub:** aggregated security findings (CSPM)
- **GuardDuty:** threat detection (anomaly-based)

### AWS IAM Access Analyzer

- Identifies resources shared externally; validates least-privilege policies

---

## 11. Governance & Cost (Important)

### AWS Organizations & SCPs

- Organize accounts into OUs; SCPs deny actions at account level (e.g., no root API keys, restrict regions)

### AWS Control Tower

- Landing zone automation: multi-account setup, guardrails, account factory

### AWS Service Catalog

- Self-service provisioning of approved CloudFormation/CDK products

### Tagging & Cost Allocation

- **Tags to enforce:** `Environment`, `Owner`, `CostCenter`, `Application`
- Cost Explorer, Budgets, CUR (Cost and Usage Reports)

### AWS Budgets & Cost Anomaly Detection

- Alert before overspend; anomaly detection for unexpected spikes

---

## 12. Landing Zones & Platform Engineering (Important)

### AWS Landing Zone (Control Tower / custom)

- Opinionated multi-account architecture: security, logging, shared services, workloads
- Central logging account, audit account, network hub (Transit Gateway)

### Platform services engineers often build

| Capability | Typical AWS building blocks |
| ---------- | --------------------------- |
| **Cluster platform** | EKS, ECR, Secrets Manager, AWS LB Controller, CloudWatch |
| **Secrets** | Secrets Manager + IRSA (IAM Roles for Service Accounts) |
| **Ingress** | ALB + Route 53 or CloudFront |
| **GitOps** | Flux/Argo CD on EKS |
| **Internal dev portal** | Backstage + Service Catalog + pipeline templates |
| **Self-service infra** | Terraform/CDK modules + CodePipeline/GitHub Actions |
| **Node scaling** | Karpenter or Cluster Autoscaler + ASG |

---

## 13. Backup, DR & Resilience (Important)

### AWS Backup

- Centralized backup for EC2, EBS, RDS, DynamoDB, EFS, EKS (via hooks/partners)

### Amazon RDS Snapshots & Aurora Backtrack

- Point-in-time recovery for databases

### Multi-AZ & Cross-Region

- **Multi-AZ:** synchronous HA within a region (RDS, ELB, NAT GW)
- **Cross-region:** S3 replication, Route 53 failover, Aurora Global Database
- Know RTO/RPO before choosing architecture

### AWS Elastic Disaster Recovery (DRS)

- Continuous block-level replication for DR orchestration

---

## 14. API & Integration (Important)

### Amazon API Gateway

- Managed REST, HTTP, and WebSocket APIs
- Fronts Lambda, ECS, EC2; usage plans, throttling, authorizers

### AWS Step Functions

- Orchestrate Lambda and ECS workflows (state machines)

---

## 15. Services You'll See But May Not Operate Daily (Awareness)

| Service | One-line purpose |
| ------- | ---------------- |
| **Athena** | SQL queries on S3 data |
| **Glue** | ETL and data catalog |
| **Redshift** | Data warehouse |
| **OpenSearch** | Search and log analytics |
| **EMR** | Managed Hadoop/Spark |
| **SageMaker** | ML training and inference |
| **Amplify** | Full-stack web/mobile hosting |
| **Cognito** | User auth for apps (not the same as IAM) |
| **AppSync** | Managed GraphQL |
| **Batch** | Batch computing jobs |
| **Lightsail** | Simple VPS for small workloads |

---

## The "Platform Engineer Starter Pack"

If you're preparing for a role or cert (SAA-C03 / SOA-C02 / DVA-C02 / SAP-C02), prioritize in this order:

1. **IAM + Organizations + IAM Identity Center**
2. **VPC, Security Groups, ALB/NLB, Route 53, VPC Endpoints**
3. **EKS** (or ECS/Fargate if your org avoids K8s)
4. **ECR + Secrets Manager + KMS**
5. **S3 + CloudWatch + CloudTrail**
6. **Terraform or CDK + GitHub Actions/CodePipeline**
7. **AWS Config/Control Tower patterns + Cost Explorer/Budgets + AWS Backup**

---

## Common Exam & Interview Scenarios

| Scenario | Services involved |
| -------- | ----------------- |
| Deploy app to K8s with private DB | EKS, ECR, VPC private subnets, RDS, Secrets Manager, ALB |
| Zero-trust internal API | PrivateLink/VPC endpoints, internal ALB/NLB, IAM auth |
| GitOps platform | EKS, ECR, Flux/Argo, CloudWatch, IRSA |
| Multi-account landing zone | Organizations, Control Tower, SCPs, Transit Gateway |
| Secure CI/CD without secrets | GitHub OIDC → IAM role → short-lived credentials |
| Central logging & audit | CloudTrail (org trail), CloudWatch Logs, S3 log archive |
| Cost-efficient dev environments | ASG schedules, Spot instances, S3 lifecycle, Budgets |

---

## Quick CLI Cheat Sheet

```bash
# Identity — create role for GitHub OIDC (simplified; use IaC in prod)
aws iam create-role --role-name github-actions-deploy --assume-role-policy-document file://trust-policy.json

# EKS
aws eks create-cluster --name prod --role-arn arn:aws:iam::123456789012:role/eks-cluster --resources-vpc-config subnetIds=subnet-aaa,subnet-bbb
aws eks update-kubeconfig --name prod --region us-east-1

# Networking
aws ec2 create-vpc --cidr-block 10.0.0.0/16
aws ec2 authorize-security-group-ingress --group-id sg-xxx --protocol tcp --port 443 --cidr 0.0.0.0/0

# Secrets
aws secretsmanager create-secret --name prod/db-password --secret-string '<secret>'

# S3 — Terraform state bucket
aws s3 mb s3://my-org-terraform-state --region us-east-1
aws dynamodb create-table --table-name terraform-locks --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST

# Logs — recent EKS control plane errors (if logging enabled)
aws logs filter-log-events --log-group-name /aws/eks/prod/cluster --filter-pattern "error" --limit 20
```

---

## Related Learning Paths

- **AWS Certified Solutions Architect – Associate (SAA-C03):** broad architecture
- **AWS Certified SysOps Administrator – Associate (SOA-C02):** operations focus
- **AWS Certified DevOps Engineer – Professional (DOP-C02):** CI/CD, IaC, observability
- **AWS Certified Security – Specialty:** IAM, KMS, GuardDuty, compliance
- **CKA/CKAD + EKS:** Kubernetes on AWS specifically

---

## Summary Map

```
Identity (IAM, Organizations, Identity Center)
    ↓
Network (VPC, SG, ALB/NLB, Route 53, CloudFront, VPC Endpoints)
    ↓
Compute (EKS / ECS / Lambda / EC2)
    ↓
Data (S3, RDS/Aurora, DynamoDB, SQS/SNS/EventBridge)
    ↓
Security (Secrets Manager, KMS, Config, GuardDuty)
    ↓
Observability (CloudWatch, X-Ray, CloudTrail)
    ↓
Automation (CloudFormation/CDK/Terraform, SSM, CodePipeline)
    ↓
Governance (Organizations, Control Tower, Budgets, Landing Zones)
```

---

## Azure ↔ AWS Quick Reference (for multi-cloud engineers)

| Category | Azure | AWS |
| -------- | ----- | --- |
| Identity | Entra ID | IAM + Identity Center |
| Kubernetes | AKS | EKS |
| Container registry | ACR | ECR |
| Object storage | Blob Storage | S3 |
| Secrets | Key Vault | Secrets Manager |
| L7 load balancer | App Gateway | ALB |
| Private PaaS access | Private Endpoint | VPC Interface Endpoint |
| Serverless compute | Functions | Lambda |
| Native IaC | Bicep/ARM | CDK/CloudFormation |
| Central logging | Log Analytics | CloudWatch Logs |
| Policy guardrails | Azure Policy | AWS Config + SCPs |
| Landing zone | Azure Landing Zone | Control Tower |

---

*Last updated: August 2025. Reflects current AWS service names and common platform engineering patterns.*
