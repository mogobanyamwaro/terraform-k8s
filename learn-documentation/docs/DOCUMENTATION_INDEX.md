# Documentation Index

**Audience:** Engineering, product, and stakeholders.  
**Use this index** to find the right document. We do not rely on a single README for design and decisions.

This is a **multi-module platform** (attendance, shift, and future modules). Documentation is split into **platform** (shared) and **modules** (per bounded context).

---

## Platform (shared across all modules)

| Document                                             | Purpose                                                                                                             |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| [platform/ARCHITECTURE.md](platform/ARCHITECTURE.md) | How the platform is built: runtime, layers, auth, API style, observability. Start here for “how we build services.” |
| [platform/decisions/](platform/decisions/)           | Architecture Decision Records (ADRs): why Express, relational DB, REST, JWT. Apply to all modules.                  |

---

## Modules (per bounded context)

Each module has an **APPROACH** (scope, boundaries, phasing — for pitching and alignment) and a **DESIGN** (context, data model, API — for implementation).

| Module         | Approach                                                         | Design                                                       | Status  |
| -------------- | ---------------------------------------------------------------- | ------------------------------------------------------------ | ------- |
| **Attendance** | [modules/attendance/APPROACH.md](modules/attendance/APPROACH.md) | [modules/attendance/DESIGN.md](modules/attendance/DESIGN.md) | Active  |
| **Shift**      | [modules/shift/APPROACH.md](modules/shift/APPROACH.md)           | [modules/shift/DESIGN.md](modules/shift/DESIGN.md)           | Planned |

**Adding a new module:** Create `docs/modules/<module>/APPROACH.md` and `DESIGN.md`; add a row above and to the module registry in [platform/ARCHITECTURE.md](platform/ARCHITECTURE.md).

---

## Other

- **API contract:** OpenAPI spec to be added under `docs/api/` when ready.
- **Runbooks and ops:** To be added when we define deployment and support procedures.
- **Coding standards:** To be added (or linked) when we formalise structure and patterns.

---

## Document ownership and updates

- **Owner:** Engineering.
- **Platform:** Keep ARCHITECTURE and ADRs in sync with implementation; new platform-level decisions get an ADR in `platform/decisions/`.
- **Modules:** Keep each module’s APPROACH and DESIGN in sync with its implementation; module-specific ADRs go under `modules/<module>/decisions/` if needed.
