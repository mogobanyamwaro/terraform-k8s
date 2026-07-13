# Cluster Mesh Deep Dive

Separate kube-apiservers. Cilium syncs identities/endpoints via **clustermesh-apiserver**.

Must: unique **cluster-name**, **cluster-id 1–255**, **non-overlapping pod CIDRs**, node datapath reachability, compatible versions, mTLS between mesh APIs.

Global Service:

```yaml
annotations:
  service.cilium.io/global: "true"
```

Same name+namespace. `affinity: local` prefers local backends.

See `19.md`–`20.md`.
