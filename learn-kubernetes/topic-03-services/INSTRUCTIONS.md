# Topic 3: Services

## What You'll Learn

- **ClusterIP** – internal only (default)
- **NodePort** – exposes on each node's IP
- **LoadBalancer** – cloud LB (if supported)
- `kubectl expose`, `kubectl get svc`

## Steps

### 1. Apply

```bash
kubectl apply -f .
```

### 2. Inspect

```bash
kubectl get svc
kubectl describe svc nginx-clusterip
```

### 3. Test (from another pod)

```bash
kubectl run test --image=busybox --restart=Never --rm -it -- wget -qO- http://nginx-clusterip.exam-ns.svc.cluster.local
```

### 4. Imperative expose

```bash
kubectl expose deployment nginx --port=80 --type=NodePort --name=nginx-exposed
```

### 5. Delete

```bash
kubectl delete -f .
```

---

## Exam Tips

| Type                                    | Use                              |
| --------------------------------------- | -------------------------------- |
| ClusterIP                               | Internal cluster traffic         |
| NodePort                                | External access via node IP:port |
| LoadBalancer                            | Cloud load balancer              |
| `kubectl expose deployment X --port=80` | Create service from deployment   |

## Practice

1. Expose the nginx deployment as NodePort using `kubectl expose`.
2. Run `kubectl get endpoints` – what do you see?
