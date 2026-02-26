# Attendance Module — Design

**Document Owner:** Engineering  
**Classification:** Internal — Technical  
**Status:** Living document  
**Module:** Attendance

Platform-wide architecture (layers, auth, observability) is in [../../platform/ARCHITECTURE.md](../../platform/ARCHITECTURE.md). This document covers **attendance-specific** context, data model, and API.

---

## 1. Module Context

```
                    +------------------+
                    |   IdP / SSO      |
                    +--------+---------+
                             |
                             v
+-----------+         +------+------+         +------------------+
|  Clients  |--------|  Platform API  |--------|  HR / Payroll    |
| (Web/App)|  REST  | /attendance/*  | Events |  (downstream)     |
+-----------+         +------+------+         +------------------+
                             |
                             v
                    +------------------+
                    |  attendance_*    |
                    |  (module schema)|
                    +------------------+
```

- **API path:** `POST/GET /api/v1/attendance/...` (see [Platform ARCHITECTURE](../../platform/ARCHITECTURE.md)).
- **Data:** Own schema/tables (e.g. `attendance_events`); no direct access to other modules’ tables. Integration via APIs or events.

---

## 2. Data Model (Conceptual)

- **AttendanceEvent:** Immutable record of one action. Fields: `id`, `userId`, `type` (clock-in, clock-out, break-start, break-end), `timestamp`, `source` (web/app), optional `metadata` (e.g. geo, device).
- **Policies (Phase 2):** Shift templates, grace periods, rounding — reference data; applied when computing derived attendance. May reference the Shift module via contract, not DB.
- **Audit:** All mutations logged (who, when, what) for compliance; same table or separate audit log.

---

## 3. API (Attendance)

- **Record event:** `POST /api/v1/attendance/events` — body: `{ type, timestamp?, idempotencyKey? }`. Idempotency key required for clock-in/out.
- **List events:** `GET /api/v1/attendance/events?userId=...&from=...&to=...` — filtered by user and time range.
- **Summary:** `GET /api/v1/attendance/summary?userId=...&date=...` — daily (or weekly) summary by user.

Versioning and auth follow platform standards ([ADR-003](../../platform/decisions/003-rest-over-graphql.md), [ADR-004](../../platform/decisions/004-jwt-authentication.md)). OpenAPI spec to be added under `docs/api/` when ready.

---

## 4. References

- [Platform ARCHITECTURE](../../platform/ARCHITECTURE.md)
- [Attendance APPROACH](APPROACH.md)
- [Platform ADRs](../../platform/decisions/README.md)
