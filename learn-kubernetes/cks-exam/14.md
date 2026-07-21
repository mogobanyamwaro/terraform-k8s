# 14. Apply A Seccomp Profile

**Domain:** System Hardening

## Question

Run a pod with the default seccomp profile, then run another pod with a custom localhost seccomp profile.

## Answer

For the normal secure default, use `RuntimeDefault`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: runtime-default
  namespace: default
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: busybox:1.36
    command: ["sleep", "3600"]
```

Apply:

```bash
kubectl apply -f runtime-default.yaml
```

For a custom profile, create it on the node under the kubelet seccomp root:

```bash
sudo mkdir -p /var/lib/kubelet/seccomp/profiles
sudo vi /var/lib/kubelet/seccomp/profiles/audit.json
```

Example audit profile:

```json
{
  "defaultAction": "SCMP_ACT_LOG",
  "architectures": [
    "SCMP_ARCH_X86_64",
    "SCMP_ARCH_X86",
    "SCMP_ARCH_X32"
  ],
  "syscalls": []
}
```

Use it from a pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: localhost-seccomp
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/audit.json
  containers:
  - name: app
    image: busybox:1.36
    command: ["sleep", "3600"]
```

Apply:

```bash
kubectl apply -f localhost-seccomp.yaml
```

## Verify

```bash
kubectl get pod runtime-default localhost-seccomp
kubectl get pod localhost-seccomp -o jsonpath='{.spec.securityContext.seccompProfile}'; echo
```

## Exam tips

- `RuntimeDefault` is the safest fast answer unless a custom profile is required.
- Localhost profiles are relative to `/var/lib/kubelet/seccomp`.
- A missing localhost profile prevents the pod from starting.

