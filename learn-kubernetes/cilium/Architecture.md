# Architecture Deep Dive

**Agent (DaemonSet):** CNI, eBPF attach, identities on node, Hubble observer, health, kube-proxy replacement datapath.

**Operator (Deployment):** cluster-pool IPAM, identity GC, LB-IPAM, Cluster Mesh helpers, some CRDs.

**If agent dies on a node:** new pods fail CNI; existing BPF often still forwards.

**If operator dies:** packets still flow; IPAM/GC/mesh provisioning stall.

## IPAM

`cluster-pool` | `kubernetes` | `eni` | `azure` | `alibabacloud`

## Datapath

- Tunnel: VXLAN 8472 UDP, Geneve 6081 UDP
- Native: route pod CIDRs (BGP/cloud)
- Encryption: WireGuard **or** IPsec
- kube-proxy replacement: ClusterIP/NodePort/LB in eBPF; SNAT vs DSR vs Hybrid; Maglev; XDP

## Identities

Labels → numeric ID in maps. Reserved: `world`, `host`, `remote-node`, `health`, `init`, `kube-apiserver`, `ingress`.

See `01.md`–`05.md`.
