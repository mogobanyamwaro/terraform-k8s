# Topic 14: Scheduling

## What You'll Learn

- **Taints & Tolerations** – restrict which pods can schedule on nodes
- **nodeSelector** – schedule pods on nodes with matching labels
- **Node Affinity** – requiredDuringScheduling / preferredDuringScheduling
- **Resource requests & limits** – CPU/memory for scheduling and limits
- `kubectl taint`, `kubectl describe node`

-Taint = Bug spray on a node saying "bugs not allowed here"
-Toleration = Bug repellent on a pod saying "this bug can handle the spray"
-nodeSelector - Analogy: "I only want to sit in window seats"
-Node Affinity 🎯 - Analogy: More sophisticated seat preferences
Two types:

-requiredDuringScheduling → "Must have" (hard requirement)

-preferredDuringScheduling → "Would like" (soft requirement)

## Steps

### 1. Inspect nodes

```bash
kubectl get nodes
kubectl describe node <node-name>   # See labels, taints, capacity
```

### 2. Taints & Tolerations

```bash
# Taint a node (prevents pods without matching toleration)
kubectl taint nodes <node-name> key=value:NoSchedule

# Remove taint
kubectl taint nodes <node-name> key=value:NoSchedule-

# Apply pod with toleration
kubectl apply -f pod-tolerations.yaml
```

**Note:** On single-node clusters (minikube, microk8s), tainting the node will prevent new pods from scheduling. Remove the taint when done: `kubectl taint nodes <node-name> key=value:NoSchedule-`

### 3. nodeSelector

```bash
# Label a node first
kubectl label nodes <node-name> disk=ssd

# Apply pod with nodeSelector
kubectl apply -f pod-node-selector.yaml
```

### 4. Node Affinity

```bash
kubectl apply -f pod-affinity.yaml
kubectl get pods -o wide
```

### 5. Resource requests & limits

```bash
kubectl apply -f pod-resources.yaml
kubectl describe pod resource-pod
```

### 6. Clean up

```bash
kubectl delete -f .
kubectl taint nodes <node-name> key=value:NoSchedule-   # Remove taint if added
```

---

## Exam Tips

| Command                                          | Purpose                      |
| ------------------------------------------------ | ---------------------------- |
| `kubectl taint nodes NODE key=value:NoSchedule`  | Add taint                    |
| `kubectl taint nodes NODE key=value:NoSchedule-` | Remove taint                 |
| `kubectl label nodes NODE disk=ssd`              | Label node for nodeSelector  |
| `kubectl describe node NODE`                     | See taints, labels, capacity |

**Taint effects:** NoSchedule (won't schedule), PreferNoSchedule (avoid), NoExecute (evict)

**Common affinity operators:** In, NotIn, Exists, DoesNotExist, Gt, Lt

## Practice

1. Add taint `workload=special:NoSchedule` to a node.
2. Create a pod with a toleration for that taint.
3. Create a pod with `nodeSelector: disk=ssd` (label a node first).
4. Create a pod with `resources.requests.memory: "128Mi"` and `resources.limits.memory: "256Mi"`.

# Add a taint to a node

kubectl taint nodes node1 app=blue:NoSchedule

# **Kubernetes Scheduling & Node Management Explained**

Let me break down each concept with simple analogies and real examples.

---

## **1. Taints & Tolerations** 🚫

**Analogy**: Bug spray vs. bug repellent

- **Taint** = Bug spray on a node saying "bugs not allowed here"
- **Toleration** = Bug repellent on a pod saying "this bug can handle the spray"

### **How Taints Work**

```bash
# Add a taint to a node
kubectl taint nodes node1 app=blue:NoSchedule

# Format: key=value:effect
# Effects:
# - NoSchedule     → Don't schedule new pods (existing pods stay)
# - PreferNoSchedule → Try to avoid, but not guaranteed
# - NoExecute      → Evict existing pods that don't tolerate
```

**Example YAML:**

```yaml
# Taint the node
kubectl taint nodes special-node dedicated=gpu:NoSchedule

# Pod that can schedule on it
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
spec:
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "gpu"
    effect: "NoSchedule"
  containers:
  - name: gpu-container
    image: nvidia/cuda
```

**Real scenario:**

```bash
# Dedicated GPU nodes only for ML workloads
kubectl taint nodes gpu-node-1 gpu=true:NoSchedule

# Regular app pods CAN'T schedule here
# ML pods WITH toleration CAN schedule here
```

---

## **2. nodeSelector** 🏷️

**Analogy**: "I only want to sit in window seats"

**Simplest form of node selection** - exact match only.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  nodeSelector:
    disktype: ssd # Must match EXACTLY
  containers:
    - name: nginx
      image: nginx
```

**Setup:**

```bash
# Label the node first
kubectl label nodes node1 disktype=ssd

# Now pods with nodeSelector: disktype=ssd will land here
```

**Limitations:**

- ❌ No "or" conditions (disktype=ssd OR disktype=nvme)
- ❌ No "not" conditions
- ❌ No soft requirements ("prefer SSD but HDD is OK")

---

## **3. Node Affinity** 🎯

**Analogy**: More sophisticated seat preferences

**Two types:**

1. **requiredDuringScheduling** → "Must have" (hard requirement)
2. **preferredDuringScheduling** → "Would like" (soft requirement)

### **Hard Requirement (requiredDuringScheduling)**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: topology.kubernetes.io/zone
                operator: In
                values:
                  - us-east-1a
                  - us-east-1b # Can be in either zone
  containers:
    - name: nginx
      image: nginx
```

### **Soft Requirement (preferredDuringScheduling)**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          preference:
            matchExpressions:
              - key: disktype
                operator: In
                values:
                  - ssd
        - weight: 50
          preference:
            matchExpressions:
              - key: cpu
                operator: In
                values:
                  - high-performance
  containers:
    - name: nginx
      image: nginx
```

Higher weight = more preferred (0-100)

### **Node Affinity Operators:**

- `In` - value in list
- `NotIn` - value not in list
- `Exists` - key exists (any value)
- `DoesNotExist` - key doesn't exist
- `Gt` - greater than
- `Lt` - less than

---

## **4. Resource Requests & Limits** ⚖️

**Analogy**: Airline baggage allowance

- **Request** = "I need at least this much" (guaranteed)
- **Limit** = "I can't use more than this" (capped)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-demo
spec:
  containers:
    - name: app
      image: nginx
      resources:
        requests:
          memory: "64Mi"
          cpu: "250m" # 1/4 of a CPU core
        limits:
          memory: "128Mi"
          cpu: "500m" # 1/2 of a CPU core
```

### **How Scheduling Uses Requests:**

```bash
# Node with 4 CPU cores, 8GB RAM
# Scheduler looks at ALLOCATABLE resources

# If node has:
# - 3 pods already using 2.5 CPU cores
# - New pod requests 0.5 CPU cores
# Total would be 3.0 CPU → Node can take it ✅

# If total would be 4.5 CPU → Node can't take it ❌
```

### **CPU Units Explained:**

- `1` = 1 full CPU core
- `0.5` or `500m` = half a core
- `100m` = 1/10 of a core
- `1` core = 1000 millicores

### **Memory Units:**

- `256Mi` = 256 Mebibytes (2^20 bytes)
- `1Gi` = 1 Gibibyte
- `512M` = 500 Megabytes (10^6 bytes)

---

## **5. Useful Commands** 💻

```bash
# Check node taints
kubectl describe node node1 | grep -i taint

# Check node labels
kubectl get nodes --show-labels
kubectl describe node node1 | grep Labels

# Check node resources
kubectl describe node node1 | grep -A5 "Capacity"
kubectl describe node node1 | grep -A10 "Allocated resources"

# Add/remove taints
kubectl taint nodes node1 key=value:NoSchedule
kubectl taint nodes node1 key:NoSchedule-  # Remove (trailing -)

# Add/remove labels
kubectl label nodes node1 disktype=ssd
kubectl label nodes node1 disktype-  # Remove
```

---

## **How They Work Together** 🎭

**Real-world scenario: Hybrid cluster with GPU and normal nodes**

```bash
# 1. Taint GPU nodes so only GPU workloads go there
kubectl taint nodes gpu-node gpu=true:NoSchedule

# 2. Label GPU nodes for affinity
kubectl label nodes gpu-node node-type=gpu

# 3. GPU pod that tolerates taint and requests resources
apiVersion: v1
kind: Pod
metadata:
  name: gpu-training
spec:
  tolerations:
  - key: "gpu"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: node-type
            operator: In
            values:
            - gpu
  containers:
  - name: cuda-container
    image: nvidia/cuda
    resources:
      requests:
        cpu: "2"
        memory: "4Gi"
        nvidia.com/gpu: 1    # GPU resource
      limits:
        cpu: "4"
        memory: "8Gi"
        nvidia.com/gpu: 1
```

---

## **Quick Decision Guide** 🤔

| Need                                | Solution                 |
| ----------------------------------- | ------------------------ |
| Dedicated nodes (only certain pods) | **Taints + Tolerations** |
| Simple label matching               | **nodeSelector**         |
| Complex label rules (AND/OR/NOT)    | **Node Affinity**        |
| Guarantee minimum resources         | **Requests**             |
| Prevent resource starvation         | **Limits**               |
| Both dedicated AND complex rules    | **Taints + Affinity**    |

**Pro tip**: Always set both requests AND limits. Requests for scheduling, limits for stability!
