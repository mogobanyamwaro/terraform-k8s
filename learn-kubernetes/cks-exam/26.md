# 26. Pin An Image To A Digest

**Domain:** Supply Chain Security

## Question

Update Deployment `api` in namespace `cks-26` so it uses an immutable image digest instead of a mutable tag.

## Answer

Inspect current image:

```bash
kubectl get deployment api -n cks-26 -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
```

Find the digest. If `crane` is available:

```bash
crane digest nginx:1.27
```

If `skopeo` is available:

```bash
skopeo inspect docker://nginx:1.27 | grep Digest
```

If the task provides a digest, use that exact value.

Patch the image:

```bash
kubectl set image deployment/api api=nginx@sha256:<digest> -n cks-26
kubectl rollout status deployment/api -n cks-26
```

If the container name is unknown:

```bash
kubectl get deployment api -n cks-26 -o jsonpath='{.spec.template.spec.containers[*].name}'; echo
```

## Verify

```bash
kubectl get deployment api -n cks-26 -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
```

Expected format:

```text
nginx@sha256:...
```

## Exam tips

- Tags are mutable; digests are content-addressed.
- Use the digest given by the task if one is provided.
- Do not invent a digest in a real exam task; resolve or copy the exact value.

