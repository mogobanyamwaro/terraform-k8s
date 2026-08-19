# Policy Deep Dive

**default mode:** no selecting policy → allow all. Selecting policy → default deny that direction.

**always / never:** always enforce / never enforce.

## CRDs

- `NetworkPolicy` — L3/L4 allow lists, implemented by Cilium
- `CiliumNetworkPolicy` — + L7, FQDN, entities, deny, services
- `CiliumClusterwideNetworkPolicy` — cluster/host

## Spec

`endpointSelector` subject. `ingress`/`egress`. Peers: endpoints, entities, CIDR, nodes, FQDN, services. `toPorts` L4 + `rules.http|kafka|dns`.

Cross-ns: `k8s:io.kubernetes.pod.namespace`.

FQDN: allow DNS to kube-dns + `toFQDNs`.

Deny rules beat allows.

NP + CNP both apply (intersection).

See `06.md`–`10.md`.
