# 16. Harden Linux Capabilities And Root Filesystem

**Domain:** System Hardening

## Question

Harden a Deployment named `api` in namespace `cks-16` by dropping all Linux capabilities, allowing only `NET_BIND_SERVICE`, disabling privilege escalation, and making the root filesystem read-only.

## Answer

Export the Deployment:

```bash
kubectl get deployment api -n cks-16 -o yaml > api.yaml
```

Edit the container security context:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: cks-16
spec:
  template:
    spec:
      containers:
      - name: api
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
            add:
            - NET_BIND_SERVICE
          seccompProfile:
            type: RuntimeDefault
```

Apply:

```bash
kubectl apply -f api.yaml
kubectl rollout status deployment/api -n cks-16
```

If the application needs writable temp space, add an `emptyDir`:

```yaml
spec:
  template:
    spec:
      volumes:
      - name: tmp
        emptyDir: {}
      containers:
      - name: api
        volumeMounts:
        - name: tmp
          mountPath: /tmp
```

## Verify

```bash
kubectl get deployment api -n cks-16 -o jsonpath='{.spec.template.spec.containers[0].securityContext}'; echo
kubectl get pods -n cks-16
```

Check the rollout:

```bash
kubectl describe deployment api -n cks-16
```

## Exam tips

- `drop: ["ALL"]` removes default capabilities.
- Add back only the exact capability required.
- `readOnlyRootFilesystem: true` often needs writable `/tmp` or app-specific data mounts.

