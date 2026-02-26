# Topic 9: Multi-container Pods

## What You'll Learn

- Multiple containers share: network (localhost), volumes
- `kubectl logs <pod> -c <container>`
- Init containers run before main containers

## Steps

### 1. Apply

```bash
kubectl apply -f pod.yaml
kubectl logs multi-pod -c main
kubectl logs multi-pod -c sidecar
```

### 2. Exec into specific container

```bash
kubectl exec multi-pod -c sidecar -it -- /bin/sh
```

---

## Exam Tips

| Flag             | Purpose                          |
| ---------------- | -------------------------------- |
| `-c <container>` | Target specific container in pod |

## Practice

1. Add an init container that runs `echo init done` before main containers start.
