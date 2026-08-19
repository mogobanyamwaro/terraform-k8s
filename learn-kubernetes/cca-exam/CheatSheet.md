# CCA CheatSheet

Closed book. 60 Q, 90 min, **75%**. Connect, secure, observe.

| Piece | Role |
| --- | --- |
| agent DS | eBPF, CNI, policy, Hubble observer |
| operator Deploy | IPAM cluster-pool, GC, mesh helpers |
| Hubble Relay | cluster flows |
| Envoy node | L7 / Ingress / Gateway |

**Datapath:** VXLAN 8472 / Geneve 6081 / native. WG **xor** IPsec.

**IPAM:** cluster-pool (operator), kubernetes (Node CIDR), eni/azure.

**kube-proxy replacement:** eBPF LB. DSR vs SNAT. Maglev. XDP.

**Policy:** unselected = allow (default). Selected = deny except allows. CNP = L7/FQDN/entities/deny. NP = L3/L4. CCNP = cluster. Identities from labels. Entities: world, host, remote-node.

**FQDN:** allow DNS + toFQDNs.

**Mesh:** sidecarless. Ingress class `cilium`. Gateway class `cilium`.

**Hubble:** `hubble observe --verdict DROPPED`. L7 needs proxy.

**CLI:** `cilium install|status --wait|connectivity test|config view`

**Mesh:** cluster-id 1–255 unique, CIDRs disjoint, `service.cilium.io/global: "true"`, affinity local.

**eBPF vs iptables:** maps O(1) vs chains O(n); identity vs IP.

**Egress:** SNAT or advertise CIDRs. Egress Gateway. BGP for metal LB/pod CIDRs.

**ConfigMap:** `cilium-config`.
