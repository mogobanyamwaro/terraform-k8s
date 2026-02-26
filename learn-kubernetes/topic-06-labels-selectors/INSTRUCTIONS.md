# Topic 6: Labels & Selectors

## What You'll Learn

- **Labels** – key=value metadata on resources
- **Selectors** – filter resources by labels
- Equality: `app=frontend`, `env!=prod`
- Set-based: `env in (prod, staging)`

## Steps

### 1. Apply

```bash
kubectl apply -f pod.yaml
```

### 2. Query by label

```bash
kubectl get pods -l app=frontend
kubectl get pods -l tier=web
kubectl get pods -l 'env in (prod, staging)'
kubectl get pods --selector=app=frontend
```

### 3. Add label

```bash
kubectl label pod frontend-pod version=v1
kubectl get pods --show-labels
```

### 4. Delete

```bash
kubectl delete -f pod.yaml
```

---

## Exam Tips

| Selector   | Example                  |
| ---------- | ------------------------ |
| Equality   | `-l app=nginx`           |
| Inequality | `-l env!=prod`           |
| Set-based  | `-l 'env in (dev,prod)'` |
| Exists     | `-l 'tier'`              |
| Not exists | `-l '!tier'`             |

## Practice

1. Create a pod with labels `team=backend` and `env=dev`.
2. List pods that have label `team=backend`.
