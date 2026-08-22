# Pod Security Standards CKS Notes

Pod Security Standards define three levels:

```text
Privileged -> Baseline -> Restricted
```

CKS usually cares about `Restricted`.

## Enable Restricted On A Namespace

```bash
kubectl label namespace secure \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=latest \
  pod-security.kubernetes.io/warn=restricted \
  pod-security.kubernetes.io/warn-version=latest \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/audit-version=latest
```

## Check Labels

```bash
kubectl get namespace secure --show-labels
```

## Restricted-Compliant Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restricted-ok
  namespace: secure
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

## Settings Restricted Blocks

Privileged:

```yaml
securityContext:
  privileged: true
```

Host namespaces:

```yaml
hostNetwork: true
hostPID: true
hostIPC: true
```

Privilege escalation:

```yaml
allowPrivilegeEscalation: true
```

Unsafe capabilities:

```yaml
capabilities:
  add:
  - SYS_ADMIN
```

Missing seccomp:

```yaml
seccompProfile:
  type: RuntimeDefault
```

## Fix A Rejected Pod

If admission rejects a pod:

```bash
kubectl apply -f pod.yaml
```

Read the warning/error carefully, then patch the pod spec:

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
```

For controllers, edit the template:

```bash
kubectl edit deployment <name> -n <namespace>
kubectl rollout status deployment/<name> -n <namespace>
```

## Enforce vs Warn vs Audit

| Mode | Effect |
| --- | --- |
| `enforce` | Rejects violating pods |
| `warn` | Allows but prints warning |
| `audit` | Allows but records audit annotation |

## Exam tips

- Namespace labels are the fastest PSA configuration method.
- `restricted` is strict, so older images that run as root may fail.
- If a task says "do not break the workload", verify rollout and logs after hardening.

