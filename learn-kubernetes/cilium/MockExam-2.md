# Mock Exam 2

Harder. 90 minutes. 60 questions. Key at the end. Aim 45+.

**1.** Cilium can replace kube-proxy **and** still:  
A. Require iptables for every ClusterIP  
B. Implement NetworkPolicy in eBPF  
C. Remove the API server  
D. Disable Hubble permanently  

**2.** Hubble Relay crash:  
A. Stops all pod traffic  
B. Breaks cluster-wide CLI/UI aggregation; node datapath continues  
C. Deletes identities  
D. Forces native routing  

**3.** ENI IPAM is paired most often with:  
A. Mandatory VXLAN  
B. Native routing in the VPC  
C. hostNetwork  
D. Istio only  

**4.** Geneve default UDP port:  
A. 8472  
B. 6081  
C. 4789  
D. 443  

**5.** Hybrid NodePort mode:  
A. Disables TCP  
B. Mixes DSR/SNAT depending on protocol/config  
C. Is IPAM  
D. Is Hubble  

**6.** XDP NodePort is attractive because:  
A. It runs in Hubble UI  
B. Packets can be processed very early  
C. It needs iptables first  
D. It replaces etcd  

**7.** IPsec vs WireGuard:  
A. Enable both  
B. IPsec usually more operational complexity; WG simpler  
C. WG cannot encrypt  
D. IPsec is Hubble  

**8.** Same-node two pods, WireGuard on:  
A. Must leave NIC encrypted  
B. Often never hits WG  
C. Always VXLAN to self  
D. Always dropped  

**9.** Identity GC is:  
A. Agent XDP  
B. Operator cleaning unused identities  
C. Ingress  
D. BGP  

**10.** `init` identity:  
A. Hubble UI  
B. Endpoint while still initializing  
C. world  
D. Maglev  

**11.** `remote-node` vs `world`:  
A. Identical  
B. Other nodes vs outside that classification  
C. IPv6 vs IPv4  
D. TCP vs UDP  

**12.** Enforcement `always`:  
A. Hubble 100%  
B. Default deny even without selecting policy  
C. kube-proxy on  
D. VXLAN on  

**13.** Enforcement `never`:  
A. CNI off  
B. Policies not enforced  
C. Mesh required  
D. IPv6 only  

**14.** `ingressDeny` vs allow:  
A. Allow wins  
B. Deny takes precedence  
C. Random  
D. Hubble wins  

**15.** Cross-namespace allow needs:  
A. Nothing  
B. Namespace label on the peer selector (or broad entity)  
C. Maglev  
D. Geneve  

**16.** `toServices` in CNP:  
A. Replaces kube-apiserver  
B. Egress to a Kubernetes Service  
C. GatewayClass  
D. IPAM  

**17.** Empty `ingress: []` on selecting NP:  
A. Allow all ingress  
B. Isolate ingress  
C. Enable BGP  
D. Create Service  

**18.** Kafka L7:  
A. NP v1  
B. CNP L7 rules  
C. Maglev  
D. LB-IPAM  

**19.** Combined NP+CNP allowing different ports:  
A. Union (more open)  
B. Intersection (must pass both)  
C. NP ignored  
D. CNP ignored  

**20.** `matchPattern: "*"` DNS rule:  
A. Blocks DNS  
B. Allows DNS queries (still need L4 to resolver)  
C. Enables IPsec  
D. Sets cluster-id  

**21.** Cilium Ingress implementation:  
A. nginx in kube-system always  
B. Envoy integrated with Cilium  
C. kube-scheduler  
D. Flannel  

**22.** Missing ingressClassName:  
A. Always Cilium  
B. Cluster default class  
C. Always 404  
D. Always NodePort all apps  

**23.** HTTPRoute `parentRefs`:  
A. IPAM  
B. Attach to a Gateway  
C. cluster-id  
D. Maglev  

**24.** `allowedRoutes` from Same namespace:  
A. WireGuard  
B. Stops other namespaces binding routes  
C. VXLAN VNI  
D. Pod CIDR  

**25.** Gateway API TCPRoute exists to:  
A. Prove Ingress is TCP-native in all controllers  
B. Model non-HTTP listeners better than classic Ingress  
C. Replace CNI  
D. Disable TLS  

**26.** App mTLS (Istio) vs Cilium WG:  
A. Identical trust  
B. WG is node-level; mTLS is workload identity in the app/proxy  
C. WG replaces JWT  
D. Istio replaces eBPF maps  

**27.** L7 HTTP policy without cilium-envoy:  
A. Still works in pure eBPF for paths  
B. Generally cannot parse HTTP paths  
C. Uses BGP  
D. Uses Maglev headers  

**28.** `hubble observe --from-pod shop/client`:  
A. Operator logs  
B. Flows sourced from that pod  
C. All clusters  
D. XDP dump  

**29.** Prometheus + Hubble:  
A. Forbidden  
B. Hubble can export metrics Prometheus scrapes  
C. Hubble replaces PromQL  
D. Needs Istio  

**30.** Compact Hubble view lacks a field:  
A. Reinstall cluster  
B. Use `-o json`  
C. Enable BGP  
D. Disable eBPF  

**31.** `cilium config set` may:  
A. Never restart agents  
B. Roll agents / reprogram datapath  
C. Delete nodes  
D. Wipe etcd  

**32.** connectivity test policy failures:  
A. Always IPAM  
B. Enforcement/identity/DNS  
C. Always Gateway CRDs  
D. Always encryption  

**33.** Helm vs CLI install:  
A. CLI only legal  
B. Both valid; CLI often wraps chart  
C. Helm forbidden  
D. Only Windows  

**34.** Privileges agent needs:  
A. Only ConfigMap read in default  
B. BPF, host netns, CNI, NET_ADMIN-style caps  
C. Hubble cookies  
D. GitHub  

**35.** Upgrade Cilium:  
A. Random `kubectl set image` without values  
B. CLI/Helm with values, read datapath notes  
C. Delete CNI forever  
D. Restart etcd only  

**36.** Duplicate cluster-id 7 in two meshes:  
A. Fine  
B. Identity/endpoint conflict  
C. Enables IPv6  
D. Replaces kube-proxy  

**37.** Overlapping 10.0.0.0/8 pod CIDRs in mesh:  
A. Recommended  
B. Routing/identity nightmare  
C. Required for IPsec  
D. Maglev  

**38.** Global Service different namespaces `web` vs `app`:  
A. Automatically mesh  
B. Not the same global service  
C. Hubble merges them  
D. BGP merges  

**39.** Remote cluster policy:  
A. Only `world`  
B. Cluster label / remote identities  
C. Maglev  
D. Ingress class  

**40.** `cilium clustermesh connect` before enable:  
A. Works always  
B. Both clusters should enable mesh first  
C. Deletes CNI  
D. Sets VXLAN 0  

**41.** Control plane after mesh:  
A. One etcd  
B. Still two apiservers  
C. Hubble is apiserver  
D. Operator is apiserver  

**42.** eBPF program attach point for early LB:  
A. Hubble CSS  
B. XDP  
C. etcd  
D. Ingress annotation  

**43.** Map update vs iptables-restore:  
A. Same cost  
B. Maps patch incrementally; iptables often reloads large blobs  
C. iptables faster always  
D. Maps need reboot  

**44.** Calico can also use eBPF. CCA still wants:  
A. Cilium-specific identity Hubble kube-proxy-replacement story  
B. Calico is the answer to every Cilium question  
C. iptables is faster than eBPF by definition  
D. eBPF is JavaScript  

**45.** Userspace operator cannot:  
A. Exist  
B. Sit in the packet fast path  
C. Do IPAM  
D. Do GC  

**46.** Socket-level LB:  
A. Envoy sidecar  
B. ClusterIP translated at connect()  
C. UDP only  
D. Disables NP  

**47.** Masquerade + node egress firewall deny 443:  
A. Pods still reach the internet on 443  
B. Pods fail using the node’s path  
C. Only ClusterIP fails  
D. Only UDP  

**48.** Egress Gateway vs Ingress:  
A. Same  
B. EG = outbound SNAT pin; Ingress = inbound HTTP  
C. Both Hubble  
D. Both BGP only  

**49.** Advertise pod CIDR with BGP then leave masquerade on:  
A. Always optimal  
B. External sees node IP still if masquerade applies  
C. Hubble breaks  
D. Identities vanish  

**50.** `externalTrafficPolicy: Cluster` on LB:  
A. Always preserves client IP  
B. May SNAT and hop extra nodes  
C. Disables BGP  
D. Enables FQDN  

**51.** Metal LoadBalancer without cloud:  
A. Impossible  
B. LB-IPAM + BGP (or MetalLB)  
C. hostNetwork all  
D. cluster-id 0  

**52.** ToR rejects prefix:  
A. Hubble issue  
B. BGP advertisement not installed; LB/pod IPs unreachable from fabric  
C. eBPF verifier  
D. Maglev CSS  

**53.** `fromEntities: [cluster]`:  
A. Internet  
B. Broad in-cluster (all clusters/identities classified as cluster)  
C. host only  
D. world only  

**54.** L7 visibility annotation/policy vs L7 deny:  
A. Same  
B. Visibility can populate Hubble without extra deny; deny also drops  
C. Visibility drops always  
D. Deny never Hubble  

**55.** kube-proxy still present with replacement true:  
A. Faster DNS  
B. Risk of conflicting Service datapaths  
C. Required  
D. Enables IPsec  

**56.** `tunnel-protocol=vxlan` while native routing expected in VPC ENI:  
A. Always best  
B. Extra overlay often unnecessary/wrong for that design  
C. Required by AWS  
D. Disables identities  

**57.** Hubble UI without Relay in multi-node:  
A. Full mesh view guaranteed  
B. Incomplete/wrong mental model; use Relay  
C. Enables encryption  
D. Disables policy  

**58.** `service.cilium.io/global` on only one cluster:  
A. Perfect HA  
B. Incomplete; other cluster needs matching global Service  
C. Hubble fills backends  
D. BGP fills  

**59.** Which is false?  
A. Agent programs eBPF  
B. Operator allocates cluster-pool CIDRs  
C. Hubble Relay allocates all pod IPs  
D. Identities live in maps  

**60.** Closed-book CCA passing score:  
A. 66%  
B. 68%  
C. 75%  
D. 90%  

---

## Answer key

1B 2B 3B 4B 5B 6B 7B 8B 9B 10B  
11B 12B 13B 14B 15B 16B 17B 18B 19B 20B  
21B 22B 23B 24B 25B 26B 27B 28B 29B 30B  
31B 32B 33B 34B 35B 36B 37B 38B 39B 40B  
41B 42B 43B 44A 45B 46B 47B 48B 49B 50B  
51B 52B 53B 54B 55B 56B 57B 58B 59C 60C  

Q59 is the odd one: **C is false**. Score carefully.

If < 40: reread `Pitfalls.md` and architecture/policy.  
40–44: Cluster Mesh + Hubble L7 + BGP masquerade vs advertise.  
45+: Mock 1 under time, then `Flashcards.md`.
