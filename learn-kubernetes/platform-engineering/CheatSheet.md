# Exam-Day Cheat Sheet

Last page before CNPA. Closed book. **120 minutes, 60 questions, 75%.**

## Facts

| | |
| --- | --- |
| Name | Certified Cloud Native Platform Engineering Associate |
| Time | **120 min** (2 min/question) |
| Pass | **75%** |
| Style | Scenario / judgement, **vendor-neutral** |

| Domain | % | ~Q |
| --- | ---: | ---: |
| **Core fundamentals** | **36** | ~22 |
| Obs / security / conformance | 20 | ~12 |
| CD & platform engineering | 16 | ~10 |
| APIs & provisioning | 12 | ~7 |
| IDPs & DX | 8 | ~5 |
| Measuring | 8 | ~5 |

## Decision rule

Pick **platform as product**: self-service, golden path (easiest default + hatch), declarative reconcile, secure/observable **by default**, measure adoption and DORA — not tickets, not tool museums, not kubectl-from-CI.

## Core

- Customer = **app teams**. Success ≠ tools installed.
- TVP: smallest path that cuts toil **now**.
- DevOps enabled, not replaced (teams still own what they run).
- Declarative spec + controller. ClickOps is wrong.
- Promote **digest**, not rebuild. CI verifies; GitOps deploys.

## Obs / sec

- Signals: **metrics, logs, traces, events**. OTel = emit.
- mTLS + identity + NetworkPolicy; Ingress TLS ≠ east-west.
- Kyverno/OPA: mutate defaults, validate gates, generate tenancy.
- Restricted PSS, least privilege, no plaintext secrets.
- CI: no prod kubeconfig, pin, sign, scan, isolate fork PRs.

## CD

- Delivery = releasable; deployment = auto to prod (optional).
- Env = Git path + destination + CODEOWNERS.
- Incident: blast radius; revert Git; status page; blameless → path fix.

## APIs

- CRD = self-service API. spec desired, status observed.
- CAPI = clusters. Crossplane/ACK = cloud. Operator = looping domain controller.

## IDP

- Portal (Backstage) **surfaces** the platform; it is not the whole product.
- Catalog = owners/APIs. Templates = golden start. API-first.
- AI proposes PRs; Git/policy still truth.

## DORA

Frequency ↑, lead time ↓, change fail ↓, MTTR ↓.  
Vanity: plugin count. Your ticket queue **is** their lead time.

## Phrases that usually win

self-service · golden path · thinnest viable · least cognitive load · secure by default · declarative · reconcile · build once · least privilege · measure adoption
