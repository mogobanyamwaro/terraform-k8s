# Topic 2: ReplicaSet & Deployment

## What You'll Learn

- **ReplicaSet** – maintains desired number of pod replicas
- **Deployment** – declarative updates; manages ReplicaSets
- `kubectl scale`, `kubectl rollout`
- `kubectl create deployment`

## Steps

### 1. Apply

```bash
kubectl apply -f deployment.yaml
```

### 2. Inspect

```bash
kubectl get deployments
kubectl get replicasets
kubectl get pods -l app=nginx
```

### 3. Scale

```bash
kubectl scale deployment nginx-deployment --replicas=5
kubectl get pods -l app=nginx
```

### 4. Update (rollout)

```bash
kubectl set image deployment/nginx-deployment nginx=nginx:1.25-alpine
kubectl rollout status deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment
```

### 5. Rollback

```bash
kubectl rollout undo deployment/nginx-deployment
```

### 6. Imperative create

```bash
kubectl create deployment myapp --image=nginx --replicas=2
```

---

## Exam Tips

| Command                                   | Purpose              |
| ----------------------------------------- | -------------------- |
| `kubectl scale deployment X --replicas=N` | Change replica count |
| `kubectl rollout status deployment/X`     | Wait for rollout     |
| `kubectl rollout undo deployment/X`       | Rollback             |
| `kubectl rollout history deployment/X`    | View revisions       |
| `kubectl create deployment`               | Imperative create    |

## Practice

1. Scale the deployment to 1 replica, then back to 3.
2. Create a deployment named `web` with image `httpd:alpine` and 2 replicas using one command.
