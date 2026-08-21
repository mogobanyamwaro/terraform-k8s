Debug and fix a Deployment where pods won't schedule due to insufficient resource requests. Learn to calculate proper requests based on node capacity.

## Tasks

1. Create a namespace called `exercise-23`
2. Create a Deployment with:
   - 3 replicas
   - Image: `nginx:1.27`
   - Resource requests: 512Mi memory, 500m CPU (intentionally too high)
   - Cluster has 2 nodes with limited resources
3. Observe pods pending — they won't schedule
4. Check node capacity and available resources
5. Calculate correct resource requests to fit 3 replicas
6. Update Deployment with new (lower) requests
7. Verify all 3 pods schedule and run
8. Document the calculation

## Key Learning

The exam trick: **Do NOT use fixed rules like "10% overhead"** — calculate based on actual node allocatable resources and what's already running.

Formula:

```
Per-pod request = (Node Allocatable - System Reserved - Already Running) / Number of Replicas
Add buffer of 5-10%
```

---

Here's the **best way** to debug scheduling failures due to insufficient resource requests on the CKA exam.

---

## 1. Create namespace

```bash
kubectl create namespace exercise-23
```

---

## 2. Create Deployment with intentionally high resource requests

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: greedy-app
  namespace: exercise-23
spec:
  replicas: 3
  selector:
    matchLabels:
      app: greedy-app
  template:
    metadata:
      labels:
        app: greedy-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.27
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
EOF
```

---

## 3. Observe pods pending – they won't schedule

**Check deployment status:**

```bash
kubectl get deployment -n exercise-23
```

**Check pods:**

```bash
kubectl get pods -n exercise-23
```

**Expected:** Pods show `Pending` status

**Check why pods are pending:**

```bash
kubectl describe pods -n exercise-23 | grep -A5 "Events:"
```

**Common pending reason:** `0/2 nodes are available: 2 Insufficient memory, 2 Insufficient cpu.`

**List pending pods with details:**

```bash
kubectl get pods -n exercise-23 -o wide
```

---

## 4. Check node capacity and available resources

**List all nodes:**

```bash
kubectl get nodes
```

**Check node capacity and allocatable:**

```bash
kubectl describe nodes | grep -E "Name:|Capacity:|Allocatable:|cpu:|memory:" -A1
```

**Better – use custom columns:**

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU-CAP:.status.capacity.cpu,MEM-CAP:.status.capacity.memory,CPU-ALLOC:.status.allocatable.cpu,MEM-ALLOC:.status.allocatable.memory
```

**Check currently allocated resources:**

```bash
kubectl top nodes
```

**If metrics-server not available, check pod resource usage:**

```bash
kubectl describe nodes | grep -A5 "Non-terminated Pods"
```

**Get detailed node allocatable:**

```bash
for node in $(kubectl get nodes -o name | cut -d'/' -f2); do
  echo "=== Node: $node ==="
  kubectl get node $node -o json | jq '{name: .metadata.name, allocatable: .status.allocatable}'
done
```

**Check how many pods currently running:**

```bash
kubectl get pods --all-namespaces --field-selector=status.phase=Running | wc -l
```

---

## 5. Calculate correct resource requests to fit 3 replicas

### Step-by-step calculation:

**Assume example node configuration (exam environment):**

- Node allocatable: 1 CPU (1000m), 1GB memory (1024Mi)
- System overhead: ~200m CPU, 256Mi memory (kube-system pods)
- Available for new pods: 800m CPU, 768Mi memory
- Need to fit 3 replicas

**Calculation formula:**

```
Per-pod CPU = Available CPU / Replicas = 800m / 3 = 266m
Per-pod Memory = Available Memory / Replicas = 768Mi / 3 = 256Mi

Add 10% buffer:
CPU = 240m (round down for safety)
Memory = 230Mi
```

**Alternative – examine actual node state:**

```bash
# Get allocatable resources from node
NODE=$(kubectl get nodes -o name | head -1 | cut -d'/' -f2)
ALLOC_CPU=$(kubectl get node $NODE -o jsonpath='{.status.allocatable.cpu}')
ALLOC_MEM=$(kubectl get node $NODE -o jsonpath='{.status.allocatable.memory}')
echo "Allocatable CPU: $ALLOC_CPU, Memory: $ALLOC_MEM"
```

**Count existing pods on node:**

```bash
kubectl get pods --all-namespaces --field-selector spec.nodeName=$NODE,status.phase=Running
```

**Calculate safe resource requests (exam-safe approach):**

```bash
# For typical CKA exam cluster (2 nodes with ~2 cores, 2GB each)
# Safe values that always work:
PER_POD_CPU="100m"
PER_POD_MEM="128Mi"

# Or use this formula in your head:
# If node has X allocatable CPUs, leave 30% for system, divide by replicas
```

**Recommended resource requests for exam (conservative but works):**

- CPU: `100m` per replica
- Memory: `128Mi` per replica

---

## 6. Update Deployment with new (lower) requests

**Method 1 – Using kubectl patch:**

```bash
kubectl patch deployment greedy-app -n exercise-23 --patch '
spec:
  template:
    spec:
      containers:
      - name: nginx
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
'
```

**Method 2 – Using kubectl edit:**

```bash
kubectl edit deployment greedy-app -n exercise-23
# Change resources.requests.cpu to "100m"
# Change resources.requests.memory to "128Mi"
```

**Method 3 – Using kubectl set resources:**

```bash
kubectl set resources deployment greedy-app -n exercise-23 \
  --requests=cpu=100m,memory=128Mi
```

**Watch rollout:**

```bash
kubectl rollout status deployment greedy-app -n exercise-23
```

---

## 7. Verify all 3 pods schedule and run

**Check pods are now running:**

```bash
kubectl get pods -n exercise-23
```

**Expected:** All 3 pods show `Running` status

**Check deployment status:**

```bash
kubectl get deployment greedy-app -n exercise-23
```

**Verify resource requests on running pods:**

```bash
kubectl get pods -n exercise-23 -o json | jq '.items[] | {name: .metadata.name, requests: .spec.containers[0].resources.requests}'
```

**Check pod distribution across nodes:**

```bash
kubectl get pods -n exercise-23 -o wide
```

**Verify no pending pods:**

```bash
kubectl get pods -n exercise-23 --field-selector=status.phase=Pending
```

---

## 8. Document the calculation

**Create documentation:**

```bash
cat <<EOF > /tmp/resource-calculation.md
# Resource Calculation for exercise-23

## Initial Problem
- Deployment requested: 512Mi memory, 500m CPU per pod
- 3 replicas = 1.5GB memory, 1.5 CPU total
- Cluster nodes insufficient capacity

## Node Analysis
\`\`\`
$(kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU-ALLOC:.status.allocatable.cpu,MEM-ALLOC:.status.allocatable.memory)
\`\`\`

## Resource Calculation Formula
Per-pod request = (Node Allocatable - System Reserved) / Number of Replicas + Buffer

## Calculated Values
- CPU per pod: 100m (0.1 core)
- Memory per pod: 128Mi
- Total for 3 replicas: 300m CPU, 384Mi memory

## Result
All 3 pods scheduled successfully.
EOF

cat /tmp/resource-calculation.md
```

---

## Quick Verification Commands

```bash
echo "=== Deployment Status ==="
kubectl get deployment greedy-app -n exercise-23

echo -e "\n=== Pods ==="
kubectl get pods -n exercise-23 -o wide

echo -e "\n=== Resource Requests ==="
kubectl get pods -n exercise-23 -o json | jq '.items[0].spec.containers[0].resources.requests'

echo -e "\n=== Node Resources ==="
kubectl top nodes 2>/dev/null || echo "metrics-server not available"

echo -e "\n=== Node Allocatable ==="
kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU-ALLOC:.status.allocatable.cpu,MEM-ALLOC:.status.allocatable.memory

echo -e "\n=== Pod Distribution ==="
kubectl get pods -n exercise-23 -o wide | awk '{print $7}' | tail -n +2 | sort | uniq -c
```

---

## Resource Calculation Cheat Sheet

### Understanding Node Resources

| Resource    | Command                    | What it shows              |
| ----------- | -------------------------- | -------------------------- |
| Capacity    | `kubectl get node -o yaml` | Physical node resources    |
| Allocatable | Same as above              | Capacity - system reserved |
| Requests    | `kubectl describe node`    | Allocated to running pods  |
| Limits      | Same as above              | Maximum allowed            |

### Simple Exam Formula

```
Node Allocatable = Capacity - System Reserve
Available = Allocatable - Already Requested
Per-pod = Available / Desired Replicas - Buffer
```

**Typical exam cluster values:**

- 2 nodes, 2 CPU each, 4GB RAM each
- System uses ~500m CPU, 1GB RAM per node
- Leaves ~1.5 CPU, 3GB per node for workloads

**Safe generic values that always work:**

- CPU: `100m` per replica
- Memory: `128Mi` per replica

---

## Common Exam Traps

| Trap                     | Consequence                    | Fix                             |
| ------------------------ | ------------------------------ | ------------------------------- |
| Using limits as requests | Over-requesting resources      | Requests matter for scheduling  |
| No buffer                | Pods may fail after scheduling | Add 5-10% buffer                |
| Ignoring existing pods   | Calculation off                | Check `kubectl describe node`   |
| Setting CPU too low      | Pod throttled                  | At least 50m-100m per container |
| Memory without CPU       | CPU starvation                 | Always set both                 |
| Same value for all pods  | Wasted resources               | Calculate per workload          |

---

## Scheduling Algorithm Summary

```
For each pod:
  1. Filter nodes that have enough resources
  2. Score remaining nodes (priority)
  3. Pick highest scoring node

Pod resource = sum(container.resources.requests[cpu|memory])
Node availability = Node.Allocatable - sum(pod.resources.requests)
```

---

## Pro Tips for CKA

1. **Requests matter for scheduling** – Limits don't affect placement
2. **Check allocatable, not capacity** – System reserves some resources
3. **CPU is compressible** – Pods can burst to limits
4. **Memory is incompressible** – Exceeding memory = OOM kill
5. **Use `kubectl describe node`** – Shows allocated vs allocatable
6. **Start low, scale up** – Begin with minimal requests
7. **Consider pod overhead** – About 50m CPU, 100Mi per pod

---

## Troubleshooting Still Pending

**If pods still pending after lowering requests:**

```bash
# Check exact reason
kubectl describe pod <pending-pod-name> -n exercise-23 | grep -A10 "Events:"

# Check node allocatable again
kubectl describe nodes | grep -A3 "Allocated resources"

# Check for node selectors/affinity
kubectl get deployment greedy-app -n exercise-23 -o yaml | grep -A10 affinity

# Check for taints
kubectl describe nodes | grep -A5 Taints
```

**Common pending reasons:**

- `Insufficient cpu` – Still too high, reduce further
- `Insufficient memory` – Same
- `0/2 nodes are available` – NodeSelector or taints

---

**Total exam time for this task:** ~6-8 minutes

**Most likely exam scenario:** Deployment stuck in Pending with `Insufficient memory/cpu`. Need to check node allocatable, calculate correct resource requests, patch deployment, and verify scheduling.
