# 04. Restrict Ingress Across Namespaces

**Domain:** Cluster Setup

## Question

In namespace `payments`, allow ingress to pods labeled `app=api` only from pods in namespace `frontend` labeled `app=web`. Deny all other ingress.

## Answer

Create namespaces:

```bash
kubectl create namespace payments
kubectl create namespace frontend
```

Create labels if your cluster version does not already add the namespace name label:

```bash
kubectl label namespace frontend kubernetes.io/metadata.name=frontend --overwrite
kubectl label namespace payments kubernetes.io/metadata.name=payments --overwrite
```

Create sample pods:

```bash
kubectl run api -n payments --image=nginx:1.27 --labels=app=api --restart=Never
kubectl run web -n frontend --image=busybox:1.36 --labels=app=web --restart=Never -- sleep 3600
kubectl run blocked -n frontend --image=busybox:1.36 --labels=app=blocked --restart=Never -- sleep 3600
```

Create the NetworkPolicy in the destination namespace:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-web-to-api
  namespace: payments
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend
      podSelector:
        matchLabels:
          app: web
    ports:
    - protocol: TCP
      port: 80
```

Apply it:

```bash
kubectl apply -f allow-frontend-web-to-api.yaml
```

## Verify

```bash
API_IP=$(kubectl get pod api -n payments -o jsonpath='{.status.podIP}')
kubectl exec -n frontend web -- wget -T 3 -qO- http://$API_IP
kubectl exec -n frontend blocked -- wget -T 3 -qO- http://$API_IP
```

The `web` pod should connect. The `blocked` pod should fail.

## Exam tips

- NetworkPolicy is namespace-scoped.
- Create ingress policies in the namespace of the destination pod.
- Separate `from` list items are OR conditions. Selectors inside the same item are AND conditions.

