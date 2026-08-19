# CCA Flashcards

**Cilium in three words?** Connect, secure, observe.

**Datapath tech?** eBPF.

**Agent vs operator?** Node BPF/CNI vs cluster IPAM/GC.

**Default overlay?** VXLAN.

**Geneve port?** 6081 UDP.

**VXLAN port (Cilium)?** 8472 UDP.

**IPAM default self-managed?** cluster-pool.

**Who allocates cluster-pool CIDRs?** Operator.

**kube-proxy replacement?** eBPF Services.

**DSR?** Backend replies toward client.

**Encryption pair?** WireGuard or IPsec.

**Unselected + default mode?** Allow all.

**Selected ingress?** Default deny ingress.

**world?** Outside cluster identities.

**host?** Local node.

**CNP extra vs NP?** L7, FQDN, entities, deny, CCNP.

**toFQDNs direction?** Egress.

**Ingress class?** cilium.

**Gateway class?** cilium.

**Sidecarless?** eBPF + node Envoy.

**Hubble source?** eBPF flows.

**Observe command?** hubble observe.

**L7 Hubble?** Need L7 proxy/visibility.

**Install check?** cilium status --wait; connectivity test.

**ConfigMap?** cilium-config.

**cluster-id range?** 1–255 unique.

**Global annotation?** service.cilium.io/global: "true".

**eBPF vs iptables?** O(1) maps vs O(n) rules.

**XDP vs iptables?** XDP earlier.

**Default egress to internet?** SNAT/masquerade.

**BGP advertises?** Pod CIDRs and/or LB IPs.

**Pass mark?** 75%. **Time?** 90 min. **Q count?** 60. **Docs?** No.
