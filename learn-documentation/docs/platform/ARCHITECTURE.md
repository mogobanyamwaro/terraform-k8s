# Platform Architecture

**Document Owner:** Engineering  
**Classification:** Internal — Technical  
**Status:** Living document  
**Scope:** Applies to all modules (attendance, shift, and future bounded contexts).

---

## 1. Purpose

This document describes the **platform-level** architecture: shared runtime, cross-cutting concerns, and how modules fit together. It is the single place for “how we build and run services” across the product. Module-specific design lives under [../modules/](../modules/).

---

## 2. Platform Context

The product is a **multi-module platform**. Each module is a bounded context (e.g. attendance, shift) with its own domain model, API surface, and optionally its own persistence schema. They share a common runtime, auth, and operational standards.

```
                         +------------------+
                         |   IdP / SSO      |
                         |   (Auth only)    |
                         +--------+---------+
                                  |
                                  v
+-----------+    +----------------+----------------+    +------------------+
|  Clients  |----|     API Service (single app)      |----|  HR / Payroll    |
| (Web/App) |    |  /api/v1/attendance  /api/v1/shift  |    |  (downstream)     |
+-----------+    |  Shared: auth, logging, health     |    +------------------+
                 +----------------+-------------------+
                                  |
                    +-------------+-------------+
                    |                           |
                    v                           v
           +----------------+          +----------------+
           |  Module data   |          |  Module data   |
           |  (attendance)  |          |  (shift)       |
           +----------------+          +----------------+
```

- **Clients:** Web or mobile apps (and internal services) call the platform API over HTTPS. URL path identifies the module (e.g. `/api/v1/attendance/...`, `/api/v1/shift/...`).
- **IdP/SSO:** Authentication only. All modules validate the same JWT; no module owns user identity.
- **API Service:** One deployable unit (Node/Express) that hosts all modules. Shared middleware: auth, correlation ID, error handling, health. Each module is a set of routes and use cases; they do not call each other via HTTP inside the process but may share libraries and DB connection pools.
- **Module data:** Each module has its own tables/schemas (or logical schema within a shared DB). No direct cross-module DB access; integration via published events or defined APIs.

---

## 3. Layered Structure (All Modules)

Every module follows the same layering so that onboarding and code reviews are consistent:

| Layer              | Responsibilities                                       | Pattern                                                    |
| ------------------ | ------------------------------------------------------ | ---------------------------------------------------------- |
| **API**            | Routing, validation, authz, error handling, logging    | Thin handlers; delegate to application layer               |
| **Application**    | Use cases, orchestration, business rules that need I/O | Depends on interfaces (repositories, events); no framework |
| **Domain**         | Entities, value objects, domain rules without I/O      | Pure where possible; no DB or HTTP                         |
| **Infrastructure** | DB, HTTP clients, event publishing, external APIs      | Implements interfaces from application/domain              |

Module-specific docs (e.g. [Attendance DESIGN](../modules/attendance/DESIGN.md)) describe each module’s resources and flows within this structure.

---

## 4. Cross-Cutting Concerns

### 4.1 Authentication and Authorization

- **Authentication:** JWT from existing IdP; validated once per request by shared middleware. All modules use the same token and claims. See [ADR-004: JWT-based authentication](decisions/004-jwt-authentication.md).
- **Authorization:** Enforced in the application layer per module. Pattern: identity from JWT (e.g. `sub`, roles); then “can this identity perform this action on this resource?”. No sensitive authz data in JWTs beyond what IdP provides.

### 4.2 API Style and Versioning

- **REST:** Resource-oriented HTTP APIs; JSON body. See [ADR-003: REST over GraphQL](decisions/003-rest-over-graphql.md).
- **Versioning:** URL path, e.g. `/api/v1/<module>/...`. Backward-incompatible changes introduce a new version (e.g. `v2`).
- **Idempotency:** Critical writes accept an idempotency key (header or body) where duplicate submission is a risk.

### 4.3 Data and Persistence

- **Primary store:** Relational database (PostgreSQL recommended) for all modules. Each module has its own schema or schema prefix. See [ADR-002: Relational database](decisions/002-relational-database-for-events.md).
- **No cross-module DB access:** Modules do not query each other’s tables. Integration via APIs or async events.

### 4.4 Observability

- **Logging:** Structured (JSON); correlation ID on every request; no passwords or tokens.
- **Metrics:** Request count/latency by route and status; module-specific metrics as needed.
- **Health:** `GET /health` (liveness), `GET /health/ready` (readiness, e.g. DB). Platform-level; modules can register readiness checks.

---

## 5. Module Registry

| Module                                          | Approach                                      | Design                                    | Status  |
| ----------------------------------------------- | --------------------------------------------- | ----------------------------------------- | ------- |
| [Attendance](../modules/attendance/APPROACH.md) | [APPROACH](../modules/attendance/APPROACH.md) | [DESIGN](../modules/attendance/DESIGN.md) | Active  |
| [Shift](../modules/shift/APPROACH.md)           | [APPROACH](../modules/shift/APPROACH.md)      | [DESIGN](../modules/shift/DESIGN.md)      | Planned |

New modules: add a folder under `docs/modules/<module>/` with `APPROACH.md` and `DESIGN.md`; add a row to this table and to [DOCUMENTATION_INDEX.md](../DOCUMENTATION_INDEX.md).

---

## 6. Platform ADRs

Decisions that apply to the whole platform (runtime, API style, auth, data store) are recorded here:

| ADR                                                    | Title                                    |
| ------------------------------------------------------ | ---------------------------------------- |
| [001](decisions/001-express-as-api-framework.md)       | Use of Express as API framework          |
| [002](decisions/002-relational-database-for-events.md) | Relational database for event/store data |
| [003](decisions/003-rest-over-graphql.md)              | REST over GraphQL                        |
| [004](decisions/004-jwt-authentication.md)             | JWT-based authentication                 |

Module-specific ADRs (e.g. “how attendance events are stored”) live under `docs/modules/<module>/decisions/` if needed.
