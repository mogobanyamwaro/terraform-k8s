# 25. Scan Kubernetes Manifests Before Applying

**Domain:** Supply Chain Security

## Question

Scan `deployment.yaml` for insecure Kubernetes settings and fix the manifest before applying it.

## Answer

If `trivy` is available:

```bash
trivy config deployment.yaml
```

If `kubesec` is available:

```bash
kubesec scan deployment.yaml
```

Common findings to fix:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: cks-25
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      automountServiceAccountToken: false
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: api
        image: nginx:1.27
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
```

Apply after fixing:

```bash
kubectl create namespace cks-25
kubectl apply -f deployment.yaml
kubectl rollout status deployment/api -n cks-25
```

## Verify

Rerun the scanner:

```bash
trivy config deployment.yaml
```

Check live workload:

```bash
kubectl get deployment api -n cks-25 -o yaml | grep -E 'runAsNonRoot|allowPrivilegeEscalation|readOnlyRootFilesystem|seccompProfile|automountServiceAccountToken'
```

## Exam tips

- Scan the exact file named by the question.
- Fix the manifest, not just the live object, if the task gives a file path.
- Common manifest issues: privileged containers, missing resources, root user, automounted API token, missing seccomp.

