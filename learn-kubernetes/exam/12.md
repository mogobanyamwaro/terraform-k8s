Create PersistentVolumes, PersistentVolumeClaims, and mount them into pods. This covers static provisioning and StorageClass basics.

## Tasks

1. Create a namespace called `exercise-12`
2. Create a PersistentVolume named `my-pv` with:
   - Capacity: 1Gi
   - AccessMode: ReadWriteOnce
   - StorageClass: `manual`
   - hostPath: `/data/exercise-12`
   - Reclaim policy: Retain
3. Create a PersistentVolumeClaim named `my-pvc` in namespace `exercise-12`:
   - Request: 500Mi
   - AccessMode: ReadWriteOnce
   - StorageClass: `manual`
4. Verify the PVC is Bound to the PV
5. Create a pod named `storage-pod` that mounts `my-pvc` at `/usr/share/nginx/html`
6. Write a file inside the mounted volume
7. Delete the pod, create a new pod with the same PVC, and verify the file persists
8. Delete the PVC and check what happens to the PV (should be Released, not Available, because policy is Retain)

---

Here's the **best way** to tackle PersistentVolumes and PersistentVolumeClaims on the CKA exam – this tests static provisioning and volume lifecycle.

---

## 1. Create namespace

```bash
kubectl create namespace exercise-12
```

---

## 2. Create PersistentVolume named my-pv

**Create the PV:**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  hostPath:
    path: /data/exercise-12
  persistentVolumeReclaimPolicy: Retain
EOF
```

**Verify PV creation:**

```bash
kubectl get pv my-pv
```

**Check PV details:**

```bash
kubectl describe pv my-pv
```

**Create the hostPath directory on the node (if using a single-node cluster like Kind or minikube):**

```bash
# On the node where pod will run (for single-node clusters)
sudo mkdir -p /data/exercise-12
sudo chmod 755 /data/exercise-12
```

**Note for multi-node clusters:** hostPath PVs only work on the node where the pod schedules. For exam, usually single-node.

---

## 3. Create PersistentVolumeClaim in namespace exercise-12

**Create the PVC:**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
  namespace: exercise-12
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
  storageClassName: manual
EOF
```

**Verify PVC creation:**

```bash
kubectl get pvc my-pvc -n exercise-12
```

---

## 4. Verify PVC is Bound to PV

**Check binding status:**

```bash
kubectl get pv my-pv
kubectl get pvc my-pvc -n exercise-12
```

**Expected:** Both show `STATUS: Bound`

**Check which PV the PVC bound to:**

```bash
kubectl get pvc my-pvc -n exercise-12 -o jsonpath='{.spec.volumeName}'
```

**Detailed verification:**

```bash
kubectl describe pvc my-pvc -n exercise-12 | grep -A5 "Volume:"
```

**Check PV claim reference:**

```bash
kubectl describe pv my-pv | grep -A5 "Claim:"
```

---

## 5. Create pod that mounts my-pvc at /usr/share/nginx/html

**Create the pod:**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: storage-pod
  namespace: exercise-12
spec:
  volumes:
  - name: storage-volume
    persistentVolumeClaim:
      claimName: my-pvc
  containers:
  - name: nginx
    image: nginx:1.27
    volumeMounts:
    - name: storage-volume
      mountPath: /usr/share/nginx/html
    ports:
    - containerPort: 80
EOF
```

**Verify pod is running:**

```bash
kubectl get pod storage-pod -n exercise-12
```

**Wait for pod to be Ready:**

```bash
kubectl wait --for=condition=Ready pod/storage-pod -n exercise-12 --timeout=60s
```

**Check volume mount:**

```bash
kubectl describe pod storage-pod -n exercise-12 | grep -A5 "Mounts:"
```

---

## 6. Write a file inside the mounted volume

**Write test file:**

```bash
kubectl exec -n exercise-12 storage-pod -- sh -c "echo 'Persistent data test' > /usr/share/nginx/html/test.txt"
```

**Verify file was written:**

```bash
kubectl exec -n exercise-12 storage-pod -- cat /usr/share/nginx/html/test.txt
```

**Expected output:** `Persistent data test`

**Additional verification - create multiple files:**

```bash
kubectl exec -n exercise-12 storage-pod -- sh -c "date > /usr/share/nginx/html/timestamp.txt"
kubectl exec -n exercise-12 storage-pod -- ls -la /usr/share/nginx/html/
```

---

## 7. Delete pod, create new pod with same PVC, verify file persists

**Delete the pod:**

```bash
kubectl delete pod storage-pod -n exercise-12
```

**Verify PVC still exists:**

```bash
kubectl get pvc my-pvc -n exercise-12
```

**Create new pod with same PVC:**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: storage-pod-new
  namespace: exercise-12
spec:
  volumes:
  - name: storage-volume
    persistentVolumeClaim:
      claimName: my-pvc
  containers:
  - name: nginx
    image: nginx:1.27
    volumeMounts:
    - name: storage-volume
      mountPath: /usr/share/nginx/html
EOF
```

**Wait for new pod to be Ready:**

```bash
kubectl wait --for=condition=Ready pod/storage-pod-new -n exercise-12 --timeout=60s
```

**Verify file persisted:**

```bash
kubectl exec -n exercise-12 storage-pod-new -- cat /usr/share/nginx/html/test.txt
```

**Expected output:** `Persistent data test` (file survived pod deletion)

**Verify timestamp file also persists:**

```bash
kubectl exec -n exercise-12 storage-pod-new -- cat /usr/share/nginx/html/timestamp.txt
```

---

## 8. Delete PVC and check PV status (should be Released)

**Delete the PVC:**

```bash
kubectl delete pvc my-pvc -n exercise-12
```

**Check PV status:**

```bash
kubectl get pv my-pv
```

**Expected output:** `STATUS: Released` (not Available)

**Detailed PV status:**

```bash
kubectl describe pv my-pv | grep -A3 "Status:"
```

**Explanation:** Because `persistentVolumeReclaimPolicy: Retain`, the PV is not automatically reclaimed for new claims

**Check PV reclaim policy:**

```bash
kubectl get pv my-pv -o jsonpath='{.spec.persistentVolumeReclaimPolicy}'
```

**Verify PV still has claim reference (now orphaned):**

```bash
kubectl describe pv my-pv | grep -A5 "Claim:"
```

**Clean up PV if needed (manual):**

```bash
kubectl delete pv my-pv
```

---

## Quick Verification Commands (Run at end)

```bash
echo "=== PersistentVolumes ==="
kubectl get pv

echo -e "\n=== PersistentVolumeClaims ==="
kubectl get pvc -n exercise-12

echo -e "\n=== Pods ==="
kubectl get pods -n exercise-12

echo -e "\n=== PVC Binding Details ==="
kubectl describe pvc my-pvc -n exercise-12 2>/dev/null || echo "PVC deleted - showing PV only"

echo -e "\n=== PV Status (after PVC deletion) ==="
kubectl get pv my-pv

echo -e "\n=== Data Persistence Verification ==="
kubectl exec -n exercise-12 storage-pod-new -- cat /usr/share/nginx/html/test.txt 2>/dev/null || echo "Pod not running"
```

---

## Exam Critical Notes

| Component     | Purpose                        | Key Detail                                    |
| ------------- | ------------------------------ | --------------------------------------------- |
| PV            | Cluster storage resource       | `storageClassName`, `capacity`, `accessModes` |
| PVC           | Request for storage            | Must match PV's storageClassName              |
| Binding       | PV to PVC                      | Based on storage class and capacity           |
| Retain policy | PV persists after PVC deletion | Status becomes `Released`                     |
| hostPath      | Node-local storage             | For testing only, not production              |
| Pod mount     | Volume claim in pod            | `persistentVolumeClaim` in volumes            |

---

## Common Exam Traps

| Trap                          | Consequence              | Fix                                         |
| ----------------------------- | ------------------------ | ------------------------------------------- |
| Mismatched storageClassName   | No binding               | Ensure PV and PVC have same class           |
| Wrong accessMode              | Binding fails            | Match access modes (RWO, ROX, RWX)          |
| PVC requests more than PV     | Pending forever          | PVC must fit within PV capacity             |
| Forgetting hostPath directory | Pod fails to mount       | Create directory on node first              |
| ReclaimPolicy not Retain      | PV gets deleted with PVC | Set `persistentVolumeReclaimPolicy: Retain` |
| Wrong namespace               | PVC not found            | PV is cluster-wide, PVC is namespaced       |

---

## PV/PVC Binding Rules

**Binding requires:**

1. Matching `storageClassName` (or both empty)
2. PVC request ≤ PV capacity
3. Compatible `accessModes`
4. PV status `Available`

**Binding behavior:**

- PVC finds best matching PV
- One-to-one binding (one PVC per PV)
- Can bind to specific PV using `volumeName` in PVC

**Explicit binding to specific PV:**

```yaml
spec:
  volumeName: my-pv # Forces binding to this PV
```

---

## StorageClass vs Manual

**Using StorageClass (dynamic provisioning):**

```bash
# PVC with StorageClass automatically creates PV
kubectl get storageclass  # See available classes
```

**Manual provisioning (static):**

- Admin creates PV first
- PVC binds to existing PV
- Used in this exercise with `manual` class

---

## Reclaim Policies

| Policy  | PVC Deleted              | PV After PVC Deleted  |
| ------- | ------------------------ | --------------------- |
| Retain  | PV Released              | Manual cleanup needed |
| Delete  | PV Deleted               | Automatic cleanup     |
| Recycle | Scrubbed, then Available | Deprecated            |

---

## Pro Tips for CKA

1. **Always specify storageClassName** – Prevents binding to wrong PV
2. **hostPath only works on single-node** – In multi-node, use local PV or network storage
3. **Check PVC status immediately** – `Pending` means binding issue
4. **PVC deletion doesn't delete data with Retain** – Data persists on hostPath
5. **Use `kubectl describe` for binding issues** – Shows why PVC is pending
6. **Volume mounts are persistent across pod recreation** – That's the whole point

---

## Troubleshooting

**PVC stuck in Pending:**

```bash
kubectl describe pvc my-pvc -n exercise-12
# Look for events at bottom
```

**PV not binding:**

```bash
kubectl get pv my-pv -o yaml | grep -A5 status
# Check if PV is Available
```

**Pod can't mount volume:**

```bash
kubectl describe pod storage-pod -n exercise-12
# Check events for volume mount errors
```

**HostPath directory permissions:**

```bash
# On node
ls -la /data/exercise-12
# Should be readable by kubelet (usually root)
```

---

**Total exam time for this task:** ~6-8 minutes

**Most likely exam scenario:** Create PV and PVC, bind them, mount in pod, demonstrate persistence, then delete PVC and observe PV status change to Released with Retain policy.
