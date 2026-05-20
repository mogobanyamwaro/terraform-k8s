## 1. Create namespace

```bash
kubectl create namespace exercise-01
```

---

## 2. Generate pod YAML (dry-run, then save/edit)

```bash
kubectl run web --image=nginx:1.27 -n exercise-01 --dry-run=client -o yaml > web.yaml
```

Edit `web.yaml` to add:

- labels (`app=web, tier=frontend`)
- resources (requests & limits)

Final pod spec inside YAML:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web
  namespace: exercise-01
  labels:
    app: web
    tier: frontend
spec:
  containers:
    - name: web
      image: nginx:1.27
      resources:
        requests:
          memory: "64Mi"
          cpu: "100m"
        limits:
          memory: "128Mi"
          cpu: "250m"
```

Create the pod:

```bash
kubectl apply -f web.yaml
```

---

## 3. Verify pod running + labels

```bash
kubectl get pod web -n exercise-01 --show-labels
```

Also check status:

```bash
kubectl get pod web -n exercise-01
```

---

## 4. Get pod IP using `-o wide`

```bash
kubectl get pod web -n exercise-01 -o wide
```

(IP is in the `IP` column)

---

## 5. Add label `version=v1` to running pod

```bash
kubectl label pod web -n exercise-01 version=v1
```

---

## 6. Remove `tier` label from the pod

```bash
kubectl label pod web -n exercise-01 tier-
```

---

## 7. Final verification

```bash
kubectl get pod web -n exercise-01 --show-labels
```

Expected labels: `app=web, version=v1` (tier removed).

---

## Exam tips:

- **Don’t overtype** – use `--dry-run=client -o yaml` + redirect
- **Keep YAML minimal** – no need for `status`, `nodeSelector`, etc.
- **Use `--show-labels`** to view labels quickly
- **Remove label with `labelname-`** (trailing minus) – easy to forget
- **If stuck**, `kubectl explain pod.spec.containers.resources` shows resource format

Total time for this: **~3 minutes** if comfortable with kubectl.
