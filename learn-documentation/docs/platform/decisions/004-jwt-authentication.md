# ADR-004: JWT-Based Authentication

**Status:** Accepted  
**Date:** 2025-02-06  
**Deciders:** Engineering  
**Scope:** Platform (all modules).

---

## Context

The platform API must authenticate callers (users or services) for all modules. We need to choose how authentication is performed at the platform boundary.

**Options considered:** JWT from existing IdP, opaque session tokens + session store, API keys (service-to-service), mTLS.

---

## Decision

We will use **JWT-based authentication** for user and client access across the platform. The API accepts JWTs issued by the organization’s existing IdP (e.g. OAuth2/OIDC) and validates signature, expiry, and issuer. We do not maintain a session store for user authentication. **Authorization** (who can do what per module) is implemented in each module’s application layer using claims (e.g. `sub`, `roles`, `team_ids`) and resource ownership.

Service-to-service callers will use a separate mechanism (e.g. API key or service JWT) to be defined when needed; this ADR covers user-facing authentication.

---

## Rationale

1. **Leverage existing IdP:** One place for login, MFA, and account lifecycle; we only validate tokens and read claims.
2. **Stateless:** No shared session store; scaling and deployment are simpler. Revocation via short-lived tokens and IdP refresh.
3. **Standards and ecosystem:** JWT/OIDC and Express middleware are mature; security and platform teams understand this model.
4. **Multi-module consistency:** Same auth middleware for attendance, shift, and future modules; each module implements its own authz rules.

---

## Consequences

- **Positive:** No session store, alignment with IdP, stateless scaling, one auth pattern for all modules.
- **Negative:** Revocation before expiry depends on IdP or short TTL; we use short-lived access tokens to limit exposure.
- **Neutral:** IdP configuration changes may require config or deployment updates.

---

## Alternatives Not Chosen

- **Opaque session tokens + Redis:** Revisit if immediate revocation is required and we accept operating a session store.
- **API key only:** For machine-to-machine; not for user context.
