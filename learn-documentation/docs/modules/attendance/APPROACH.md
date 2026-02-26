# Attendance Module — Approach & Scope

**Document Owner:** Engineering  
**Audience:** Engineering team, product, stakeholders  
**Status:** Proposal  
**Last Updated:** 2025-02-06  
**Module:** Attendance (bounded context)

---

## 1. Executive Summary

This document outlines the approach for the **attendance** module within the platform. Attendance is one bounded context among others (e.g. shift). The goal is a maintainable, auditable solution that integrates with existing identity and HR systems and aligns with [platform architecture](../../platform/ARCHITECTURE.md).

---

## 2. Problem Statement

- **Track presence:** Who was where, when (clock-in/out, geo, device).
- **Auditability:** Immutable records for compliance and disputes.
- **Integration:** Plug into existing auth, HR, and reporting without tight coupling.

---

## 3. Module Boundaries

| Inside the module                                   | Outside (integrated via contracts)     |
| --------------------------------------------------- | -------------------------------------- |
| Attendance events (in/out, breaks, overtime rules)  | User/employee identity (from IdP/HR)   |
| Policies (shift templates, grace periods, rounding) | Payroll (consumes aggregated data)     |
| Audit log of attendance changes                     | Reporting/BI (reads via API or events) |

**Principle:** This module does not own user master data; it receives identifiers (e.g. `userId`, `employeeId`) and optionally caches minimal attributes. Authoritative identity lives in the existing IdP/HR system. **Shift** (schedules, templates) may be a separate module; attendance consumes shift context via API or events where needed.

---

## 4. High-Level Approach

### 4.1 Phasing

1. **Phase 1 — Core events:** REST API for clock-in/clock-out (and optionally break start/end); store raw events; minimal business rules; optional daily/weekly summary.
2. **Phase 2 — Policies and rules:** Shift templates, grace periods, rounding; derive attendance state (late, on-time, absent) from events + policies.
3. **Phase 3 — Integration and scale:** Outbound events (payroll/reporting); reporting API; read replicas or caches if needed.

### 4.2 Design Principles

- **Event-centric:** Store factual events first; derive state and reports from events + policies.
- **API-first:** All capabilities via REST (and optionally events); see [platform ADR-003](../../platform/decisions/003-rest-over-graphql.md).
- **Explicit contracts:** Versioned API and event schemas; backward-compatible evolution where possible.
- **Security by default:** Authn via IdP (JWT); authz by role/resource; see [platform ADR-004](../../platform/decisions/004-jwt-authentication.md).
- **Operability:** Structured logging, correlation IDs, health; see [platform ARCHITECTURE](../../platform/ARCHITECTURE.md).

---

## 5. Out of Scope (Initial Release)

- Payroll calculation (we provide data; payroll owns calculation).
- Full workforce scheduling (shift module; integrate later).
- Biometric hardware (can be added behind the same “record event” API later).

---

## 6. Success Criteria

- Record and query attendance via API with clear audit trail.
- Design supports policy and integration changes without big rewrites.
- Documentation and ADRs give new engineers a clear path to extend the module.

---

## 7. Next Steps

- Align with team on boundaries and phasing.
- Confirm identity model (who provides `userId` / `employeeId`).
- Implement Phase 1 behind agreed API contract; see [DESIGN.md](DESIGN.md).
