# BGP and External Networking Deep Dive

**Masquerade:** hide pod CIDR, SNAT to node/egress-gateway IP. Needed when WAN cannot route pods.

**Advertise:** BGP or cloud/ENI native routing so the fabric knows pod CIDRs / LB VIPs. Then you can disable masquerade for that path.

**Egress Gateway:** `CiliumEgressGatewayPolicy` → stable egress IPs.

**LB-IPAM + BGP:** LoadBalancer Services on metal.

**Peers:** ASN + router IP. Don’t overlap prefixes.

**externalTrafficPolicy: Local** preserves client IP more often.

See `23.md`–`24.md`.
