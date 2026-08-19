# CNCF Platforms White Paper (Exam-Ready)

Canonical: [tag-app-delivery.cncf.io/whitepapers/platforms](https://tag-app-delivery.cncf.io/whitepapers/platforms/).

CNPA language comes from here. Memorise the **ideas**, not the PDF page numbers.

## What a platform is

A platform is an **integrated product** that offers **self-service** capabilities to users (usually developers) so they can deliver **with less cognitive load**, on top of infrastructure.

It is **not**:

- A pile of tools with no UX
- A shared cluster with no product owner
- An ops team that only takes tickets
- “We run Kubernetes”

## Platform as a product

Treat capabilities like a product:

- Named users and jobs-to-be-done
- Roadmap, docs, versioning, deprecation
- SLOs (the platform API should be as reliable as any other product)
- Feedback (DX surveys, office hours, usage metrics)
- A **product owner**, not only SREs on-call

## Capabilities (compose, don’t boil the ocean)

Typical layers: identity, compute/runtime, networking, data, CI/CD, GitOps, observability, security/policy, developer portal, cost.

The platform **composes** these into **paved paths**. App teams should not assemble the CNCF landscape themselves.

## Multi-tenancy and isolation

Platforms often offer **tenancy** (namespaces, vclusters, accounts) with **guardrails** (quotas, NetworkPolicy, PSS). Isolation level is a product choice: shared cluster vs dedicated.

## Relationship to DevOps / SRE / platform engineering

- **DevOps** = culture of sharing responsibility for delivery.
- **SRE** = reliability engineering of *services* (often including the platform).
- **Platform engineering** = building the **product** that makes DevOps scalable across many teams.

Platform engineering **enables** DevOps; it does not replace application ownership. You still want teams to own their code **and** run it — on a paved path.

## Team topologies (exam flavour)

Platform team as a **platform group**: provides compelling internal products. Avoid becoming a **complicated-subsystem** bottleneck or a pure **ticket** helpdesk.

Enabling teams may coach app teams onto the path; they should not do all app work forever.
