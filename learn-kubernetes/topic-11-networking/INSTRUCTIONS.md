# Topic 11: Ingress & NetworkPolicy

## What You'll Learn

- **Ingress** – HTTP routing, path-based, host-based
- **NetworkPolicy** – allow/deny pod traffic
- Ingress Controller required (nginx, traefik, etc.)

## Steps

### 1. Apply

```bash
kubectl apply -f .
kubectl get ingress
kubectl get networkpolicies
```

### 2. NetworkPolicy

```bash
kubectl describe networkpolicy allow-from-default
```

---

## Exam Tips

| Resource      | Purpose                     |
| ------------- | --------------------------- |
| Ingress       | L7 routing, TLS termination |
| NetworkPolicy | L3/L4 pod-to-pod rules      |
| policyTypes   | Ingress, Egress             |
