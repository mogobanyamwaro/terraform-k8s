# Mock Exam 1

Timer: **90 minutes**. 60 questions. Closed book. Passing simulation: **45/60**.

Domain mix ≈ real exam: Architecture 12, Policy 11, Mesh 10, Hubble 6, Install 6, Cluster Mesh 6, eBPF 6, BGP 4.

Mark answers on paper. Key at the end.

---

**1.** Cilium implements Kubernetes networking primarily with:  
A. OpenFlow controllers  
B. eBPF in the Linux kernel  
C. Userspace NAT in the operator  
D. iptables only, always  

**2.** Which component is a DaemonSet?  
A. cilium-operator  
B. cilium-agent  
C. Hubble UI  
D. clustermesh-apiserver only  

**3.** Operator outage typically:  
A. Drops all in-flight TCP  
B. Leaves existing datapath up; may block new IPAM  
C. Deletes Hubble  
D. Forces VXLAN off  

**4.** cluster-pool IPAM is driven by:  
A. CoreDNS  
B. cilium-operator  
C. Ingress  
D. kube-proxy  

**5.** kubernetes IPAM mode uses:  
A. ENIs  
B. Node `podCIDR`  
C. LoadBalancer IPs  
D. Hubble identities  

**6.** Default overlay encapsulation in many installs:  
A. GRE  
B. VXLAN  
C. IP-in-IP only  
D. MPLS  

**7.** Native routing needs:  
A. No node connectivity  
B. Underlay/BGP/cloud routes for pod CIDRs  
C. Istio  
D. hostNetwork on all pods  

**8.** kube-proxy replacement puts Service LB in:  
A. Envoy in every pod  
B. eBPF  
C. etcd  
D. Hubble Relay  

**9.** DSR means:  
A. DNS round robin  
B. Backend replies toward the client without hairpinning the entry node  
C. Double SNAT required  
D. Disable Services  

**10.** WireGuard and IPsec together:  
A. Required  
B. Not supported; choose one  
C. Enable Hubble  
D. Enable Maglev  

**11.** Security identity comes from:  
A. Pod UID only  
B. Labels (namespace + selected k8s labels)  
C. MAC  
D. PVC name  

**12.** Reserved identity `world` is:  
A. All cluster pods  
B. Typically external/non-cluster  
C. kube-dns  
D. operator  

**13.** Default enforcement, no policy selects pod:  
A. Deny all  
B. Allow all  
C. Allow DNS only  
D. Allow world only  

**14.** Policy selects pod with ingress rules only:  
A. Egress also default deny  
B. Ingress default deny; egress still unrestricted (default mode)  
C. Both always deny  
D. Hubble off  

**15.** `fromEndpoints` without namespace label matches:  
A. Whole cluster  
B. Same namespace as the policy  
C. world  
D. host only  

**16.** HTTP path allow lists need:  
A. NetworkPolicy v1  
B. Cilium L7 rules (Envoy)  
C. Maglev  
D. BGP  

**17.** `toFQDNs` is:  
A. Ingress host matching  
B. Egress DNS-aware allow  
C. Cluster Mesh name  
D. IPAM  

**18.** FQDN policy also needs:  
A. Blocking port 53  
B. Allowing DNS to CoreDNS / kube-dns  
C. IPsec  
D. Geneve  

**19.** Kubernetes NetworkPolicy on Cilium:  
A. Ignored  
B. Enforced by Cilium  
C. Sent to Calico  
D. BGP only  

**20.** Feature only in CNP, not NP:  
A. podSelector  
B. `fromEntities: [host]`  
C. namespaceSelector  
D. TCP ports  

**21.** CCNP is:  
A. Namespaced  
B. Cluster-scoped  
C. Hubble CRD  
D. Ingress class  

**22.** Sidecarless mesh means:  
A. Envoy in every pod  
B. eBPF + optional per-node Envoy  
C. No L7 ever  
D. iptables mesh  

**23.** Cilium Ingress class name:  
A. nginx  
B. cilium  
C. istio  
D. traefik  

**24.** Gateway API splits:  
A. IPAM and BGP  
B. Gateway (infra) vs Route (app)  
C. Agent and CNI  
D. VXLAN and Geneve  

**25.** `gatewayClassName` for Cilium:  
A. istio  
B. cilium  
C. nginx  
D. envoy  

**26.** Benefit of Gateway API over Ingress:  
A. No HTTP  
B. Standard multi-protocol / role separation / fewer vendor annotations  
C. Replaces CNI  
D. Disables TLS  

**27.** Transparent encryption provides:  
A. App-layer JWT  
B. Node-to-node confidentiality without app changes  
C. NetworkPolicy  
D. Maglev  

**28.** Hubble data comes from:  
A. App stdout  
B. eBPF datapath  
C. kube-scheduler  
D. etcd WAL  

**29.** Hubble Relay:  
A. Allocates ENIs  
B. Aggregates node observers  
C. Is kube-proxy  
D. Is BGP  

**30.** See policy drops:  
A. `hubble observe --verdict DROPPED`  
B. `kubectl logs etcd`  
C. `cilium ipam`  
D. `helm list`  

**31.** HTTP method in Hubble requires:  
A. Only Hubble enabled  
B. L7 visibility/proxy  
C. Maglev  
D. hostNetwork  

**32.** After install, wait with:  
A. `cilium status --wait`  
B. `rm -rf /`  
C. `kubeadm reset`  
D. `hubble ui --kill`  

**33.** Datapath/Service/policy smoke test:  
A. `cilium connectivity test`  
B. `kubectl delete ns kube-system`  
C. `cilium uninstall`  
D. `iptables -F`  

**34.** View config:  
A. `cilium config view`  
B. `hubble paint`  
C. `kubectl get csr`  
D. `crictl info` only  

**35.** Typical ConfigMap:  
A. `kube-system/cilium-config`  
B. `default/coredns`  
C. `istio-system/istio`  
D. `kube-public/cluster-info` only  

**36.** kind + Cilium:  
A. Keep Flannel  
B. disableDefaultCNI  
C. Two CNIs  
D. No kernel  

**37.** Cluster Mesh needs:  
A. One merged API server  
B. Unique cluster-id and non-overlapping pod CIDRs  
C. Same node names  
D. Disabled Hubble  

**38.** cluster-id valid example:  
A. 0  
B. 42  
C. 256  
D. -1  

**39.** Global Service annotation:  
A. `service.cilium.io/global: "true"`  
B. `global: yes`  
C. `mesh.istio.io/global`  
D. `lb=world`  

**40.** `affinity: local` :  
A. Prefer local backends  
B. Prefer remote only  
C. Disable mesh  
D. Enable VXLAN  

**41.** clustermesh-apiserver:  
A. Kubernetes API  
B. Exports Cilium state to other clusters  
C. Ingress  
D. CoreDNS  

**42.** Same Service name/namespace required for:  
A. Hubble UI  
B. Global Services  
C. IPAM  
D. Maglev CSS  

**43.** eBPF runs in:  
A. Browser  
B. Linux kernel  
C. etcd  
D. Hubble CSS  

**44.** Verifier:  
A. Signs JWTs  
B. Rejects unsafe BPF programs  
C. Allocates IPs  
D. Peers BGP  

**45.** eBPF maps store:  
A. Helm values  
B. Identities, CT, LB backends  
C. YAML files  
D. PVC data  

**46.** iptables Service rules scale:  
A. O(1) always  
B. Often O(n) chain walks  
C. Better than XDP always  
D. Identity native  

**47.** XDP vs iptables:  
A. XDP later  
B. XDP can run earlier (driver)  
C. Same  
D. XDP is userspace Go  

**48.** Identity policy in kernel favours:  
A. iptables IP matches only  
B. eBPF maps keyed by identity  
C. DNS TXT  
D. Ingress TLS  

**49.** Default pod→Internet:  
A. Public pod IP everywhere  
B. Masquerade/SNAT to node or egress IP  
C. Drop  
D. VXLAN to 8.8.8.8  

**50.** Egress Gateway:  
A. Ingress controller  
B. Pins egress to dedicated nodes/IPs  
C. Hubble UI  
D. Maglev  

**51.** BGP advertises:  
A. Hubble graphs  
B. Pod CIDRs and/or LB IPs to routers  
C. NetworkPolicy YAML  
D. Identities as ASNs only  

**52.** LB-IPAM:  
A. PVC  
B. LoadBalancer IPs without cloud NLB  
C. DNS  
D. etcd  

**53.** To keep pod source IPs on WAN:  
A. Only Hubble  
B. Route pod CIDRs (BGP/cloud), don’t masquerade that path  
C. kube-proxy  
D. Ingress class  

**54.** `host` entity:  
A. Internet  
B. Local node host namespace  
C. All Ingress  
D. etcd  

**55.** Agent CrashLoop on one node:  
A. All nodes lose CNI  
B. New pods on that node fail CNI  
C. Operator dies  
D. API server dies  

**56.** Mixing NP and CNP:  
A. NP ignored  
B. Both enforced (more restrictive combo)  
C. Cluster panic  
D. eBPF unload  

**57.** Maglev:  
A. IPAM cloud  
B. Consistent-hash LB  
C. VXLAN port  
D. Reserved identity  

**58.** `cilium install --set kubeProxyReplacement=true` :  
A. Deletes Services  
B. eBPF Service datapath  
C. Hubble UI only  
D. cluster-id 0  

**59.** L7 policy cost:  
A. Always free  
B. Envoy hop vs pure eBPF L3/L4  
C. Operator per packet  
D. Disables Hubble  

**60.** CCA exam is:  
A. Hands-on 2h  
B. 60 MCQ, 90 min, 75%, closed book  
C. Oral  
D. Open book cilium.io  

---

## Answer key

1B 2B 3B 4B 5B 6B 7B 8B 9B 10B  
11B 12B 13B 14B 15B 16B 17B 18B 19B 20B  
21B 22B 23B 24B 25B 26B 27B 28B 29B 30A  
31B 32A 33A 34A 35A 36B 37B 38B 39A 40A  
41B 42B 43B 44B 45B 46B 47B 48B 49B 50B  
51B 52B 53B 54B 55B 56B 57B 58B 59B 60B  

Missed architecture → `01–05`. Policy → `06–10`. Mesh → `11–14`. Hubble → `15–16`. Install → `17–18`. Mesh clusters → `19–20`. eBPF → `21–22`. BGP → `23–24`.
