# Operators, CRDs, and Infra APIs

## Loop

`spec` desired → controller → cloud/cluster → `status` observed → repeat.

## Self-service API quality

Good: `kind: TeamWorkspace` with `size`, `owners`.  
Bad: `kind: AWSEverything` with 200 fields.

## Inventory

| Problem | Typical API |
| --- | --- |
| New cluster | Cluster API |
| Cloud bucket/DB | Crossplane XR, ACK, ASO |
| Certificates | cert-manager |
| App GitOps | Application / Kustomization |
| Policy | ClusterPolicy / Constraint |

## Operator vs Job vs Helm one-shot

| | Loop | Domain knowledge |
| --- | --- | --- |
| Job | No | Maybe |
| Helm install | Weak | Chart |
| Operator | Yes | Yes |

GitOps **syncs** these CRs; it does not replace the operator.
