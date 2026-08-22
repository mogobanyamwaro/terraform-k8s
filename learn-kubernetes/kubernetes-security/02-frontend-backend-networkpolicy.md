# 02. Allow Only Frontend To Backend

**Domain:** Cluster Setup

## Question

In namespace `cks-02`, only pods labeled `role=frontend` should access pods labeled `role=backend` on TCP port 8080. All other ingress traffic to backend pods must be denied.

## Answer

Create the namespace and pods:

```bash
kubectl create namespace cks-02
kubectl run frontend -n cks-02 --image=busybox:1.36 --restart=Never --labels=role=frontend -- sleep 3600
kubectl run attacker -n cks-02 --image=busybox:1.36 --restart=Never --labels=role=attacker -- sleep 3600
kubectl create deployment backend -n cks-02 --image=nginx:1.27
kubectl label deployment backend -n cks-02 role=backend
kubectl expose deployment backend -n cks-02 --port=8080 --target-port=80 --name=backend
```

Create the policy:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: cks-02
spec:
  podSelector:
    matchLabels:
      role: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 8080
```

Apply it:

```bash
kubectl apply -f allow-frontend-to-backend.yaml
```

## Verify

Frontend should work:

```bash
kubectl exec -n cks-02 frontend -- wget -T 3 -qO- http://backend:8080
```

Attacker should fail:

```bash
kubectl exec -n cks-02 attacker -- wget -T 3 -qO- http://backend:8080
```

## Exam tips

- The `podSelector` at the top chooses the protected destination pods.
- The `from` section chooses allowed source pods.
- If a pod is selected by any ingress NetworkPolicy, ingress becomes deny-by-default except allowed rules.

