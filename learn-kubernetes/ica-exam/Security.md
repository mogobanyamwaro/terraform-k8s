# Security Reference

Zero-trust pieces:

| Resource | Job |
| --- | --- |
| PeerAuthentication | Inbound mTLS mode |
| DestinationRule tls | Outbound TLS mode |
| RequestAuthentication | Validate JWT |
| AuthorizationPolicy | Allow/deny after identity exists |
| Gateway tls | Edge TLS |
| istiod CA / cacerts | Workload certificates |

Identity: `spiffe://<trustDomain>/ns/<ns>/sa/<sa>`  
Policy principal: `cluster.local/ns/<ns>/sa/<sa>`

Default mTLS **PERMISSIVE**. Enforce with **STRICT**.

Default authz **allow all** until an ALLOW policy selects the workload (then default deny).

JWT: invalid → **401**. Missing with require-authz → **403**. RA does not require tokens.

Files: `22.md`–`28.md`.
