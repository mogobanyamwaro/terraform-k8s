## Tasks

1. Check the current cluster version (`k get nodes`, `kubeadm version`)
2. Upgrade the control plane node:
   a. Update the kubeadm package to the target version
   b. Run `kubeadm upgrade plan` to see available upgrades
   c. Run `kubeadm upgrade apply v1.35.x`
   d. Upgrade kubelet and kubectl packages
   e. Restart kubelet
3. Upgrade a worker node:
   a. Drain the worker node
   b. Update kubeadm, kubelet, kubectl packages on the worker
   c. Run `kubeadm upgrade node`
   d. Restart kubelet
   e. Uncordon the worker
4. Verify all nodes show the new version

---

Here's the **best way** to tackle cluster upgrade on the CKA exam – this is a critical task that follows a specific order.

---

## Prerequisites – Check Current Version

**Check nodes:**

```bash
kubectl get nodes
```

**Check kubeadm version:**

```bash
kubeadm version
```

**Check kubelet version on control plane:**

```bash
kubelet --version
```

**Check available kubeadm versions:**

```bash
apt list -a kubeadm
```

---

## Part 2: Upgrade Control Plane Node

### 2a. Update kubeadm package to target version

**On Ubuntu/Debian (CKA exam uses Ubuntu):**

```bash
apt-get update
apt-get install --allow-change-held-packages kubeadm=1.35.0-00
```

**Hold the package to prevent auto-updates:**

```bash
apt-mark hold kubeadm
```

**Verify kubeadm version:**

```bash
kubeadm version
```

---

### 2b. Run `kubeadm upgrade plan` to see available upgrades

```bash
kubeadm upgrade plan
```

**Expected output:** Shows available versions and upgrade compatibility

---

### 2c. Run `kubeadm upgrade apply v1.35.x`

```bash
kubeadm upgrade apply v1.35.0
```

**Note:** Replace `v1.35.0` with the exact version shown in upgrade plan

**Wait for completion:** This drains the control plane temporarily

---

### 2d. Upgrade kubelet and kubectl packages

```bash
apt-get install --allow-change-held-packages kubelet=1.35.0-00 kubectl=1.35.0-00
```

**Hold these packages:**

```bash
apt-mark hold kubelet kubectl
```

---

### 2e. Restart kubelet

```bash
systemctl daemon-reload
systemctl restart kubelet
```

**Verify kubelet is running:**

```bash
systemctl status kubelet
```

**Verify control plane node shows new version:**

```bash
kubectl get nodes
```

---

## Part 3: Upgrade a Worker Node

### 3a. Drain the worker node

**First, list nodes and identify worker:**

```bash
kubectl get nodes
```

**Cordon and drain the worker node:**

```bash
kubectl drain <worker-node-name> --ignore-daemonsets --delete-emptydir-data
```

**Wait for drain to complete:**

```bash
kubectl get nodes
```

Expected: Worker node shows `SchedulingDisabled`

---

### 3b. Update kubeadm, kubelet, kubectl packages on the worker

**SSH to worker node (or use `kubectl exec` if available):**

```bash
# On the worker node
apt-get update
apt-get install --allow-change-held-packages kubeadm=1.35.0-00 kubelet=1.35.0-00 kubectl=1.35.0-00
```

**Hold packages:**

```bash
apt-mark hold kubeadm kubelet kubectl
```

---

### 3c. Run `kubeadm upgrade node`

```bash
kubeadm upgrade node
```

**Expected output:** "The node has been upgraded"

---

### 3d. Restart kubelet

```bash
systemctl daemon-reload
systemctl restart kubelet
```

**Verify kubelet is running:**

```bash
systemctl status kubelet
```

---

### 3e. Uncordon the worker

**From control plane:**

```bash
kubectl uncordon <worker-node-name>
```

**Verify node is schedulable:**

```bash
kubectl get nodes
```

Expected: No `SchedulingDisabled`

---

## Part 4: Verify All Nodes Show New Version

**Check all nodes:**

```bash
kubectl get nodes
```

**Expected output:** Both control plane and worker show `v1.35.x` in VERSION column

**Detailed node versions:**

```bash
kubectl get nodes -o wide
```

**Check kubelet version on each node:**

```bash
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.kubeletVersion}{"\n"}{end}'
```

**Verify cluster version:**

```bash
kubectl version --short
```

---

## Complete Upgrade Script (Exam Reference)

### Control Plane Node (Run as root or with sudo):

```bash
# Update kubeadm
apt-get update
apt-get install --allow-change-held-packages kubeadm=1.35.0-00
apt-mark hold kubeadm

# Plan and apply upgrade
kubeadm upgrade plan
kubeadm upgrade apply v1.35.0

# Update kubelet and kubectl
apt-get install --allow-change-held-packages kubelet=1.35.0-00 kubectl=1.35.0-00
apt-mark hold kubelet kubectl

# Restart kubelet
systemctl daemon-reload
systemctl restart kubelet
```

### Worker Node (Run on the worker):

```bash
# From control plane first
kubectl drain <worker-node> --ignore-daemonsets --delete-emptydir-data

# On worker node
apt-get update
apt-get install --allow-change-held-packages kubeadm=1.35.0-00 kubelet=1.35.0-00 kubectl=1.35.0-00
apt-mark hold kubeadm kubelet kubectl
kubeadm upgrade node
systemctl restart kubelet

# Back on control plane
kubectl uncordon <worker-node>
```

---

## Quick Verification Commands

```bash
echo "=== Node Versions ==="
kubectl get nodes

echo -e "\n=== Kubelet Versions per Node ==="
kubectl get nodes -o custom-columns=NAME:.metadata.name,KUBELET:.status.nodeInfo.kubeletVersion

echo -e "\n=== Kubeadm Version ==="
kubeadm version

echo -e "\n=== Kubelet Version (local) ==="
kubelet --version

echo -e "\n=== Kubectl Version ==="
kubectl version --client --short
```

---

## Exam Critical Notes

| Step                 | Command                     | Critical Detail              |
| -------------------- | --------------------------- | ---------------------------- |
| Check versions       | `kubectl get nodes`         | Note current version         |
| Update kubeadm first | `apt-get install kubeadm=X` | Must be first                |
| Upgrade plan         | `kubeadm upgrade plan`      | Always run before apply      |
| Apply upgrade        | `kubeadm upgrade apply`     | Control plane only           |
| Worker upgrade       | `kubeadm upgrade node`      | Worker node only             |
| Hold packages        | `apt-mark hold`             | Prevents accidental upgrades |
| Drain worker         | `--ignore-daemonsets`       | Required for DaemonSets      |
| Uncordon worker      | `kubectl uncordon`          | Bring back to service        |

---

## Common Exam Traps

| Trap                                            | Consequence                 | Fix                               |
| ----------------------------------------------- | --------------------------- | --------------------------------- |
| Upgrading kubelet before kubeadm                | Version mismatch            | Always upgrade kubeadm first      |
| Forgetting to drain worker                      | Pods disrupted              | Drain before worker upgrade       |
| Skipping `kubeadm upgrade plan`                 | Unknown upgrade path        | Always run plan first             |
| Not holding packages                            | Auto-upgrade breaks cluster | Hold after install                |
| Upgrading control plane and worker at same time | Cluster instability         | Control plane first, then workers |
| Forgetting to uncordon                          | Node stays unschedulable    | Uncordon after upgrade            |

---

## Version Numbers for CKA Exam

**Current CKA exam version (as of 2026):**

- Kubernetes: v1.35
- Check exact version with: `kubeadm version`

**Package naming convention:**

- Ubuntu/Debian: `kubeadm=1.35.0-00`
- RHEL/CentOS: `kubeadm-1.35.0-0`

---

## Pro Tips for CKA

1. **Always check current version first** – Know where you're starting from
2. **Run `kubeadm upgrade plan`** – Shows exact commands to use
3. **Control plane first** – Never upgrade workers first
4. **Drain before upgrading workers** – Prevents pod disruption
5. **Verify after each step** – Don't assume it worked
6. **Hold packages** – Exam expects this for production readiness
7. **One minor version at a time** – Can't skip versions (e.g., 1.33 → 1.35 requires 1.34 first)

---

## If Upgrade Fails (Exam Troubleshooting)

**Check package versions available:**

```bash
apt-cache policy kubeadm
```

**Check current kubeadm version:**

```bash
kubeadm version
```

**Check if node is cordoned:**

```bash
kubectl describe node <node-name> | grep Unschedulable
```

**Check kubelet logs:**

```bash
journalctl -u kubelet -f --since "5 minutes ago"
```

**Resume failed upgrade:**

```bash
kubeadm upgrade apply v1.35.0 --force
```

---

**Total exam time for this task:** ~8-10 minutes (upgrade is time-consuming)

**Most likely exam scenario:** Upgrade a single control plane node cluster (non-HA) and one worker node to the next minor version (e.g., 1.34 → 1.35)
