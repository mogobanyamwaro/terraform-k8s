# Service Mesh Deep Dive

Cilium mesh is **sidecarless**: eBPF L3/L4 + **node Envoy** L7.

**Ingress:** `ingressClassName: cilium`, Helm `ingressController.enabled`.

**Gateway API:** `gatewayClassName: cilium`, Gateway vs HTTPRoute, `parentRefs`, `allowedRoutes`, weights, multi-protocol.

**Why Gateway > Ingress:** role split, fewer annotations, standard extra protocols, multi-tenant listeners.

**Encryption:** WireGuard (preferred) or IPsec, not both. Node-to-node confidentiality, not app mTLS.

See `11.md`–`14.md`.
