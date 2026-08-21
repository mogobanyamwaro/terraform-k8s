Deploy a stateful application using StatefulSet. This exercise teaches ordered pod initialization, persistent storage, and stable network identities—critical for databases and distributed systems on the CKA.

## Context

StatefulSets are for applications that need:

- Stable, predictable pod names (not randomly generated like Deployments)
- Ordered pod startup and shutdown
- Persistent storage per pod replica
- Stable network identities (DNS names with ordinal suffixes)

Unlike Deployments where pod identity doesn't matter, StatefulSets maintain identity across restarts. Example: a MySQL cluster needs predictable names like `mysql-0`, `mysql-1`, `mysql-2` that survive pod recreations.

## Tasks

1. Create a headless Service for the StatefulSet (required for DNS routing)
2. Create a StatefulSet with 3 replicas using the `nginx:1.28` image
3. Verify pods start in order (mysql-0 first, then mysql-1, then mysql-2)
4. Verify each pod has a persistent volume claim attached
5. Delete a pod and observe it respawn with the same name and storage
6. Scale the StatefulSet up and down using `kubectl scale`
7. Delete the StatefulSet and verify PVCs persist (data survives)

---

Good — this is a very typical CKA-style StatefulSet question. The key to scoring full marks is:

> **use the smallest number of YAMLs, rely on defaults, and avoid manual PV work**

We’ll do it in the **lowest operational overhead way possible**.

---

# 🧠 STRATEGY (what examiners want)

You only need:

1. Headless Service
2. StatefulSet with `volumeClaimTemplates`
3. `local-path` or default StorageClass (dynamic provisioning)
4. kubectl commands to verify behavior

You DO NOT:

- manually create PVs
- manually create PVCs
- manually manage storage

---

# 🚀 STEP 1 — Headless Service (REQUIRED)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  clusterIP: None
  selector:
    app: mysql
  ports:
  - port: 3306
    targetPort: 3306
EOF
```

✔ This enables:

- stable DNS
- StatefulSet identity

---

# 🚀 STEP 2 — StatefulSet (core answer)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: nginx:1.28
        ports:
        - containerPort: 80
        volumeMounts:
        - name: data
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: local-path
      resources:
        requests:
          storage: 100Mi
EOF
```

---

# 🧠 Why this is optimal

✔ PVCs auto-created
✔ PVs auto-created (via provisioner)
✔ No manual storage work
✔ No YAML explosion

This is what gets full marks.

---

# 🚀 STEP 3 — Verify ordered pod creation

```bash
kubectl get pods -w
```

You will see:

```text
mysql-0
mysql-1
mysql-2
```

✔ Ordered creation is automatic in StatefulSet

---

# 🚀 STEP 4 — Verify PVCs

```bash
kubectl get pvc
```

You should see:

```text
data-mysql-0
data-mysql-1
data-mysql-2
```

✔ Each pod has its own storage

---

# 🚀 STEP 5 — Delete a Pod (recreate test)

```bash
kubectl delete pod mysql-1
```

Then:

```bash
kubectl get pods
```

✔ It comes back as:

```text
mysql-1
```

✔ Same name
✔ Same PVC attached
✔ Same storage preserved

---

# 🚀 STEP 6 — Scale StatefulSet

## Scale up

```bash
kubectl scale statefulset mysql --replicas=5
```

✔ creates:

- mysql-3
- mysql-4
- new PVCs automatically

---

## Scale down

```bash
kubectl scale statefulset mysql --replicas=2
```

✔ deletes:

- mysql-4
- mysql-3

✔ BUT PVCs remain (important exam point)

---

# 🚀 STEP 7 — Delete StatefulSet (IMPORTANT MARKS)

```bash
kubectl delete statefulset mysql
```

---

# 🔍 Verify PVCs still exist

```bash
kubectl get pvc
```

✔ You will still see:

```text
data-mysql-0
data-mysql-1
data-mysql-2
```

---

# 🧠 WHY THIS IS IMPORTANT (exam trick)

StatefulSet deletion:

| Resource    | Behavior   |
| ----------- | ---------- |
| Pods        | deleted    |
| StatefulSet | deleted    |
| PVCs        | ❗ persist |

Because Kubernetes assumes:

> “Stateful data should not be accidentally lost”

---

# 🧠 WHAT YOU USED (minimal overhead)

✔ 2 YAMLs only:

- Service
- StatefulSet

✔ Everything else automatic:

- PVC creation
- PV creation
- binding
- scaling
- identity

---

# ⚡ KEY EXAM SUMMARY (MEMORIZE THIS)

> StatefulSet + Headless Service + volumeClaimTemplates is enough to satisfy full persistent storage requirements — no manual PVs required if StorageClass exists.

---

# 🧠 FINAL MENTAL MODEL

```text
Headless Service → DNS identity
StatefulSet → Pods + ordered identity
volumeClaimTemplates → PVCs per Pod
StorageClass → PV automation
Provisioner → actual storage creation
```

---

# Clean up

```bash
{
kubectl delete statefulset mysql
kubectl delete service mysql
kubectl delete pvc -l app=mysql
}
```
