# Topic 6: VPC (Virtual Private Cloud)

## What You'll Learn

- VPC – isolated network with a CIDR block
- Subnet – segment of the VPC in one AZ
- Internet Gateway (IGW) – connects VPC to the internet
- Route table – rules for traffic (e.g. 0.0.0.0/0 → IGW)
- `cidrsubnet()` – calculate subnet CIDRs from parent VPC

## Architecture

```
VPC (10.0.0.0/16)
└── Public Subnet (10.0.1.0/24)
    └── Route Table: 0.0.0.0/0 → Internet Gateway
```

## Steps

### 1. Apply

```bash
source ../../aws.cred
cd topic-06-vpc
terraform init
terraform apply -auto-approve
```

### 2. Verify in AWS Console

- VPC → Your VPCs → `learn-terraform-vpc`
- Subnets → `learn-terraform-public-subnet`

### 3. Clean up when done

```bash
terraform destroy -auto-approve
```

---

## Exam Tips

| Concept                                 | Key Point                                                       |
| --------------------------------------- | --------------------------------------------------------------- |
| **cidrsubnet(prefix, newbits, netnum)** | Splits CIDR: `cidrsubnet("10.0.0.0/16", 8, 1)` → `10.0.1.0/24`  |
| **map_public_ip_on_launch**             | Instances in subnet get public IP automatically                 |
| **Public subnet**                       | Route table sends 0.0.0.0/0 to IGW                              |
| **Private subnet**                      | No route to IGW; use NAT Gateway for outbound only              |
| **depends_on**                          | IGW doesn't need explicit depends_on; subnet/route reference it |

## Practice

1. Add a second subnet in a different AZ using `data.aws_availability_zones.available.names[1]`.
2. Associate it with the same route table (one route table can have multiple subnets).
