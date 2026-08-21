# 24. Scan Container Images With Trivy

**Domain:** Supply Chain Security

## Question

Scan image `nginx:1.16` for vulnerabilities, identify that it is risky, and update the Deployment `web` in namespace `cks-24` to use `nginx:1.27`.

## Answer

Scan the old image:

```bash
trivy image nginx:1.16
```

Show only high and critical vulnerabilities:

```bash
trivy image --severity HIGH,CRITICAL nginx:1.16
```

Update the Deployment:

```bash
kubectl set image deployment/web web=nginx:1.27 -n cks-24
kubectl rollout status deployment/web -n cks-24
```

If the container name is unknown:

```bash
kubectl get deployment web -n cks-24 -o jsonpath='{.spec.template.spec.containers[*].name}'; echo
```

Rescan the new image:

```bash
trivy image --severity HIGH,CRITICAL nginx:1.27
```

## Verify

```bash
kubectl get deployment web -n cks-24 -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
kubectl get pods -n cks-24
```

## Exam tips

- CKS tasks often provide tools like `trivy`, `kubesec`, or `falco`; use the tool named in the question.
- Prefer a supported newer image tag over an old vulnerable tag.
- If asked for immutable images, use a digest like `image@sha256:<digest>`.

