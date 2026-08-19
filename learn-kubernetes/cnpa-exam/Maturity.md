# Platform Engineering Maturity Model

CNCF / community maturity (levels vary by doc; exam cares about **direction**, not a brand’s five logos).

Typical progression:

| Level | You see | Problem |
| --- | --- | --- |
| Ad hoc | Wikis, heroes, tickets | Does not scale |
| Repeatable | Some Terraform/Helm, still copy-paste | Drift, snowflakes |
| Productised | Golden paths, self-service APIs, docs, SLOs | This is CNPA “good” |
| Optimising | Measured DORA/DX, paved path is default, policy as code, multi-cluster as a product | Continuous improvement |

## What “more mature” is **not**

- More tools in the portal
- Mandatory use of every CNCF project
- Centralising all deploys in the platform team (that is **less** DevOps)

## Signals of maturity (use on scenario questions)

- Time-to-first-hello-world on the path is hours, not weeks
- Most deploys do **not** open a platform ticket
- Security/obs are **defaults**, not add-on homework
- App teams can still **escape** with review
- Platform has error budgets / SLOs like any product
- You **measure** adoption and DORA, then change the product

## Mapping to domains

| Maturity gap | Domain you will be tested in |
| --- | --- |
| Everything is a ticket | Core + IDP |
| No GitOps / unique clusters | Core + CD |
| No traces/metrics by default | Observability |
| Policy after breach | Conformance |
| No CRDs, only kubectl by humans | Platform APIs |
| “Success” = tools installed | Measuring |
