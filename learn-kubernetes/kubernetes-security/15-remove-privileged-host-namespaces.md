# 15. Remove Privileged And Host Namespace Access

**Domain:** System Hardening

## Question

A pod named `debug-shell` in namespace `cks-15` is using privileged mode, host PID, host IPC, and host network. Replace it with a safer pod that still runs but does not use host namespaces or privileged mode.

## Answer

Inspect the pod:

```bash
kubectl get pod debug-shell -n cks-15 -o yaml > debug-shell.yaml
```

Look for dangerous fields:

```yaml
hostPID: true
hostIPC: true
hostNetwork: true
securityContext:
  privileged: true
```

Edit the YAML:

```bash
vi debug-shell.yaml
```

Set or remove:

```yaml
spec:
  hostPID: false
  hostIPC: false
  hostNetwork: false
  containers:
  - name: debug-shell
    securityContext:
      privileged: false
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      seccompProfile:
        type: RuntimeDefault
```

Remove generated fields before applying:

```yaml
status:
metadata:
  creationTimestamp:
  resourceVersion:
  uid:
```

Recreate:

```bash
kubectl delete pod debug-shell -n cks-15
kubectl apply -f debug-shell.yaml
```

## Verify

```bash
kubectl get pod debug-shell -n cks-15 -o jsonpath='{.spec.hostPID}{" "}{.spec.hostIPC}{" "}{.spec.hostNetwork}{"\n"}'
kubectl get pod debug-shell -n cks-15 -o jsonpath='{.spec.containers[0].securityContext.privileged}{"\n"}'
```

Expected: false or empty values.

## Exam tips

- Host namespaces expose node-level process, network, or IPC surfaces.
- Privileged containers are one of the biggest CKS red flags.
- For Deployments, edit the pod template instead of editing individual pods.

