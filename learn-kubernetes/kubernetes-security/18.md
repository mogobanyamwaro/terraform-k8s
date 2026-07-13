# 18. Enforce Pod Security Standards

**Domain:** Minimize Microservice Vulnerabilities

## Question

Create namespace `cks-18` and enforce the Restricted Pod Security Standard. Also enable warning and audit labels.

## Answer

Create namespace:

```bash
kubectl create namespace cks-18
```

Label it:

```bash
kubectl label namespace cks-18 \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=latest \
  pod-security.kubernetes.io/warn=restricted \
  pod-security.kubernetes.io/warn-version=latest \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/audit-version=latest
```

Create a compliant pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restricted-ok
  namespace: cks-18
spec:
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: nginx:1.27
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
```

Apply:

```bash
kubectl apply -f restricted-ok.yaml
```

Create a failing pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: privileged-bad
  namespace: cks-18
spec:
  containers:
  - name: app
    image: nginx:1.27
    securityContext:
      privileged: true
```

Try it:

```bash
kubectl apply -f privileged-bad.yaml
```

Expected: admission rejection.

## Verify

```bash
kubectl get namespace cks-18 --show-labels
kubectl get pods -n cks-18
```

## Exam tips

- PSS is the rule set. PSA is the built-in admission controller.
- `enforce` rejects bad pods.
- `warn` prints warnings to the user.
- `audit` writes policy violations to audit logs.

