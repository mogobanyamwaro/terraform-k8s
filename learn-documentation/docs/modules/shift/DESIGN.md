# Shift Module — Design

**Document Owner:** Engineering  
**Classification:** Internal — Technical  
**Status:** Planned  
**Module:** Shift

---

## 1. Purpose

This document will describe the **shift** module’s design: context, data model, and API. It is intentionally minimal until the module is scoped and prioritised.

---

## 2. Module Context (Draft)

- **API path:** `/api/v1/shift/...` (see [Platform ARCHITECTURE](../../platform/ARCHITECTURE.md)).
- **Data:** Own schema/tables (e.g. `shift_templates`, `shift_assignments`). No direct DB access from or to other modules; integration via APIs or events.
- **Relationship to Attendance:** Attendance may reference shift definitions (e.g. “expected shift”) via API or shared reference data contract; no cross-module DB access.

---

## 3. Data Model (TBD)

To be defined: shift template, recurrence, assignments, and any reference consumed by attendance.

---

## 4. API (TBD)

Resource-oriented REST under `/api/v1/shift/...`; exact resources and payloads to be specified when the module is designed.

---

## 5. References

- [Platform ARCHITECTURE](../../platform/ARCHITECTURE.md)
- [Shift APPROACH](APPROACH.md)
- [Platform ADRs](../../platform/decisions/README.md)
