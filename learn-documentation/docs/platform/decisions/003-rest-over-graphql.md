# ADR-003: REST over GraphQL

**Status:** Accepted  
**Date:** 2025-02-06  
**Deciders:** Engineering  
**Scope:** Platform (all modules).

---

## Context

The platform must expose APIs for all modules (attendance, shift, etc.). We need to choose the primary API style: **REST** or **GraphQL**.

---

## Decision

We will expose **REST APIs** as the primary interface for all modules. Versioning is in the URL path (e.g. `/api/v1/attendance/...`, `/api/v1/shift/...`). We document contracts with OpenAPI. Downstream integration uses REST or async events; we do not use GraphQL subscriptions for the initial platform.

---

## Rationale

1. **Domain fit:** Current modules are “create/read/update resource” and “list/filter”; these map cleanly to REST. No need for client-defined query graphs yet.
2. **Simplicity and tooling:** REST is universal; gateways, caching, and monitoring work out of the box. OpenAPI supports documentation and contract testing for every module.
3. **Caching and idempotency:** GET is cacheable; POST with idempotency keys is standard. GraphQL’s typical single-POST endpoint complicates both.
4. **Enterprise alignment:** Security and governance tooling expect REST; one consistent style across attendance, shift, and future modules.
5. **Future flexibility:** A dedicated GraphQL or reporting endpoint can be added later without changing the core REST contract.

---

## Consequences

- **Positive:** One style for all modules, easy to document and test, cacheable reads.
- **Negative:** Clients needing very different shapes may require multiple calls or dedicated endpoints; we add those when justified.
- **Neutral:** Pagination, filtering, and sort conventions are defined at platform level and reused by every module.

---

## Alternatives Not Chosen

- **GraphQL:** Revisit if we gain many clients with divergent data needs and the overhead of schema/resolvers is justified.
- **gRPC:** Revisit for internal service-to-service only.
