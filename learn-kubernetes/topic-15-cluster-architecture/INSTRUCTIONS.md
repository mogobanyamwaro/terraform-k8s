# Topic 15: Cluster Architecture & Installation

## What You'll Learn

- **Control plane components** – kube-apiserver, etcd, kube-scheduler, kube-controller-manager
- **kubeadm** – init cluster, join nodes, upgrade
- **etcd** – backup and restore
- **Worker node** – kubelet, kube-proxy, container runtime
- **Cluster DNS** – CoreDNS, service discovery

## Steps

### 1. Inspect your cluster

```bash
kubectl get nodes -o wide
kubectl get componentstatuses   # Legacy; may show deprecated
kubectl get pods -n kube-system
```

### 2. Control plane components (static pods)

```bash
# Components run as static pods on control plane
kubectl get pods -n kube-system
kubectl get pods -n kube-system -o wide   # See node placement
# Look for: etcd-*, kube-apiserver-*, kube-scheduler-*, kube-controller-manager-*
```

### 3. kubeadm (kubeadm-based clusters only)

**Initialize control plane:**

```bash
kubeadm init --pod-network-cidr=10.244.0.0/16
# Or: kubeadm init --config kubeadm-config.yaml
```

**Join worker node:**

```bash
# On control plane: kubeadm token create --print-join-command
# On worker: run the output (kubeadm join ...)
```

**Upgrade cluster:**

```bash
# Upgrade control plane first
kubeadm upgrade plan
kubeadm upgrade apply v1.XX.X
# Drain node, upgrade kubelet, uncordon
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
apt-get update && apt-get install -y kubelet=1.XX.X-00 kubectl=1.XX.X-00
systemctl daemon-reload && systemctl restart kubelet
kubectl uncordon <node>
```

### 4. etcd backup & restore (kubeadm clusters)

**Backup:**

```bash
# Find etcd pod and cert paths
ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

**Restore:**

```bash
# Stop kube-apiserver, move existing etcd data, restore from snapshot, restart
# Full procedure: https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/
```

**microk8s:** Use `microk8s snapshot save` / `microk8s snapshot restore`. Exam expects etcdctl commands.

### 5. Cluster DNS

```bash
kubectl get svc -n kube-system   # kube-dns (CoreDNS)
kubectl run test-dns --image=busybox:1.36 --rm -it --restart=Never -- nslookup kubernetes.default
# Should resolve: kubernetes.default.svc.cluster.local
```

### 6. High availability (concept)

- Multiple control plane nodes
- Load balancer in front of kube-apiserver
- Stacked etcd (etcd on each control plane) or external etcd cluster

---

## Exam Tips

| Command                                                                        | Purpose                      |
| ------------------------------------------------------------------------------ | ---------------------------- |
| `kubeadm init`                                                                 | Initialize control plane     |
| `kubeadm join <master>:6443 --token X --discovery-token-ca-cert-hash sha256:Y` | Join worker                  |
| `kubeadm upgrade plan`                                                         | Plan upgrade                 |
| `kubeadm upgrade apply vX.Y.Z`                                                 | Upgrade control plane        |
| `etcdctl snapshot save`                                                        | Backup etcd                  |
| `etcdctl snapshot restore`                                                     | Restore etcd                 |
| `kubectl drain NODE`                                                           | Prepare node for maintenance |
| `kubectl uncordon NODE`                                                        | Mark node schedulable        |

**Control plane components:** kube-apiserver (API), etcd (state), kube-scheduler (scheduling), kube-controller-manager (controllers)

## Practice

1. Run `kubectl get pods -n kube-system` and identify control plane pods.
2. If using kubeadm: run `etcdctl snapshot save` to create a backup (use correct cert paths).
3. Run `kubectl run dns-test --image=busybox:1.36 --rm -it --restart=Never -- nslookup kubernetes` and verify DNS works.
