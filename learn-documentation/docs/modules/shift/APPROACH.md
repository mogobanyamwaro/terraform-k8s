# Shift Module — Approach & Scope

**Document Owner:** Engineering  
**Audience:** Engineering team, product, stakeholders  
**Status:** Planned  
**Last Updated:** 2025-02-06  
**Module:** Shift (bounded context)

---

## 1. Executive Summary

This document is a **placeholder** for the **shift** module. Shift will be a bounded context alongside attendance: defining schedules, shift templates, and assignments. It will follow the same platform standards ([platform ARCHITECTURE](../../platform/ARCHITECTURE.md)) and be exposed under `/api/v1/shift/...`.

---

## 2. Problem Statement (Draft)

- **Define shifts:** Templates, time windows, recurrence.
- **Assign people:** Who works which shift when (may integrate with attendance for clock-in/out against assigned shifts).
- **Integration:** Consumed by attendance (e.g. policies), reporting, and potentially workforce scheduling.

---

## 3. Module Boundaries (Draft)

| Inside the module            | Outside (contracts)       |
| ---------------------------- | ------------------------- |
| Shift templates, definitions | User/employee (from IdP)  |
| Assignments, schedule        | Attendance (reads refs)   |
|                              | Reporting (reads via API) |

---

## 4. Phasing (TBD)

To be defined when the module is prioritised. Likely: Phase 1 — templates and CRUD; Phase 2 — assignments and calendar; Phase 3 — integration with attendance and reporting.

---

## 5. Next Steps

- Align with product on scope and priority.
- Add [DESIGN.md](DESIGN.md) when design work starts.
- Create module ADRs under `decisions/` only if module-specific decisions are needed.
