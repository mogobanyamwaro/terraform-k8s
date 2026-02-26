# Topic 12: kubectl & Debugging (Troubleshooting)

## CKA Troubleshooting Focus

### 1. Pod not starting

```bash
kubectl describe pod <name>
kubectl logs <pod> -c <container>
kubectl get events --sort-by='.lastTimestamp'
```

### 2. Service not routing

```bash
kubectl get endpoints
kubectl get svc
# Check selector matches pod labels
```

### 3. Node issues

```bash
kubectl get nodes
kubectl describe node <name>
kubectl get pods -o wide
```

### 4. Debug in cluster

```bash
# Run ephemeral debug pod
kubectl run debug --image=busybox --restart=Never -it --rm -- sh
# Inside: nslookup kubernetes.default
#         wget -qO- http://service-name
```

### 5. Copy files

```bash
kubectl cp <pod>:/path/file ./local-file
kubectl cp ./local-file <pod>:/path/
```

### 6. Common fixes

```bash
# Restart deployment
kubectl rollout restart deployment/<name>

# Cordon/uncordon node
kubectl cordon <node>
kubectl uncordon <node>

# Drain node (evict pods)
kubectl drain <node> --ignore-daemonsets
```

---

## Exam Tips

| Command              | Use                     |
| -------------------- | ----------------------- |
| `kubectl describe`   | Detailed status, events |
| `kubectl logs -f`    | Follow logs             |
| `kubectl get events` | Cluster events          |
| `kubectl debug`      | Node/pod debugging      |
