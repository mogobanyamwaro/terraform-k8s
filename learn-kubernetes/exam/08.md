Drain a worker node for maintenance, then bring it back. This tests your understanding of pod eviction, DaemonSets, and scheduling.

## Tasks

1. List all nodes and identify a worker node
2. Cordon the worker node (mark it unschedulable)
3. Verify the node shows `SchedulingDisabled`
4. Create a Deployment with 3 replicas and observe where pods are scheduled
5. Drain the worker node — handle DaemonSets and local data
6. Verify all non-DaemonSet pods have been evicted from the node
7. Uncordon the node
8. Scale the deployment to 6 replicas and verify pods get scheduled on the uncordoned node

---

Here's the **best way** to tackle node draining on the CKA exam – this is a critical operational task that appears frequently.

---

## 1. List all nodes and identify a worker node

```bash
kubectl get nodes
```

**Identify worker nodes** (not control-plane/master):

```bash
kubectl get nodes --show-labels | grep -v control-plane
```

**Get the exact worker node name:**

```bash
WORKER_NODE=$(kubectl get nodes -o name | grep -v control-plane | head -1 | cut -d'/' -f2)
echo $WORKER_NODE
```

---

## 2. Cordon the worker node (mark unschedulable)

```bash
kubectl cordon $WORKER_NODE
```

---

## 3. Verify node shows SchedulingDisabled

```bash
kubectl get nodes
```

**Expected output:** `STATUS` shows `SchedulingDisabled` under the worker node

**Detailed verification:**

```bash
kubectl describe node $WORKER_NODE | grep -i unschedulable
```

Expected: `Unschedulable: true`

---

## 4. Create Deployment with 3 replicas and observe scheduling

```bash
kubectl create deployment test-app --image=nginx:1.28 --replicas=3
```

**Observe where pods are scheduled (none should go to cordoned node):**

```bash
kubectl get pods -o wide
```

**Verify all pods are on other nodes:**

```bash
kubectl get pods -o wide | grep -v $WORKER_NODE
```

**Check for any pods pending due to cordon:**

```bash
kubectl get pods --field-selector status.phase=Pending
```

---

## 5. Drain the worker node

**First, check what pods are on the node:**

```bash
kubectl get pods --all-namespaces -o wide --field-selector spec.nodeName=$WORKER_NODE
```

**Drain command (standard exam approach):**

```bash
kubectl drain $WORKER_NODE --ignore-daemonsets --delete-emptydir-data
```

**Flag explanations:**

- `--ignore-daemonsets` - Keep DaemonSet pods (they'll re-create)
- `--delete-emptydir-data` - Remove pods with emptyDir volumes (safe for exam)

**If pods with local data block drain:**

```bash
kubectl drain $WORKER_NODE --ignore-daemonsets --delete-emptydir-data --force
```

**Watch drain progress:**

```bash
kubectl get pods --all-namespaces -o wide --watch
```

---

## 6. Verify all non-DaemonSet pods are evicted

**Check node for remaining pods:**

```bash
kubectl get pods --all-namespaces -o wide --field-selector spec.nodeName=$WORKER_NODE
```

**Should only show:**

- DaemonSet pods (if any)
- No regular pods (deployments, statefulsets, etc.)

**Verify node is still cordoned:**

```bash
kubectl get nodes
```

**Check drain status:**

```bash
kubectl describe node $WORKER_NODE | grep -A5 Conditions
```

**Verify pods were rescheduled elsewhere:**

```bash
kubectl get pods -o wide
```

---

## 7. Uncordon the node

```bash
kubectl uncordon $WORKER_NODE
```

**Verify node is schedulable again:**

```bash
kubectl get nodes
```

Expected: No `SchedulingDisabled` in STATUS

**Verify Unschedulable flag removed:**

```bash
kubectl describe node $WORKER_NODE | grep -i unschedulable
```

Expected: `Unschedulable: false` (or line not present)

---

## 8. Scale deployment to 6 replicas and verify scheduling on uncordoned node

**Scale the deployment:**

```bash
kubectl scale deployment test-app --replicas=6
```

**Watch new pods being created:**

```bash
kubectl get pods -o wide --watch
```

**Verify pods schedule on the uncordoned node:**

```bash
kubectl get pods -o wide | grep $WORKER_NODE
```

**Check distribution across nodes:**

```bash
kubectl get pods -o wide | awk '{print $7}' | sort | uniq -c
```

**Verify all 6 pods are running:**

```bash
kubectl get deployment test-app
```

---

## Quick Verification Commands (Run at end)

```bash
echo "=== Node Status ==="
kubectl get nodes

echo -e "\n=== Pod Distribution ==="
kubectl get pods -o wide

echo -e "\n=== Pods on Previously Drained Node ==="
kubectl get pods -o wide | grep $WORKER_NODE | wc -l

echo -e "\n=== Deployment Status ==="
kubectl get deployment test-app

echo -e "\n=== Pod Count per Node ==="
kubectl get pods -o wide | awk '{print $7}' | tail -n +2 | sort | uniq -c
```

---

## Exam Critical Notes

| Command            | Purpose                     | Critical Flags                                  |
| ------------------ | --------------------------- | ----------------------------------------------- |
| `kubectl cordon`   | Mark node unschedulable     | None needed                                     |
| `kubectl drain`    | Evict all pods              | `--ignore-daemonsets`, `--delete-emptydir-data` |
| `kubectl uncordon` | Make node schedulable again | None needed                                     |
| `kubectl scale`    | Increase replicas           | `--replicas=N`                                  |

---

## Common Exam Traps

| Trap                                | Consequence                   | Fix                      |
| ----------------------------------- | ----------------------------- | ------------------------ |
| Forgetting `--ignore-daemonsets`    | Drain fails                   | Always include this flag |
| Forgetting `--delete-emptydir-data` | Drain blocks on emptyDir pods | Include the flag         |
| Draining control-plane node         | Bad practice, may fail        | Only drain worker nodes  |
| Not verifying pods rescheduled      | Missing data loss check       | Check pod distribution   |
| Uncordoning before drain completes  | Pods schedule during drain    | Wait for drain finish    |

---

## Drain Blocked Scenarios (Exam Troubleshooting)

**Blocked by DaemonSet pods:**

```bash
kubectl drain $WORKER_NODE --ignore-daemonsets
```

**Blocked by pods with local storage:**

```bash
kubectl drain $WORKER_NODE --delete-emptydir-data
```

**Blocked by pods not managed by controller:**

```bash
kubectl drain $WORKER_NODE --force
```

**Combination for exam (use this):**

```bash
kubectl drain $WORKER_NODE --ignore-daemonsets --delete-emptydir-data
```

---

## Pro Tips for CKA

1. **Always cordon before drain** – Prevents new pods from scheduling
2. **Drain takes time** – Pods need time to terminate gracefully
3. **Check pod distribution after scaling** – Confirms node is schedulable
4. **DaemonSets ignored** – They're node-specific and will restart automatically
5. **EmptyDir data deleted** – Safe for exam scenarios, be careful in production

---

## Complete Exam Workflow

```bash
# Step 1-3: Cordon node
NODE=$(kubectl get nodes -o name | grep -v control-plane | head -1 | cut -d'/' -f2)
kubectl cordon $NODE
kubectl get nodes

# Step 4: Create deployment
kubectl create deployment test-app --image=nginx:1.28 --replicas=3

# Step 5-6: Drain node
kubectl drain $NODE --ignore-daemonsets --delete-emptydir-data
kubectl get pods --all-namespaces -o wide --field-selector spec.nodeName=$NODE

# Step 7: Uncordon
kubectl uncordon $NODE

# Step 8: Scale and verify
kubectl scale deployment test-app --replicas=6
kubectl get pods -o wide | grep $NODE
```

---

## Clean Up (For reference)

```bash
# Delete deployment
kubectl delete deployment test-app

# Uncordon if still cordoned
kubectl uncordon $WORKER_NODE
```

---

**Total exam time for this task:** ~5-7 minutes

**Most likely exam scenario:** A node needs maintenance. They'll ask you to drain it safely, then bring it back into service and verify workloads can schedule there again.
