# 19. Run A Workload As Non-Root

**Domain:** Minimize Microservice Vulnerabilities

## Question

Harden Deployment `web` in namespace `cks-19` so containers must run as non-root user `10001`.

## Answer

Export the Deployment:

```bash
kubectl get deployment web -n cks-19 -o yaml > web.yaml
```

Edit the pod template:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: cks-19
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        runAsGroup: 10001
        fsGroup: 10001
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: web
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
```

Apply:

```bash
kubectl apply -f web.yaml
kubectl rollout status deployment/web -n cks-19
```

If the image cannot run as non-root, the pod may fail with permission errors. In the exam, you may be asked to change to a known non-root image or mount writable directories.

## Verify

```bash
kubectl get deployment web -n cks-19 -o jsonpath='{.spec.template.spec.securityContext}'; echo
kubectl get pods -n cks-19
kubectl logs -n cks-19 deployment/web
```

Check the running user:

```bash
POD=$(kubectl get pod -n cks-19 -l app=web -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n cks-19 $POD -- id
```

Expected: uid should not be `0`.

## Exam tips

- `runAsNonRoot: true` rejects images that try to run as UID 0.
- `runAsUser` sets the actual UID.
- Use pod-level security context for common settings and container-level context for capability/privilege settings.

