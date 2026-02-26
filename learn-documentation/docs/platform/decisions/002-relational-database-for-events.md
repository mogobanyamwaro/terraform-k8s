# ADR-002: Relational Database for Event and Reference Data

**Status:** Accepted  
**Date:** 2025-02-06  
**Deciders:** Engineering  
**Scope:** Platform (all modules).

---

## Context

Module data (e.g. attendance events, shift definitions) must be stored durably and support querying by identity, time range, and reference data. We need to choose the primary store for events and reference data **across all modules**.

**Candidates considered:** Relational DB (e.g. PostgreSQL), document store (e.g. MongoDB), dedicated event store (e.g. EventStoreDB), hybrid.

---

## Decision

We will use a **relational database (PostgreSQL recommended)** as the primary store for all modules. Each module has its own schema or schema prefix (e.g. `attendance_events`, `shift_templates`). We store “event-like” and reference rows; we do **not** adopt a full event-sourcing architecture at the platform level. Strong consistency and ACID apply to all module data.

---

## Rationale

1. **Auditability and compliance:** Sensitive data (attendance, shifts) may be audited. ACID and strong consistency avoid ambiguous or out-of-order states across modules.
2. **Query patterns:** User/time-range and reference-data access fit indexed relational tables; PostgreSQL JSONB supports flexible metadata where needed.
3. **Operational simplicity:** One DB technology, one backup/restore story, one set of runbooks. Event-store-specific concepts (projections, snapshots) are deferred.
4. **Multi-module consistency:** Same persistence model for attendance, shift, and future modules reduces cognitive load and allows shared connection pooling and migration tooling.
5. **Document DB / event store:** Revisit only if a specific module has a strong requirement that cannot be met with relational storage.

---

## Consequences

- **Positive:** Strong consistency, simple operations, one pattern for all modules.
- **Negative:** Schema changes require migrations; design tables with forward-thinking (e.g. JSONB for optional metadata).
- **Neutral:** Read replicas or caches can be added per module or platform-wide later.

---

## Alternatives Not Chosen

- **EventStoreDB:** Revisit if we adopt event sourcing across bounded contexts.
- **MongoDB:** Revisit if a module requires highly variable nested payloads and accepts eventual consistency.
