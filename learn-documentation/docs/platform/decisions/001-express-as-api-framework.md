# ADR-001: Use of Express as API Framework

**Status:** Accepted  
**Date:** 2025-02-06  
**Deciders:** Engineering  
**Scope:** Platform (all modules).

---

## Context

We need a runtime and HTTP framework for the platform API that hosts all modules (attendance, shift, etc.). Node.js is the chosen runtime. The decision is which **framework** to use on top of Node’s `http` module.

**Candidates considered:** Express.js, Fastify, NestJS, Hono, raw Node.js.

---

## Decision

We will use **Express.js** as the API framework for the platform. All modules (attendance, shift, future) are implemented as Express routers mounted under versioned paths (e.g. `/api/v1/attendance`, `/api/v1/shift`).

---

## Rationale

1. **Team and organizational fit:** De facto standard in Node; easy onboarding and code review across modules.
2. **Ecosystem and middleware:** Auth, logging, CORS, rate limiting, error handling available and battle-tested; shared across modules.
3. **Sufficient performance:** Request volume and latency for this product are within Express’s capabilities; bottleneck is DB and business logic.
4. **Stability:** Stable API and upgrade path; preferred for compliance-sensitive domains (attendance, shift).
5. **NestJS trade-off:** More structure/DI at the cost of a larger footprint; for a multi-module but single-app platform, Express + explicit layering keeps the codebase consistent and easy to extend.

---

## Consequences

- **Positive:** Fast ramp-up, rich middleware, one pattern for all modules.
- **Negative:** Structure (layers, validation) is enforced by convention and standards, not by the framework.
- **Neutral:** Future framework migration would require a new ADR and platform-wide change.

---

## Alternatives Not Chosen

- **Fastify:** Revisit if profiling shows HTTP layer as a bottleneck.
- **NestJS:** Revisit if we standardize on it for multiple deployable services.
