# CCA Pitfalls

1. Thinking Cilium is “just a CNI” — it is also policy, Hubble, optional kube-proxy, mesh, BGP.
2. Mixing **istiod / sidecars** into Cilium architecture answers.
3. Operator on the packet path — it is **not**.
4. Agent down = whole cluster dead — it is **that node’s CNI**.
5. **cluster-pool IPAM** attributed to the agent only — **operator** carves pools.
6. Native routing without a way to route pod CIDRs.
7. VXLAN port 4789 (that is another VXLAN default; Cilium Linux often **8472**).
8. Enabling **WireGuard and IPsec** together.
9. Encryption = NetworkPolicy.
10. kube-proxy **plus** kube-proxy replacement.
11. Identity = pod IP.
12. `world` = all pods.
13. Unselected endpoint is default deny in **default** mode — it is **allow**.
14. Ingress-only policy locks egress too.
15. `fromEndpoints` matches all namespaces — **same ns** unless namespace label.
16. FQDN without allowing **kube-dns**.
17. L7 Hubble without L7 visibility.
18. Kubernetes NP can do HTTP paths — **no**.
19. NP ignored when CNP exists — **both apply**.
20. Cilium mesh requires sidecars.
21. Ingress always hits Cilium without `ingressClassName`.
22. Gateway API = Ingress object.
23. Cluster Mesh merges API servers.
24. Duplicate **cluster-id** or overlapping CIDRs.
25. Global Service without annotation / mismatched name.
26. Hubble = Prometheus app metrics.
27. `cilium connectivity test` is optional trivia — it is the official install check.
28. iptables and eBPF have the same scaling story.
29. Masquerade still used when you advertised pod CIDRs and wanted source IP.
30. Egress Gateway = Ingress.
31. BGP replaces eBPF.
32. `host` entity = remote internet.
33. cluster-id 0 is fine.
34. Changing labels never changes identity.
35. Closed-book: you cannot look this list up — drill it.
