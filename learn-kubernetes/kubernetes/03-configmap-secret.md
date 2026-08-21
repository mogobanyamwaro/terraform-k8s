Create ConfigMaps and Secrets, then inject them into a pod as environment variables and mounted files.

## Tasks

1. Create a namespace called `exercise-03`
2. Create a ConfigMap named `app-config` with:
   - Key `APP_MODE` = `production`
   - Key `LOG_LEVEL` = `debug`
3. Create a Secret named `db-creds` with:
   - Key `DB_USER` = `admin`
   - Key `DB_PASS` = `s3cretP@ss`
4. Create a pod named `app` that:
   - Uses image `busybox:1.36`, command `sleep 3600`
   - Loads `APP_MODE` and `LOG_LEVEL` from the ConfigMap as env vars
   - Loads `DB_USER` and `DB_PASS` from the Secret as env vars
   - Mounts the entire ConfigMap as files at `/etc/config/`
5. Verify the env vars are set inside the pod
6. Verify the mounted files exist at `/etc/config/`

## Hints

---

Here's my CKA exam approach for **ConfigMaps and Secrets** – systematic and efficient:

---

## 1. Create namespace

```bash
kubectl create namespace exercise-03
```

---

## 2. Create ConfigMap

**Option A – Literal (fastest for exam):**

```bash
kubectl create configmap app-config -n exercise-03 \
  --from-literal=APP_MODE=production \
  --from-literal=LOG_LEVEL=debug
```

**Option B – Verify after creation:**

```bash
kubectl get configmap app-config -n exercise-03 -o yaml
```

---

## 3. Create Secret

**Option A – Literal (fastest):**

```bash
kubectl create secret generic db-creds -n exercise-03 \
  --from-literal=DB_USER=admin \
  --from-literal=DB_PASS=s3cretP@ss
```

**Option B – Verify (optional):**

```bash
kubectl get secret db-creds -n exercise-03 -o yaml
# Values will be base64 encoded
```

---

## 4. Create pod with ConfigMap and Secret injection

**Generate pod skeleton:**

```bash
kubectl run app --image=busybox:1.36 -n exercise-03 --dry-run=client -o yaml > app.yaml
```

**Edit `app.yaml` to add:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app
  namespace: exercise-03
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sleep", "3600"]
      env:
        # From ConfigMap
        - name: APP_MODE
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: APP_MODE
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: LOG_LEVEL
        # From Secret
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: db-creds
              key: DB_USER
        - name: DB_PASS
          valueFrom:
            secretKeyRef:
              name: db-creds
              key: DB_PASS
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        name: app-config
```

**Apply:**

```bash
kubectl apply -f app.yaml
```

---

## 5. Verify env vars are set

```bash
# Check all env vars
kubectl exec -n exercise-03 app -- env | grep -E "APP_MODE|LOG_LEVEL|DB_USER|DB_PASS"
```

**Expected output:**

```
APP_MODE=production
LOG_LEVEL=debug
DB_USER=admin
DB_PASS=s3cretP@ss
```

**Alternative – check individually:**

```bash
kubectl exec -n exercise-03 app -- sh -c 'echo $APP_MODE'
kubectl exec -n exercise-03 app -- sh -c 'echo $DB_USER'
```

---

## 6. Verify mounted files exist at `/etc/config/`

```bash
# List files in mount directory
kubectl exec -n exercise-03 app -- ls -la /etc/config/
```

**Expected output shows:** `APP_MODE`, `LOG_LEVEL` (each key becomes a file)

```bash
# Check file contents
kubectl exec -n exercise-03 app -- cat /etc/config/APP_MODE
kubectl exec -n exercise-03 app -- cat /etc/config/LOG_LEVEL
```

**Expected:**

```
production
debug
```

**Verify all at once:**

```bash
kubectl exec -n exercise-03 app -- sh -c 'for f in /etc/config/*; do echo "$f: $(cat $f)"; done'
```

---

## Quick verification checklist

```bash
# Pod running?
kubectl get pod app -n exercise-03

# All env vars?
kubectl exec -n exercise-03 app -- env | sort

# ConfigMap mounted as files?
kubectl exec -n exercise-03 app -- find /etc/config -type f -exec cat {} \;
```

---

## Exam critical notes:

| Requirement            | Method                                 | Key syntax                  |
| ---------------------- | -------------------------------------- | --------------------------- |
| ConfigMap env vars     | `configMapKeyRef`                      | `valueFrom.configMapKeyRef` |
| Secret env vars        | `secretKeyRef`                         | `valueFrom.secretKeyRef`    |
| Mount entire ConfigMap | `volumes[].configMap` + `volumeMounts` | Each key → file             |
| Secret values in env   | Auto-decrypted by kubelet              | No base64 decode needed     |

---

## Common exam traps:

❌ **Don't do this:**

```yaml
env:
  - name: APP_MODE
    value: production # Wrong - bypasses ConfigMap
```

✅ **Do this:**

```yaml
env:
  - name: APP_MODE
    valueFrom:
      configMapKeyRef:
        name: app-config
        key: APP_MODE
```

❌ **Mount path trailing slash:** `mountPath: /etc/config/` (works but inconsistent)

✅ **No trailing slash:** `mountPath: /etc/config`

---

## Time-saving tips:

- **Create ConfigMap/Secret in one line** with `--from-literal` (no YAML files)
- **Use `kubectl exec -- env | grep`** to quickly verify
- **Secret values are base64 in etcd** but plaintext inside pod – don't be confused
- **If mount fails**, check pod events: `kubectl describe pod app -n exercise-03`

---

## Bonus – Verify Secret is actually secret:

```bash
# Secret stored encrypted (if etcd encryption enabled)
kubectl get secret db-creds -n exercise-03 -o jsonpath='{.data.DB_PASS}'
# Returns base64: czNjcmV0UEBzcw==

# But in pod it's plaintext
kubectl exec -n exercise-03 app -- echo $DB_PASS
# Returns: s3cretP@ss
```

---

**Total exam time for this task:** ~4-5 minutes

**Pro tip:** Keep this YAML pattern memorized – ConfigMap+Secret injection is **guaranteed** to appear on CKA.
