# Topic 1: Pods

## What You'll Learn

- **Pod** – smallest deployable unit; wraps one or more containers
- `kubectl apply`, `kubectl get`, `kubectl describe`
- `kubectl exec`, `kubectl logs`
- `kubectl run` – imperative create

## Steps

### 1. Apply the pod

```bash
kubectl apply -f pod.yaml
```

### 2. Inspect

```bash
kubectl get pods
kubectl get pod nginx-pod -o wide
kubectl describe pod nginx-pod
```

### 3. Interact

```bash
# Logs
kubectl logs nginx-pod

# Execute into container
kubectl exec nginx-pod -it -- /bin/sh
# Inside: curl localhost:80  | head
# Exit: exit
```

# Expose the pod as a service

kubectl expose pod nginx-pod --type=NodePort --port=80 --name=nginx-service

# Or create a service YAML

**microk8s users:** If exec fails with "is not supported anymore", use standalone kubectl:

```bash
microk8s config > ~/.kube/config   # one-time
/opt/homebrew/bin/kubectl exec nginx-pod -it -- /bin/sh
```

### 4. Imperative create (exam shortcut)

```bash
kubectl run busybox --image=busybox --restart=Never -- sleep 3600
kubectl get pods
```

```bash
kubectl port-forward pod/nginx-pod 8080:80
```

### 5. Delete

```bash
kubectl delete -f pod.yaml
kubectl delete pod busybox
```

---

## Exam Tips

| Command                             | Purpose                              |
| ----------------------------------- | ------------------------------------ |
| `kubectl get pods -A`               | All pods in all namespaces           |
| `kubectl logs <pod> -c <container>` | Logs for specific container          |
| `kubectl exec <pod> -it -- <cmd>`   | Run command in pod                   |
| `--restart=Never`                   | Pod (not Deployment) – won't restart |

## Practice

1. Create a pod named `redis` using image `redis:alpine` with `kubectl run`.
2. Get logs from that pod (redis may not log much; that's ok).
