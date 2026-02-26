# Topic 8: PersistentVolumes & PVCs

## What You'll Learn

- **PV** – cluster resource (storage)
- **PVC** – request for storage by user
- **StorageClass** – dynamic provisioning
- AccessModes: ReadWriteOnce, ReadOnlyMany, ReadWriteMany

## Steps

### 1. Apply (requires StorageClass or manual PV)

```bash
# Minikube/Kind: usually has default StorageClass
kubectl get storageclass
kubectl apply -f .
```

### 2. Inspect

```bash
kubectl get pvc
kubectl describe pvc my-pvc
```

---

## Exam Tips

| AccessMode | Use                       |
| ---------- | ------------------------- |
| RWO        | Single node read-write    |
| ROX        | Multiple nodes read-only  |
| RWX        | Multiple nodes read-write |

These access modes say how the volume can be used across nodes:

### **RWO (ReadWriteOnce)**

- **One node at a time** can mount the volume for read and write
- Typical for block storage (EBS, GCP persistent disk)
- Example: One pod on node A uses the volume; only when that pod is gone can a pod on node B use it
- Use when a single pod needs a dedicated disk

### **ROX (ReadOnlyMany)**

- **Several nodes** can mount the volume for **read-only**
- Example: NFS or object storage shared for static assets
- Use when many pods on different nodes need read-only access to the same data

### **RWX (ReadWriteMany)**

- **Several nodes** can mount the volume for **read and write**
- Example: NFS or distributed storage
- Use when many pods on different nodes need to read and write the same data
- Not all storage backends support it (EBS and most block storage do not)

### Summary

| Mode | Mounts at once | Read | Write |
| ---- | -------------- | ---- | ----- |
| RWO  | One node       | ✅   | ✅    |
| ROX  | Many nodes     | ✅   | ❌    |
| RWX  | Many nodes     | ✅   | ✅    |

## Practice

1. Create a PVC requesting 2Gi with ReadWriteOnce.
2. Check if it's bound: `kubectl get pvc`.
