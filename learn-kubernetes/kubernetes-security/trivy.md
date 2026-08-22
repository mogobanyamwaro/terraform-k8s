# Trivy CKS Notes

Trivy can scan:

- Container images
- Filesystems
- Git repositories
- Kubernetes manifests and Helm charts

CKS tasks commonly ask you to find vulnerabilities or insecure config and then fix the workload.

## Image Scan

```bash
trivy image nginx:1.16
```

Only high and critical:

```bash
trivy image --severity HIGH,CRITICAL nginx:1.16
```

Ignore unfixed vulnerabilities if the task asks:

```bash
trivy image --ignore-unfixed nginx:1.16
```

Write output:

```bash
trivy image --severity HIGH,CRITICAL nginx:1.16 > /opt/trivy-nginx.txt
```

## Manifest Scan

```bash
trivy config deployment.yaml
```

Scan a directory:

```bash
trivy config ./manifests
```

## Common Image Fix

Find image:

```bash
kubectl get deployment web -n prod -o jsonpath='{.spec.template.spec.containers[*].image}'; echo
```

Update image:

```bash
kubectl set image deployment/web web=nginx:1.27 -n prod
kubectl rollout status deployment/web -n prod
```

## Common Manifest Fixes

Add resources:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

Drop capabilities:

```yaml
securityContext:
  capabilities:
    drop:
    - ALL
```

Disable privilege escalation:

```yaml
securityContext:
  allowPrivilegeEscalation: false
```

Use seccomp:

```yaml
securityContext:
  seccompProfile:
    type: RuntimeDefault
```

Run as non-root:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 10001
```

Disable service account token:

```yaml
automountServiceAccountToken: false
```

## Exam tips

- Save scanner output only if the question asks for an output file.
- Fix the object named in the task, not every finding in the universe.
- A newer image tag can still have findings. Use the task's required severity threshold.
- If network access is blocked, use images and databases already present in the exam environment.

