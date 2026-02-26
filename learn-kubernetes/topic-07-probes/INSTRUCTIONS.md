# Topic 7: Probes

## What You'll Learn

- **livenessProbe** – if fails, pod is restarted
- **readinessProbe** – if fails, pod removed from Service endpoints
- Types: httpGet, tcpSocket, exec

## Steps

### 1. Apply

```bash
kubectl apply -f pod.yaml
kubectl describe pod probe-pod
```

### 2. Check probe status

```bash
kubectl get pod probe-pod -o yaml | grep -A 20 "livenessProbe"
```

---

## Exam Tips

| Probe          | Effect of failure                |
| -------------- | -------------------------------- |
| livenessProbe  | Restart container                |
| readinessProbe | Remove from Service (no traffic) |
| startupProbe   | Delay liveness until success     |

## Practice

1. Add an exec probe that runs `cat /tmp/ready` (create file for success).
2. Change readiness path to `/nonexistent` and observe pod behavior.
