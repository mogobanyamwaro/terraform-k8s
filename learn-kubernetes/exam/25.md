Create a StorageClass with `WaitForFirstConsumer` binding mode, and understand why PVCs remain Pending until a pod actually uses them.

## Tasks

1. Create a namespace called `exercise-25`
2. Create a StorageClass named `local-storage` with:
   - Provisioner: `kubernetes.io/no-provisioner` (local volumes)
   - Binding mode: `WaitForFirstConsumer`
3. Create a PersistentVolume (PV) with:
   - Name: `local-pv-1`
   - Size: 1Gi
   - AccessMode: ReadWriteOnce
   - StorageClassName: `local-storage`
   - Local path: `/tmp/k8s-pv` (or any valid node path)
4. Create a PersistentVolumeClaim (PVC) with:
   - Name: `local-pvc`
   - Size: 1Gi
   - StorageClassName: `local-storage`
5. Observe: PVC remains Pending (not Bound) — WHY?
6. Create a Pod that uses the PVC:
   - Image: `busybox:1.36`
   - Mount PVC at `/data`
7. Observe: Now PVC transitions to Bound
   - Pod schedules on the node where the PV exists
8. Verify data persistence by writing to the volume

## Key Learning

- `WaitForFirstConsumer` = PVC stays Pending until a pod needs it
- Binding is deferred to allow node affinity scheduling
- Useful for local storage where PV is tied to a specific node
- Exam tests understanding of binding modes and their tradeoffs

---

Here's the **best way** to tackle StorageClass with `WaitForFirstConsumer` binding mode on the CKA exam.

---

## Understanding WaitForFirstConsumer

| Binding Mode           | Behavior                      | Use Case                     |
| ---------------------- | ----------------------------- | ---------------------------- |
| `Immediate`            | PVC binds immediately to PV   | Network storage (NFS, EBS)   |
| `WaitForFirstConsumer` | PVC waits until pod scheduled | Local storage, zone-specific |

**Why WaitForFirstConsumer exists:**

- Local PVs are tied to specific nodes
- Scheduler needs pod to know which node to schedule on
- PVC binds to PV on the node where pod lands

---

## 1. Create namespace

```bash
kubectl create namespace exercise-25
```

---

## 2. Create StorageClass with WaitForFirstConsumer binding mode

```bash
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
```

**Verify StorageClass:**

```bash
kubectl get storageclass local-storage
```

**Check binding mode:**

```bash
kubectl get storageclass local-storage -o yaml | grep -A2 volumeBindingMode
```

---

## 3. Create PersistentVolume with local path

**First, create the local directory on the node (for single-node clusters):**

```bash
# On the node where pod will run (for minikube/single-node)
sudo mkdir -p /tmp/k8s-pv
sudo chmod 777 /tmp/k8s-pv
```

**Create the PV:**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv-1
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  local:
    path: /tmp/k8s-pv
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - $(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
EOF
```

**Note:** The nodeAffinity is required for local PVs to tell Kubernetes which node has the storage.

**For multi-node clusters, replace with actual node name:**

```bash
# Get node name
NODE_NAME=$(kubectl get nodes -o name | head -1 | cut -d'/' -f2)
echo "Using node: $NODE_NAME"

# Create PV with proper node affinity
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv-1
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /tmp/k8s-pv
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - $NODE_NAME
EOF
```

**Verify PV:**

```bash
kubectl get pv local-pv-1
```

**Expected status:** `Available`

---

## 4. Create PersistentVolumeClaim

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: local-pvc
  namespace: exercise-25
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: local-storage
EOF
```

---

## 5. Observe: PVC remains Pending

**Check PVC status:**

```bash
kubectl get pvc local-pvc -n exercise-25
```

**Expected:** `STATUS: Pending`

**Why?** The binding mode `WaitForFirstConsumer` delays binding until a pod uses this PVC.

**Check PVC details:**

```bash
kubectl describe pvc local-pvc -n exercise-25
```

**Notice the events:** No events about binding – it's waiting.

**Verify PVC is not bound:**

```bash
kubectl get pvc local-pvc -n exercise-25 -o yaml | grep -A5 status
```

**Check PV is still Available:**

```bash
kubectl get pv local-pv-1
```

**Expected:** `STATUS: Available` (not Bound)

---

## 6. Create Pod that uses the PVC

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: storage-tester
  namespace: exercise-25
spec:
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: local-pvc
  containers:
  - name: app
    image: busybox:1.36
    command: ["sleep", "3600"]
    volumeMounts:
    - name: storage
      mountPath: /data
EOF
```

---

## 7. Observe: PVC transitions to Bound

**Watch PVC status:**

```bash
kubectl get pvc local-pvc -n exercise-25 --watch
```

**Expected:** Changes from `Pending` to `Bound`

**Check PV status:**

```bash
kubectl get pv local-pv-1
```

**Expected:** `STATUS: Bound`

**Verify pod is running:**

```bash
kubectl get pod storage-tester -n exercise-25
```

**Check PVC binding details:**

```bash
kubectl describe pvc local-pvc -n exercise-25 | grep -A5 "Volume:"
```

**Check pod node placement:**

```bash
kubectl get pod storage-tester -n exercise-25 -o wide
```

**Expected:** Pod runs on the node where the PV's local storage exists

**Verify volume mount:**

```bash
kubectl describe pod storage-tester -n exercise-25 | grep -A5 "Mounts:"
```

---

## 8. Verify data persistence by writing to the volume

**Write test data:**

```bash
kubectl exec -n exercise-25 storage-tester -- sh -c "echo 'Persistent data' > /data/test.txt"
```

**Verify file was written:**

```bash
kubectl exec -n exercise-25 storage-tester -- cat /data/test.txt
```

**Delete the pod:**

```bash
kubectl delete pod storage-tester -n exercise-25
```

**Create new pod with same PVC:**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: storage-tester-new
  namespace: exercise-25
spec:
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: local-pvc
  containers:
  - name: app
    image: busybox:1.36
    command: ["sleep", "3600"]
    volumeMounts:
    - name: storage
      mountPath: /data
EOF
```

**Verify data persisted:**

```bash
kubectl exec -n exercise-25 storage-tester-new -- cat /data/test.txt
```

**Expected output:** `Persistent data`

---

## Quick Verification Commands

```bash
echo "=== StorageClass ==="
kubectl get storageclass local-storage

echo -e "\n=== PV Status (before pod binding) ==="
kubectl get pv local-pv-1

echo -e "\n=== PVC Status (before pod) ==="
kubectl get pvc local-pvc -n exercise-25
echo "Note: STATUS should be Pending until pod uses it"

echo -e "\n=== Pod ==="
kubectl get pod storage-tester -n exercise-25

echo -e "\n=== PVC Status (after pod) ==="
kubectl get pvc local-pvc -n exercise-25

echo -e "\n=== Bound PV ==="
kubectl get pv

echo -e "\n=== Pod Node Placement ==="
kubectl get pod storage-tester -n exercise-25 -o wide

echo -e "\n=== Data Persistence ==="
kubectl exec -n exercise-25 storage-tester-new -- cat /data/test.txt 2>/dev/null || echo "New pod not ready"
```

---

## WaitForFirstConsumer Behavior Diagram

```
1. Create StorageClass (WaitForFirstConsumer)
         ↓
2. Create PV (Available)
         ↓
3. Create PVC (Pending)
         ↓
   [PVC waits for consumer]
         ↓
4. Create Pod using PVC
         ↓
5. Scheduler selects node for Pod
         ↓
6. PVC binds to PV on that node
         ↓
7. Pod mounts volume and runs
```

---

## Binding Modes Comparison

| Aspect                 | Immediate              | WaitForFirstConsumer         |
| ---------------------- | ---------------------- | ---------------------------- |
| Binding timing         | As soon as PVC created | When pod scheduled           |
| Node awareness         | No                     | Yes (bind to node affinity)  |
| Use case               | Network storage        | Local storage, zone affinity |
| PV availability        | Must exist globally    | Can be node-specific         |
| Scheduling flexibility | Less                   | More (pods go to PV node)    |

---

## Local PV Requirements

**For local PVs, you MUST specify:**

```yaml
local:
  path: /tmp/k8s-pv
nodeAffinity:
  required:
    nodeSelectorTerms:
      - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
              - <specific-node-name>
```

**Without nodeAffinity, local PV won't bind correctly.**

---

## Common Exam Traps

| Trap                             | Consequence        | Fix                                          |
| -------------------------------- | ------------------ | -------------------------------------------- |
| No nodeAffinity                  | PV can't bind      | Add required nodeAffinity                    |
| Wrong provisioner                | StorageClass fails | Use `kubernetes.io/no-provisioner` for local |
| No directory on node             | Pod can't mount    | Create directory on node first               |
| Expecting immediate binding      | Confusion          | Remember WaitForFirstConsumer delays         |
| Deleting pod with no replacement | Data not tested    | Create new pod to verify persistence         |

---

## Pro Tips for CKA

1. **WaitForFirstConsumer is for local storage** – Network storage uses Immediate
2. **PVC stays Pending until pod created** – That's by design, not an error
3. **Check pod node placement** – Pod must run on node with the local PV
4. **Create directory on node first** – Otherwise volume mount fails
5. **nodeAffinity is required** – Tells scheduler which node has the storage
6. **Use `kubectl describe pvc`** – Shows waiting status
7. **Data persists across pod deletion** – PVC and PV retain data

---

## Troubleshooting

**PVC stuck in Pending even after pod created:**

```bash
# Check pod events
kubectl describe pod storage-tester -n exercise-25

# Check PVC events
kubectl describe pvc local-pvc -n exercise-25

# Check PV node affinity
kubectl get pv local-pv-1 -o yaml | grep -A10 nodeAffinity
```

**Pod stuck in Pending:**

```bash
# Check if pod can schedule on node with PV
kubectl describe pod storage-tester -n exercise-25 | grep -A5 "Events"
```

**Volume mount failed:**

```bash
# Check directory exists on node
ssh <node-name>
ls -la /tmp/k8s-pv
# Directory should exist and be writable
```

---

**Total exam time for this task:** ~6-8 minutes

**Most likely exam scenario:** PVC is stuck in Pending and you need to explain why (WaitForFirstConsumer). Then create a pod to trigger binding and verify data persistence. Local storage with delayed binding is a common CKA question.
