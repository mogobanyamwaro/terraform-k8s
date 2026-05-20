# Exercise 22 — PriorityClass

**Domain:** Workloads & Scheduling (15%)

**Difficulty:** Medium | **Time:** 15 min

---

## Context

PriorityClass defines the relative importance of pods. When nodes have limited resources, the scheduler prioritizes high-priority pods first. If a high-priority pod can't fit on any node, the scheduler can evict lower-priority pods to make room (preemption).

On the exam, you'll create PriorityClasses and assign them to pods. You need to know the difference between priority values, how preemption works, and how to debug which pods get scheduled when resources are tight.

---

## Tasks

1. Create a PriorityClass named `high-priority` with value 1000 and preemptionPolicy set to `PreemptLowerPriority`.

2. Create a PriorityClass named `low-priority` with value 10 and preemptionPolicy set to `Never`.

3. Create a Pod named `critical-app` using `nginx:1.28` and assign it to the `high-priority` class.

4. Create a Pod named `background-job` using `busybox:1.37` to run `sleep 3600` and assign it to the `low-priority` class.

5. Verify both pods are running. Check their priority values with `kubectl get pod -o json` and filter for `priority` and `priorityClassName`.

6. If possible, drain a node to trigger preemption and observe which pod gets evicted.

---

Here's the **best way** to tackle PriorityClass on the CKA exam – this tests scheduling priority and preemption behavior.

---

## Understanding PriorityClass

| Priority Value | Effect          | PreemptionPolicy                                       |
| -------------- | --------------- | ------------------------------------------------------ |
| Higher number  | Higher priority | `PreemptLowerPriority` – can evict lower-priority pods |
| Lower number   | Lower priority  | `Never` – never preempts others                        |

**Default system priorities:**

- `system-cluster-critical`: 2000000000
- `system-node-critical`: 2000001000

---

## 1. Create PriorityClass high-priority (value 1000, PreemptLowerPriority)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
preemptionPolicy: PreemptLowerPriority
globalDefault: false
description: "High priority for critical workloads"
EOF
```

**Verify creation:**

```bash
kubectl get priorityclass high-priority
```

**Check details:**

```bash
kubectl describe priorityclass high-priority
```

---

## 2. Create PriorityClass low-priority (value 10, Never)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 10
preemptionPolicy: Never
globalDefault: false
description: "Low priority for background jobs"
EOF
```

**Verify both PriorityClasses:**

```bash
kubectl get priorityclass
```

**Expected output:**

```
NAME                      VALUE        GLOBAL-DEFAULT   AGE
high-priority             1000         false            10s
low-priority              10           false            5s
system-cluster-critical   2000000000   false            <age>
system-node-critical      2000001000   false            <age>
```

---

## 3. Create Pod critical-app with high-priority class

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: critical-app
spec:
  priorityClassName: high-priority
  containers:
  - name: nginx
    image: nginx:1.28
EOF
```

**Verify pod creation:**

```bash
kubectl get pod critical-app
```

**Check priority assignment:**

```bash
kubectl get pod critical-app -o json | jq '{priority: .spec.priority, priorityClassName: .spec.priorityClassName}'
```

---

## 4. Create Pod background-job with low-priority class

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: background-job
spec:
  priorityClassName: low-priority
  containers:
  - name: busybox
    image: busybox:1.37
    command: ["sleep", "3600"]
EOF
```

**Verify pod creation:**

```bash
kubectl get pod background-job
```

**Check priority assignment:**

```bash
kubectl get pod background-job -o json | jq '{priority: .spec.priority, priorityClassName: .spec.priorityClassName}'
```

---

## 5. Verify both pods are running and check priority values

**List both pods:**

```bash
kubectl get pods
```

**Check priority values with custom columns:**

```bash
kubectl get pods -o custom-columns=NAME:.metadata.name,PRIORITY:.spec.priority,PRIORITY-CLASS:.spec.priorityClassName
```

**Expected output:**

```
NAME              PRIORITY   PRIORITY-CLASS
background-job    10         low-priority
critical-app      1000       high-priority
```

**Detailed JSON output:**

```bash
kubectl get pods -o json | jq '.items[] | {name: .metadata.name, priority: .spec.priority, priorityClassName: .spec.priorityClassName}'
```

**Check pod statuses:**

```bash
kubectl get pods -o wide
```

---

## 6. Trigger preemption (if possible in exam environment)

**Note:** Preemption requires resource pressure. In a typical exam environment, you may have enough resources that preemption doesn't trigger automatically.

### Method 1: Simulate resource pressure by scaling a deployment

```bash
# Create a high-priority pod that requires more resources
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: hungry-pod
spec:
  priorityClassName: high-priority
  containers:
  - name: stress
    image: polinux/stress
    command: ["stress"]
    args: ["--cpu", "2", "--vm", "1", "--vm-bytes", "512M", "--timeout", "300s"]
    resources:
      requests:
        memory: "512Mi"
        cpu: "1"
      limits:
        memory: "1Gi"
        cpu: "2"
EOF
```

### Method 2: Cordon and drain a node

**List nodes:**

```bash
kubectl get nodes
```

**Pick a worker node and cordon it:**

```bash
NODE=$(kubectl get nodes -o name | grep -v control-plane | head -1 | cut -d'/' -f2)
kubectl cordon $NODE
```

**Drain the node (this will evict pods):**

```bash
kubectl drain $NODE --ignore-daemonsets --delete-emptydir-data
```

**Observe which pods get evicted:**

```bash
kubectl get pods --watch
```

**Check preemption events:**

```bash
kubectl get events | grep -i preempt
```

**Check pod eviction details:**

```bash
kubectl describe pod background-job | grep -A5 "Events"
```

### Method 3: Create resource-intensive pods to fill nodes

**Create many low-priority pods:**

```bash
# Create 5 low-priority pods
for i in 1 2 3 4 5; do
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: filler-$i
spec:
  priorityClassName: low-priority
  containers:
  - name: busybox
    image: busybox:1.37
    command: ["sleep", "3600"]
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
EOF
done
```

**Then create a high-priority pod that needs significant resources:**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: preemptor-pod
spec:
  priorityClassName: high-priority
  containers:
  - name: nginx
    image: nginx:1.28
    resources:
      requests:
        memory: "512Mi"
        cpu: "500m"
EOF
```

**Observe preemption:**

```bash
kubectl get pods --watch
```

**After the experiment, uncordon the node:**

```bash
kubectl uncordon $NODE
```

---

## Quick Verification Commands

```bash
echo "=== PriorityClasses ==="
kubectl get priorityclass

echo -e "\n=== Pods with Priorities ==="
kubectl get pods -o custom-columns=NAME:.metadata.name,PRIORITY:.spec.priority,PRIORITY-CLASS:.spec.priorityClassName

echo -e "\n=== Pod Details ==="
for pod in critical-app background-job; do
  echo "--- $pod ---"
  kubectl get pod $pod -o json | jq '{priority: .spec.priority, priorityClassName: .spec.priorityClassName}'
done

echo -e "\n=== Preemption Events ==="
kubectl get events | grep -i preempt | tail -10

echo -e "\n=== Pod Statuses ==="
kubectl get pods
```

---

## PriorityClass Parameters

| Parameter          | Purpose                                      | Example                         |
| ------------------ | -------------------------------------------- | ------------------------------- |
| `value`            | Numerical priority (higher = more important) | `1000`                          |
| `preemptionPolicy` | Whether pod can evict others                 | `PreemptLowerPriority`, `Never` |
| `globalDefault`    | Default for pods without class               | `true`/`false`                  |
| `description`      | Human-readable info                          | `"Critical workload"`           |

---

## Preemption Policies Explained

| Policy                 | Behavior                      | Use Case                          |
| ---------------------- | ----------------------------- | --------------------------------- |
| `PreemptLowerPriority` | Can evict lower-priority pods | Critical workloads                |
| `Never`                | Never evicts any pods         | Background jobs, batch processing |

**Preemption workflow:**

```
1. High-priority pod scheduled
2. No resources available
3. Scheduler finds lower-priority pods
4. Evicts them (graceful termination)
5. Schedules high-priority pod
```

---

## Priority Values Reference

| Priority Class            | Typical Value | Use Case                     |
| ------------------------- | ------------- | ---------------------------- |
| `system-node-critical`    | 2000001000    | Critical system pods         |
| `system-cluster-critical` | 2000000000    | Cluster-critical components  |
| `high-priority`           | 1000          | Production workloads         |
| `default`                 | 0             | Regular workloads (implied)  |
| `low-priority`            | 10            | Batch jobs, background tasks |
| `best-effort`             | -10           | Non-critical workloads       |

---

## Setting Default PriorityClass

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: default-priority
value: 0
globalDefault: true
description: "Default priority for all pods"
```

**After setting globalDefault, pods without priorityClassName get this value.**

---

## Pods with Multiple PriorityClasses (Exam Trap)

**Pod can only have ONE priorityClass:**

```yaml
# WRONG – can't specify multiple
spec:
  priorityClassName: high-priority
  priorityClassName: low-priority  # This overrides the first
```

**Correct:**

```yaml
spec:
  priorityClassName: high-priority
```

---

## Debugging Priority and Preemption

**Check pod priority:**

```bash
kubectl get pod <pod-name> -o yaml | grep -E "priority:|priorityClassName:"
```

**Check scheduler events:**

```bash
kubectl get events --all-namespaces | grep -i "failed to schedule"
```

**Check node resources:**

```bash
kubectl describe node <node-name> | grep -A10 "Allocated resources"
```

**Check why pod is pending:**

```bash
kubectl describe pod <pod-name> | grep -A10 "Events"
```

**Common pending reason:** `0/3 nodes are available: 3 Insufficient cpu.`

---

## Exam Critical Notes

| Concept                | Key Point                                |
| ---------------------- | ---------------------------------------- |
| Priority value         | Higher number = higher priority          |
| Preemption             | Only happens when resources insufficient |
| `PreemptLowerPriority` | Pod can evict lower-priority pods        |
| `Never`                | Pod never evicts others                  |
| `globalDefault`        | Sets default for namespace               |
| System priorities      | Always higher than user priorities       |

---

## Common Exam Traps

| Trap                                  | Consequence                       | Fix                                    |
| ------------------------------------- | --------------------------------- | -------------------------------------- |
| Forgetting priorityClassName in pod   | Pod gets default (0) priority     | Always specify for critical workloads  |
| Misunderstanding preemption           | Expect eviction when resources OK | Preemption only happens under pressure |
| Using `PreemptNever` for critical pod | Can't schedule if no resources    | Use `PreemptLowerPriority`             |
| Setting value too low                 | Other pods get scheduled first    | Higher number = more priority          |
| No description field                  | Missing metadata                  | Add description for documentation      |

---

## Pro Tips for CKA

1. **Priority values are integers** – No decimal points
2. **System priorities are huge** – Don't try to override them
3. **Preemption is not guaranteed** – Only if lower-priority pods exist
4. **`globalDefault` only one per cluster** – Can't have multiple defaults
5. **Priority affects scheduling order** – Not runtime performance
6. **Deletion priority is opposite** – Lower priority deleted first
7. **Preemption is graceful** – Pods get termination notice (SIGTERM)

---

## Clean Up

```bash
# Delete pods
kubectl delete pod critical-app background-job

# Delete filler pods if created
kubectl delete pod filler-1 filler-2 filler-3 filler-4 filler-5 preemptor-pod hungry-pod --ignore-not-found

# Delete PriorityClasses
kubectl delete priorityclass high-priority low-priority

# Uncordon node if cordoned
kubectl uncordon $NODE 2>/dev/null || echo "Node not cordoned"
```

---

**Total exam time for this task:** ~5-7 minutes

**Most likely exam scenario:** Create PriorityClasses, assign them to pods, understand preemption behavior, or debug why a high-priority pod isn't scheduling (resources insufficient, need to evict lower pods).
