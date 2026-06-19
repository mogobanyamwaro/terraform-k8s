Absolutely. **Pod Security Standards (PSS)** is one of those Kubernetes topics that becomes very simple once you understand the problem it's solving.

---

# 1. Why PSS Exists

Imagine any developer can create pods like this:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dangerous
spec:
  containers:
  - name: app
    image: nginx
    securityContext:
      privileged: true
```

A privileged container is almost equivalent to giving root access to the node.

Or someone could:

* Mount the host filesystem
* Access host networking
* Run as root
* Add Linux capabilities
* Disable seccomp

All of these increase the attack surface.

Kubernetes needed a way to say:

> "Pods in this namespace must follow these security rules."

That's what PSS provides.

---

# 2. Terminology

People often mix these terms:

| Term             | Meaning                                                |
| ---------------- | ------------------------------------------------------ |
| PSS              | Pod Security Standards (the rules)                     |
| PSA              | Pod Security Admission (the controller enforcing them) |
| Namespace Labels | How we tell PSA what rules to apply                    |

Think:

```text
PSS = Security Policy
PSA = Policeman
Namespace Label = The instructions given to the policeman
```

---

# 3. History

Before Kubernetes 1.25 there was:

```text
PodSecurityPolicy (PSP)
```

PSP was complicated and removed.

It was replaced by:

```text
Pod Security Standards (PSS)
Pod Security Admission (PSA)
```

which are much simpler.

---

# 4. The Three Security Levels

PSS defines three levels.

```text
Privileged
    ↓
Baseline
    ↓
Restricted
```

Each level is stricter than the previous.

---

# 5. Privileged

This is essentially:

```text
Allow everything
```

Example:

```yaml
securityContext:
  privileged: true
```

Allowed.

Host networking?

```yaml
hostNetwork: true
```

Allowed.

HostPath?

```yaml
volumes:
- hostPath:
    path: /
```

Allowed.

This level is typically used for:

* CNI plugins
* Storage drivers
* Monitoring agents
* System components

---

# 6. Baseline

Baseline blocks obviously dangerous settings.

Example:

```yaml
securityContext:
  privileged: true
```

❌ Rejected

Host namespaces:

```yaml
hostPID: true
hostIPC: true
```

❌ Rejected

HostPath mounts:

```yaml
hostPath:
  path: /
```

❌ Rejected

But running as root is still allowed.

```yaml
runAsUser: 0
```

✅ Allowed

---

# 7. Restricted

This is the strongest level.

It requires:

### Non-root

```yaml
runAsNonRoot: true
```

### No privilege escalation

```yaml
allowPrivilegeEscalation: false
```

### Drop capabilities

```yaml
capabilities:
  drop:
  - ALL
```

### Seccomp

```yaml
seccompProfile:
  type: RuntimeDefault
```

---

# 8. Enabling PSS

PSS is configured per namespace.

Create a namespace:

```bash
kubectl create ns secure-app
```

Apply restricted:

```bash
kubectl label namespace secure-app \
  pod-security.kubernetes.io/enforce=restricted
```

Verify:

```bash
kubectl get ns secure-app --show-labels
```

---

# 9. The Three Modes

This is where many people get confused.

There are actually three actions PSA can take.

## Enforce

Block the pod.

```bash
kubectl label ns secure-app \
  pod-security.kubernetes.io/enforce=restricted
```

Result:

```text
Forbidden
```

Pod never created.

---

## Warn

Allow pod creation.

Show warning.

```bash
kubectl label ns secure-app \
  pod-security.kubernetes.io/warn=restricted
```

Example:

```text
Warning: violates PodSecurity restricted
pod/nginx created
```

Pod still runs.

---

## Audit

Allow pod creation.

Record violations in audit logs.

```bash
kubectl label ns secure-app \
  pod-security.kubernetes.io/audit=restricted
```

Users won't necessarily notice.

Administrators can later review audit logs.

---

# 10. Combining Modes

Very common production setup:

```bash
kubectl label ns secure-app \
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/warn=restricted \
  pod-security.kubernetes.io/audit=restricted
```

Meaning:

```text
Block dangerous stuff (baseline)

Warn about anything not meeting restricted

Audit everything
```

This allows gradual migration.

---

# 11. Version Pinning

You can pin a specific Kubernetes version.

Example:

```bash
kubectl label ns secure-app \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=v1.34
```

Without this:

```text
restricted:latest
```

is used.

---

# 12. Why Your Nginx Pod Failed

You created:

```yaml
containers:
- name: nginx
  image: nginx
```

Restricted expects:

```yaml
securityContext:
  allowPrivilegeEscalation: false
```

Missing.

It expects:

```yaml
runAsNonRoot: true
```

Missing.

It expects:

```yaml
capabilities:
  drop:
  - ALL
```

Missing.

It expects:

```yaml
seccompProfile:
  type: RuntimeDefault
```

Missing.

Therefore:

```text
Forbidden
```

---

# 13. A Fully Compliant Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-nginx
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault

  containers:
  - name: nginx
    image: nginx:1.28

    securityContext:
      runAsNonRoot: true
      runAsUser: 101
      allowPrivilegeEscalation: false

      capabilities:
        drop:
        - ALL
```

This is close to what you'll see in production clusters.

---

# 14. How PSA Evaluates a Pod

When you run:

```bash
kubectl apply -f pod.yaml
```

The flow is:

```text
kubectl
    ↓
API Server
    ↓
Pod Security Admission
    ↓
Namespace Labels
    ↓
Check Pod Spec
    ↓
Allow or Reject
```

If compliant:

```text
Pod Created
```

If not:

```text
Forbidden
```

---

# 15. Real-World Namespace Strategy

Many organizations use:

| Namespace    | Policy     |
| ------------ | ---------- |
| kube-system  | privileged |
| monitoring   | baseline   |
| logging      | baseline   |
| applications | restricted |
| production   | restricted |

Example:

```bash
kubectl label ns production \
  pod-security.kubernetes.io/enforce=restricted
```

This ensures application teams can't accidentally deploy insecure workloads.

---

# 16. Interview Questions

### What's the difference between PSP and PSS?

* PSP was a resource and admission controller.
* PSP was removed.
* PSS defines security standards.
* PSA enforces those standards.

### Does PSS replace RBAC?

No.

```text
RBAC → Who can do something
PSS  → What security settings pods may use
```

### Is PSS cluster-wide?

No.

It is applied per namespace using labels.

### Does restricted require non-root containers?

Yes.

```yaml
runAsNonRoot: true
```

is required.

---

## Mental Model

Whenever you see:

```bash
kubectl label namespace myapp \
  pod-security.kubernetes.io/enforce=restricted
```

Think:

> "Every pod entering this namespace must pass a security inspection before the API server accepts it."

That's the entire Pod Security Standards system in one sentence.
