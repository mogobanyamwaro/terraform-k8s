# 21. Handle Secrets Safely In Workloads

**Domain:** Minimize Microservice Vulnerabilities

## Question

In namespace `cks-21`, create a Secret and mount it read-only into a pod. Do not expose the Secret as an environment variable.

## Answer

Create namespace:

```bash
kubectl create namespace cks-21
```

Create the Secret:

```bash
kubectl create secret generic db-creds -n cks-21 \
  --from-literal=username=appuser \
  --from-literal=password='change-me'
```

Create a pod that mounts it as a read-only volume:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app
  namespace: cks-21
spec:
  automountServiceAccountToken: false
  securityContext:
    runAsNonRoot: true
    runAsUser: 10001
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: busybox:1.36
    command: ["sleep", "3600"]
    volumeMounts:
    - name: db-creds
      mountPath: /etc/db-creds
      readOnly: true
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
  volumes:
  - name: db-creds
    secret:
      secretName: db-creds
```

Apply:

```bash
kubectl apply -f app.yaml
```

## Verify

```bash
kubectl wait --for=condition=Ready pod/app -n cks-21 --timeout=60s
kubectl exec -n cks-21 app -- ls -l /etc/db-creds
kubectl exec -n cks-21 app -- sh -c 'echo test > /etc/db-creds/password'
```

Expected: writing should fail because the Secret volume is read-only.

Check that no Secret environment variables are present:

```bash
kubectl get pod app -n cks-21 -o yaml | grep -n "secretKeyRef"
```

Expected: no output.

## Exam tips

- Secret values in environment variables can leak through process inspection and debug output.
- Secret volumes are mounted read-only by default, but include `readOnly: true` for clarity.
- Disable service account token automount when the app does not need the API.

---
This one is testing **how to handle Kubernetes Secrets securely**.

The question has **three requirements**:

1. Create a Secret in `cks-21`.
2. Mount the Secret as a **file** inside a Pod.
3. Make the mount **read-only** and **do not use environment variables**.

### Think about the desired architecture

```text
Secret
   |
   ↓
Pod
   |
   ↓
/etc/secrets/
   ├── username
   └── password
```

The application reads the credentials from files instead of:

```text
❌ environment variable
PASSWORD=supersecret
```

---

## 1. Create the Secret

For example:

```bash
kubectl create namespace cks-21

kubectl create secret generic app-secret \
  -n cks-21 \
  --from-literal=username=admin \
  --from-literal=password=supersecret
```

Now Kubernetes has:

```text
cks-21
└── Secret: app-secret
    ├── username
    └── password
```

---

## 2. Mount it as a volume

Your Pod would have:

```yaml
volumes:
- name: secret-volume
  secret:
    secretName: app-secret
```

Then inside the container:

```yaml
volumeMounts:
- name: secret-volume
  mountPath: /etc/secrets
  readOnly: true
```

So:

```text
Secret
  ↓
secret-volume
  ↓
/etc/secrets
  ↓
Container
```

The files become:

```text
/etc/secrets/username
/etc/secrets/password
```

---

## 3. Why `readOnly: true`?

The question specifically says:

> **mount it read-only**

So:

```yaml
readOnly: true
```

means the container can:

```text
cat /etc/secrets/password     ✅
```

but shouldn't be able to modify the mounted Secret volume:

```text
echo hacked > /etc/secrets/password    ❌
```

---

## 4. "Do not expose the Secret as an environment variable"

This is the other important part.

**Don't do this:**

```yaml
env:
- name: PASSWORD
  valueFrom:
    secretKeyRef:
      name: app-secret
      key: password
```

That would expose the Secret as:

```text
PASSWORD=supersecret
```

Instead, use:

```yaml
volumes:
- name: secret-volume
  secret:
    secretName: app-secret

containers:
- name: app
  image: nginx

  volumeMounts:
  - name: secret-volume
    mountPath: /etc/secrets
    readOnly: true
```

Now the application accesses:

```text
/etc/secrets/password
```

rather than an environment variable.

---

### The CKS concept

The question is essentially asking:

> **"Use a Secret as a read-only file inside the container, rather than injecting its values into the container's environment."**

Remember this pattern:

```text
             Kubernetes Secret
                    |
                    ↓
               Secret Volume
                    |
                    ↓
             /etc/secrets
                    |
             ┌──────┴──────┐
             ↓             ↓
        username        password
```

And the security principle is:

**Secret → volume mount → read-only**

rather than:

**Secret → environment variable.**
