Create a high-priority pod that gets scheduled before lower-priority pods. Practice using `kubectl patch` to modify existing resources without editing manifests.

## Tasks

1. Create a namespace called `exercise-24`
2. Create a PriorityClass with:
   - Name: `high-priority`
   - Value: `999999` (one less than 1000000 — max priority)
   - Description: "Critical workload"
3. Create a Deployment named `critical-app`:
   - 1 replica initially
   - Image: `busybox:1.36`
   - Do NOT specify priorityClassName yet
4. Use `kubectl patch` to add `priorityClassName: high-priority` to the Deployment
5. Verify the pod has the priority class assigned
6. Create a second lower-priority Deployment to compare
7. Verify scheduling order respects priority

## Key Learning

- PriorityClass affects pod scheduling order
- Higher value = higher priority = schedules first
- `kubectl patch` is faster than editing files in exam
- Exam often asks: "Update this Deployment using only kubectl" → patch is the answer

---

Here's the **best way** to use `kubectl patch` to add priorityClassName to an existing Deployment on the CKA exam.

---

## 1. Create namespace

```bash
kubectl create namespace exercise-24
```

---

## 2. Create PriorityClass high-priority

```bash
cat <<EOF | kubectl apply -f -
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 999999
description: "Critical workload"
preemptionPolicy: PreemptLowerPriority
EOF
```

**Verify PriorityClass:**

```bash
kubectl get priorityclass high-priority
```

---

## 3. Create Deployment without priorityClassName initially

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-app
  namespace: exercise-24
spec:
  replicas: 1
  selector:
    matchLabels:
      app: critical-app
  template:
    metadata:
      labels:
        app: critical-app
    spec:
      containers:
      - name: busybox
        image: busybox:1.36
        command: ["sleep", "3600"]
EOF
```

**Verify pod is running without priority:**

```bash
kubectl get pods -n exercise-24
kubectl get pod -n exercise-24 -o json | jq '.items[0].spec.priorityClassName'
```

**Expected:** `null` (no priority class assigned)

---

## 4. Use kubectl patch to add priorityClassName to Deployment

**Method 1 – Strategic merge patch (recommended for exam):**

```bash
kubectl patch deployment critical-app -n exercise-24 --patch '
spec:
  template:
    spec:
      priorityClassName: high-priority
'
```

**Method 2 – JSON patch:**

```bash
kubectl patch deployment critical-app -n exercise-24 \
  --type json \
  --patch='[{"op": "add", "path": "/spec/template/spec/priorityClassName", "value": "high-priority"}]'
```

**Method 3 – Using `-p` with strategic merge (shorter):**

```bash
kubectl patch deployment critical-app -n exercise-24 -p '{"spec":{"template":{"spec":{"priorityClassName":"high-priority"}}}}'
```

**Watch the rollout (old pod gets replaced):**

```bash
kubectl rollout status deployment critical-app -n exercise-24
```

---

## 5. Verify the pod has the priority class assigned

**Check pod priority:**

```bash
kubectl get pods -n exercise-24 -o custom-columns=NAME:.metadata.name,PRIORITY-CLASS:.spec.priorityClassName,PRIORITY:.spec.priority
```

**Detailed verification:**

```bash
kubectl get pods -n exercise-24 -o json | jq '.items[] | {name: .metadata.name, priorityClassName: .spec.priorityClassName, priority: .spec.priority}'
```

**Check deployment has priorityClassName in template:**

```bash
kubectl get deployment critical-app -n exercise-24 -o yaml | grep -A2 priorityClassName
```

**Verify the priority value (should be 999999):**

```bash
kubectl get pods -n exercise-24 -o json | jq '.items[0].spec.priority'
```

---

## 6. Create a second lower-priority Deployment for comparison

**Create low-priority PriorityClass:**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 100
description: "Low priority workload"
preemptionPolicy: PreemptLowerPriority
EOF
```

**Create low-priority deployment:**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: low-priority-app
  namespace: exercise-24
spec:
  replicas: 1
  selector:
    matchLabels:
      app: low-priority-app
  template:
    metadata:
      labels:
        app: low-priority-app
    spec:
      priorityClassName: low-priority
      containers:
      - name: busybox
        image: busybox:1.36
        command: ["sleep", "3600"]
EOF
```

---

## 7. Verify scheduling order respects priority

**List both deployments' pods:**

```bash
kubectl get pods -n exercise-24 -o custom-columns=NAME:.metadata.name,PRIORITY-CLASS:.spec.priorityClassName,PRIORITY:.spec.priority,NODE:.spec.nodeName
```

**Expected output shows high-priority pod may have scheduled even if resources were tight**

**Check pod priority values side by side:**

```bash
echo "=== High Priority Pod ==="
kubectl get pod -n exercise-24 -l app=critical-app -o json | jq '{priority: .items[0].spec.priority, priorityClass: .items[0].spec.priorityClassName}'

echo -e "\n=== Low Priority Pod ==="
kubectl get pod -n exercise-24 -l app=low-priority-app -o json | jq '{priority: .items[0].spec.priority, priorityClass: .items[0].spec.priorityClassName}'
```

**Sort pods by priority (highest first):**

```bash
kubectl get pods -n exercise-24 -o json | jq '.items | sort_by(-.spec.priority) | .[] | {name: .metadata.name, priority: .spec.priority}'
```

---

## kubectl patch Cheat Sheet for Exam

### Patch Types

| Patch Type      | Flag                | Use Case                                  |
| --------------- | ------------------- | ----------------------------------------- |
| Strategic merge | `--patch` (default) | Add/modify fields in native K8s objects   |
| JSON patch      | `--type json`       | Precise operations (add, remove, replace) |
| Merge patch     | `--type merge`      | Replace entire object (risky)             |

### Common Patch Operations

**Add a label to pod template:**

```bash
kubectl patch deployment my-app -p '{"spec":{"template":{"metadata":{"labels":{"env":"prod"}}}}}'
```

**Add annotation:**

```bash
kubectl patch deployment my-app -p '{"spec":{"template":{"metadata":{"annotations":{"version":"v2"}}}}}'
```

**Change image:**

```bash
kubectl patch deployment my-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"my-container","image":"nginx:1.28"}]}}}}'
```

**Add environment variable:**

```bash
kubectl patch deployment my-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"my-container","env":[{"name":"DEBUG","value":"true"}]}]}}}}'
```

**Change replica count:**

```bash
kubectl patch deployment my-app -p '{"spec":{"replicas":5}}'
```

**Add nodeSelector:**

```bash
kubectl patch deployment my-app -p '{"spec":{"template":{"spec":{"nodeSelector":{"disktype":"ssd"}}}}}'
```

**Add toleration:**

```bash
kubectl patch deployment my-app -p '{"spec":{"template":{"spec":{"tolerations":[{"key":"dedicated","operator":"Equal","value":"special","effect":"NoSchedule"}]}}}}'
```

**Remove a field (JSON patch):**

```bash
kubectl patch deployment my-app --type json -p='[{"op": "remove", "path": "/spec/template/spec/priorityClassName"}]'
```

---

## Quick Verification Commands

```bash
echo "=== PriorityClasses ==="
kubectl get priorityclass

echo -e "\n=== Deployments ==="
kubectl get deployments -n exercise-24

echo -e "\n=== Pods with Priorities ==="
kubectl get pods -n exercise-24 -o custom-columns=NAME:.metadata.name,PRIORITY-CLASS:.spec.priorityClassName,PRIORITY:.spec.priority

echo -e "\n=== Pods Sorted by Priority ==="
kubectl get pods -n exercise-24 -o json | jq -r '.items | sort_by(-.spec.priority) | .[] | "\(.metadata.name): priority=\(.spec.priority)"'

echo -e "\n=== Deployment Patch Verification ==="
kubectl get deployment critical-app -n exercise-24 -o jsonpath='{.spec.template.spec.priorityClassName}'
echo ""
```

---

## Priority Value Comparison

| PriorityClass      | Value  | Schedules First |
| ------------------ | ------ | --------------- |
| high-priority      | 999999 | ✓ (highest)     |
| low-priority       | 100    | ✗               |
| default (no class) | 0      | ✗               |

---

## Common Exam Traps with kubectl patch

| Trap                                   | Consequence                   | Fix                                         |
| -------------------------------------- | ----------------------------- | ------------------------------------------- |
| Wrong path                             | Patch doesn't apply           | Use `spec.template.spec.priorityClassName`  |
| Missing container name                 | Multiple containers ambiguous | Specify `containers[0]` or name             |
| Using JSON patch without `--type json` | Wrong operation               | Add `--type json` for add/remove ops        |
| Forgetting rollout                     | Old pods unchanged            | Patch triggers rollout automatically        |
| YAML vs JSON format                    | Syntax error                  | Use double quotes for JSON, single for YAML |

---

## Pro Tips for kubectl patch on CKA

1. **Memorize the path structure** – `spec.template.spec.priorityClassName`
2. **Use strategic merge for simple adds** – Default patch type works
3. **Test with `--dry-run=client`** – Verify patch syntax
4. **Patch triggers rollout** – Pods will restart with new spec
5. **JSON patch for removal** – `{"op": "remove", "path": "..."}`
6. **Single quotes outside, double inside** – `-p '{"key":"value"}'`
7. **Watch rollout status** – `kubectl rollout status deployment`

---

## More Exam-Ready Patch Examples

### Add multiple things at once

```bash
kubectl patch deployment critical-app -n exercise-24 --patch '
spec:
  replicas: 3
  template:
    spec:
      priorityClassName: high-priority
      containers:
      - name: busybox
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
'
```

### Using JSON patch for precise control

```bash
# Replace the image
kubectl patch deployment critical-app -n exercise-24 \
  --type json \
  --patch='[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "nginx:1.28"}]'
```

### Add a new container (advanced)

```bash
kubectl patch deployment critical-app -n exercise-24 \
  --type json \
  --patch='[{"op": "add", "path": "/spec/template/spec/containers/-", "value": {"name": "sidecar", "image": "busybox:1.36", "command": ["sleep", "3600"]}}]'
```

---

## Clean Up

```bash
# Delete deployments
kubectl delete deployment critical-app low-priority-app -n exercise-24

# Delete priority classes
kubectl delete priorityclass high-priority low-priority

# Delete namespace
kubectl delete namespace exercise-24
```

---

**Total exam time for this task:** ~4-5 minutes

**Most likely exam scenario:** You have an existing Deployment and need to add a priorityClassName to it using ONLY kubectl commands (no editing files). This tests your ability to use `kubectl patch` efficiently.
