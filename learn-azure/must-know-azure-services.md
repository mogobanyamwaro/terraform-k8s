# Must-Know Azure Services for Platform / DevOps Engineers

A practical reference for engineers who build, deploy, operate, and secure workloads on Azure. Focus is on services you touch weekly—not every SKU in the catalog.

---

## How to Use This Guide

| Priority | Meaning |
| -------- | ------- |
| **Core** | You should know this cold for interviews and day-to-day work |
| **Important** | Common in production; know when and why to use it |
| **Awareness** | Know it exists and what problem it solves |

---

## 1. Identity & Access (Core)

Everything in Azure starts with **who** can do **what**.

### Microsoft Entra ID (formerly Azure AD)

- Central identity provider for users, groups, service principals, and managed identities
- SSO, MFA, conditional access, app registrations
- **DevOps use:** CI/CD service principals, workload identity for AKS, RBAC at subscription/resource-group scope

### Managed Identities

- Azure-managed credentials for apps/VMs/AKS—no secrets in code
- **System-assigned:** tied to one resource lifecycle
- **User-assigned:** reusable across resources

### Azure RBAC

- Role assignments: `Owner`, `Contributor`, `Reader`, plus scoped custom roles
- Scope hierarchy: Management Group → Subscription → Resource Group → Resource
- **DevOps pattern:** least privilege for pipelines, break-glass admin separate from daily ops

### Key concepts to memorize

```
Principal → Role Assignment → Scope
Example: sp-ci-cd → Contributor → rg-prod-apps
```

---

## 2. Compute (Core)

### Azure Virtual Machines

- IaaS workloads, jump boxes, legacy apps, GPU nodes
- Availability Sets / Availability Zones for HA
- VMSS (Virtual Machine Scale Sets) for auto-scaling VM fleets

### Azure Kubernetes Service (AKS)

- Managed control plane; you manage node pools
- **Platform engineer essentials:** node pools, cluster autoscaler, Azure CNI vs kubenet, workload identity, Azure Key Vault CSI, AGIC (App Gateway Ingress), Azure Monitor container insights
- Upgrades: control plane + node image/channel upgrades

### Azure Container Apps

- Serverless containers on top of Kubernetes (KEDA built-in)
- Good for event-driven microservices, jobs, internal APIs
- Less ops than AKS; less control than raw K8s

### Azure Functions

- Event-driven serverless compute
- Triggers: HTTP, Queue, Event Hub, Timer, Blob
- **DevOps:** deploy via ZIP, containers, or GitHub Actions; use Application Insights

### Azure App Service

- PaaS for web apps, APIs, containers
- Deployment slots (blue/green), autoscale, VNet integration
- Common for .NET/Node/Python apps when you don't need K8s

---

## 3. Networking (Core)

Networking is where most platform incidents live. Know these deeply.

### Virtual Network (VNet)

- Private network boundary in a region
- Subnets, route tables, NSGs, service endpoints, private endpoints
- **Design rule:** hub-spoke or mesh; never expose backends on public IPs unless required

### Network Security Groups (NSGs)

- Stateful L3/L4 firewall rules at subnet or NIC level
- Allow/deny by source/dest IP, port, protocol

### Azure Load Balancer

- L4 load balancing (public or internal)
- Used by AKS for `LoadBalancer` services

### Application Gateway

- L7 load balancer + WAF
- Path-based routing, SSL termination, autoscaling
- Often paired with AKS via AGIC

### Azure Front Door / Traffic Manager

- **Front Door:** global L7 CDN + WAF + routing (modern choice)
- **Traffic Manager:** DNS-based global routing (legacy but still seen)

### Azure Firewall

- Managed network firewall for hub VNets
- Central egress/ingress policy

### Private Link / Private Endpoints

- Access PaaS services over private IP inside your VNet
- **Security baseline:** storage, Key Vault, ACR, SQL should use private endpoints in prod

### VPN Gateway / ExpressRoute

- Hybrid connectivity: site-to-site VPN vs dedicated ExpressRoute circuits

### Azure DNS

- Host public zones (`example.com`) or private DNS linked to VNets
- Critical for internal service discovery in private environments

---

## 4. Storage (Core)

### Azure Storage Account

Types you'll see constantly:

| Service | Use case |
| ------- | -------- |
| **Blob** | Object storage, backups, static sites, Terraform state |
| **File** | SMB/NFS shares, legacy lift-and-shift |
| **Queue** | Simple async messaging |
| **Table** | NoSQL key-value (legacy workloads) |

- Redundancy: LRS, ZRS, GRS, GZRS
- Access tiers: Hot, Cool, Archive
- **DevOps:** remote Terraform state in blob + locking via blob lease

### Azure Disk Storage

- Managed disks for VMs: Standard vs Premium, snapshots, encryption

### Azure Files

- Shared file storage; common for persistent volumes in AKS

---

## 5. Containers & Registry (Core)

### Azure Container Registry (ACR)

- Private Docker/OCI registry
- Geo-replication, content trust, retention policies
- **AKS integration:** attach ACR with managed identity (`AcrPull` role)

### ACR Tasks

- Build images in Azure (CI without external runners)

---

## 6. Databases & Messaging (Important)

You don't need to be a DBA, but platform engineers provision and connect these constantly.

### Azure SQL Database / Managed Instance

- PaaS SQL; MI closer to full SQL Server for migrations

### Azure Database for PostgreSQL / MySQL (Flexible Server)

- Common app backends; VNet integration + private endpoint

### Azure Cosmos DB

- Globally distributed multi-model DB (NoSQL)

### Azure Cache for Redis

- In-memory cache/session store; cluster mode for HA

### Azure Service Bus

- Enterprise messaging: queues, topics, subscriptions, dead-letter queues

### Azure Event Hubs

- High-throughput event ingestion (telemetry, streaming pipelines)

### Azure Event Grid

- Event routing / pub-sub for Azure resources and custom topics

---

## 7. Infrastructure as Code & Automation (Core)

### Azure Resource Manager (ARM)

- Underlying deployment API for all Azure resources
- Templates: JSON/Bicep define desired state

### Bicep

- Domain-specific language that compiles to ARM
- **Preferred** for native Azure IaC when not using Terraform

### Terraform (`azurerm` provider)

- Multi-cloud IaC; state in Azure Blob Storage
- Know: provider auth (OIDC from GitHub Actions), remote backend, `azurerm` vs `azapi`

### Azure CLI (`az`) & PowerShell (`Az`)

- Day-to-day automation and troubleshooting
- **Must-know commands:**

```bash
az login
az account set --subscription "<sub-id>"
az group create -n rg-demo -l eastus
az aks get-credentials -g rg-demo -n aks-demo
az resource list -g rg-demo -o table
```

### Azure Deployment Environments (ADE)

- Self-service dev/test environments for engineering teams

---

## 8. CI/CD & DevOps Tooling (Core)

### Azure DevOps

- Repos, Pipelines (YAML), Boards, Artifacts, Test Plans
- Service connections to Azure subscriptions
- Agent pools: Microsoft-hosted vs self-hosted

### GitHub Actions + Azure

- OIDC federation to Azure (no long-lived secrets)
- Common pattern for AKS, App Service, Functions deploys

### Azure Pipelines / GitHub Actions patterns

- Build → test → scan → push to ACR → deploy to AKS/App Service
- Environment gates, approvals, deployment slots

---

## 9. Observability (Core)

You can't operate what you can't see.

### Azure Monitor

- Umbrella platform: metrics, logs, alerts, dashboards

### Log Analytics Workspace

- Central log store; Kusto Query Language (KQL) is essential

```kusto
ContainerLog
| where TimeGenerated > ago(1h)
| where LogEntry contains "error"
| summarize count() by Computer
```

### Application Insights

- APM for apps: requests, dependencies, exceptions, traces
- OpenTelemetry integration for modern stacks

### Azure Monitor Alerts & Action Groups

- Metric alerts, log alerts, activity log alerts
- Notify via email, SMS, webhook, Logic App, ITSM

### Azure Workbooks & Grafana (Managed Grafana)

- Dashboards and SRE views

---

## 10. Security & Secrets (Core)

### Azure Key Vault

- Secrets, keys, certificates
- **Platform patterns:** CSI driver in AKS, reference from App Service, pipeline secret retrieval

### Microsoft Defender for Cloud

- CSPM + workload protection recommendations
- Secure score, regulatory compliance views

### Azure Policy

- Guardrails at scale: deny public storage, enforce tags, require TLS
- **DevOps:** policy-as-code in CI; remediation tasks

### Azure Security Center / Sentinel (awareness → important at scale)

- **Microsoft Sentinel:** cloud SIEM/SOAR on Log Analytics

---

## 11. Governance & Cost (Important)

### Management Groups & Subscriptions

- Organize environments: prod/nonprod/sandbox
- Apply policies and RBAC at the right level

### Azure Policy (again—it's that important)

- Initiatives = bundles of policies

### Cost Management + Billing

- Budgets, alerts, cost allocation by tags
- **Tags you should enforce:** `Environment`, `Owner`, `CostCenter`, `Application`

### Azure Blueprints (legacy) / Deployment Stacks

- Repeatable landing zones; prefer **Azure Landing Zone (ALZ)** patterns today

---

## 12. Landing Zones & Platform Engineering (Important)

### Azure Landing Zone (ALZ)

- Opinionated architecture: identity, connectivity, governance, management
- Built on management groups, policy, hub-spoke networking

### Platform services engineers often build

| Capability | Typical Azure building blocks |
| ---------- | ----------------------------- |
| **Cluster platform** | AKS, ACR, Key Vault, AGIC/NGINX, Azure Monitor |
| **Secrets** | Key Vault + workload identity |
| **Ingress** | App Gateway or Front Door |
| **GitOps** | Flux/Argo CD on AKS |
| **Internal dev portal** | Backstage + ADE + templates |
| **Self-service infra** | Bicep/Terraform modules + pipeline templates |

---

## 13. Backup, DR & Resilience (Important)

### Azure Backup

- VM, file share, SQL, AKS backup (via extensions/partners)

### Azure Site Recovery (ASR)

- Disaster recovery orchestration for VMs

### Availability Zones & Regions

- Zone-redundant services vs single-zone
- Know RTO/RPO requirements before picking SKUs

---

## 14. Services You'll See But May Not Operate Daily (Awareness)

| Service | One-line purpose |
| ------- | ---------------- |
| **Logic Apps** | Low-code workflow automation |
| **API Management (APIM)** | API gateway, rate limiting, OAuth |
| **Data Factory** | ETL / data pipelines |
| **Databricks** | Spark analytics platform |
| **Synapse** | Analytics warehouse |
| **Batch** | Large-scale parallel batch jobs |
| **Spring Apps** | Managed Spring Boot |
| **Communication Services** | SMS/email/voice APIs |

---

## The "Platform Engineer Starter Pack"

If you're preparing for a role or cert (AZ-104 / AZ-400 / AZ-305), prioritize in this order:

1. **Entra ID + RBAC + Managed Identities**
2. **VNet, NSG, Private Endpoints, Load Balancer / App Gateway**
3. **AKS** (or App Service if your org is PaaS-heavy)
4. **ACR + Key Vault**
5. **Storage Account (Blob) + Azure Monitor / Log Analytics / App Insights**
6. **Terraform or Bicep + Azure DevOps or GitHub Actions**
7. **Azure Policy + Cost Management + Backup**

---

## Common Exam & Interview Scenarios

| Scenario | Services involved |
| -------- | ----------------- |
| Deploy app to K8s with private DB | AKS, ACR, Private Endpoint, Azure Database, Key Vault |
| Zero-trust internal API | Private Link, App Gateway or Internal LB, Entra ID |
| GitOps platform | AKS, ACR, Flux/Argo, Azure Monitor, Key Vault |
| Multi-env landing zone | Management Groups, Subscriptions, Policy, Hub VNet |
| Secure CI/CD without secrets | GitHub OIDC → Entra ID → federated credentials |
| Central logging | Log Analytics, Diagnostic Settings on all resources |

---

## Quick CLI Cheat Sheet

```bash
# Identity
az ad sp create-for-rbac --name sp-terraform --role Contributor --scopes /subscriptions/<sub-id>

# AKS
az aks create -g rg -n aks --node-count 3 --enable-managed-identity --attach-acr <acr-name>
az aks nodepool add -g rg --cluster-name aks -n gpupool --node-count 1 --node-vm-size Standard_NC6

# Networking
az network vnet create -g rg -n vnet --address-prefix 10.0.0.0/16
az network nsg rule create -g rg --nsg-name nsg -n allow-https --priority 100 \
  --access Allow --protocol Tcp --destination-port-range 443

# Key Vault secret (for apps/pipelines)
az keyvault secret set --vault-name kv-prod --name db-password --value '<secret>'

# Monitor - tail AKS logs
az monitor log-analytics query -w <workspace-id> \
  --analytics-query "KubePodInventory | where Namespace=='default' | take 20"
```

---

## Related Learning Paths

- **AZ-104:** Azure Administrator — operations focus
- **AZ-400:** DevOps Engineer — pipelines, IaC, monitoring
- **AZ-305:** Solutions Architect — design and governance
- **CKA/CKAD + AKS:** Kubernetes on Azure specifically

---

## Summary Map

```
Identity (Entra ID, RBAC, Managed Identity)
    ↓
Network (VNet, NSG, Private Link, LB/AppGW/Front Door)
    ↓
Compute (AKS / App Service / Functions / VMs)
    ↓
Data (Storage, DB, Cache, Messaging)
    ↓
Security (Key Vault, Policy, Defender)
    ↓
Observability (Monitor, Log Analytics, App Insights)
    ↓
Automation (Bicep/Terraform, Azure DevOps/GitHub Actions)
    ↓
Governance (Management Groups, Policy, Cost, Landing Zones)
```

---

*Last updated: August 2025. Service names reflect Microsoft Entra ID rebrand and current Azure terminology.*
