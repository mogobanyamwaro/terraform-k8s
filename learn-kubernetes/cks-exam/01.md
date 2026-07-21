# 01. Default Deny NetworkPolicy

**Domain:** Cluster Setup

## Question

In namespace `cks-01`, deny all ingress and egress traffic for every pod. Then verify that the namespace is isolated.

## Answer

Create the namespace:

```bash
kubectl create namespace cks-01
```

Create a default-deny policy:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: cks-01
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

Apply it:

```bash
kubectl apply -f default-deny-all.yaml
```

Create two test pods:

```bash
kubectl run web -n cks-01 --image=nginx:1.27 --restart=Never
kubectl run client -n cks-01 --image=busybox:1.36 --restart=Never -- sleep 3600
kubectl wait --for=condition=Ready pod/web -n cks-01 --timeout=60s
kubectl wait --for=condition=Ready pod/client -n cks-01 --timeout=60s
```

Try to connect:

```bash
WEB_IP=$(kubectl get pod web -n cks-01 -o jsonpath='{.status.podIP}')
kubectl exec -n cks-01 client -- wget -T 3 -qO- http://$WEB_IP
```

Expected result: timeout or failure.

## Verify

```bash
kubectl get networkpolicy -n cks-01
kubectl describe networkpolicy default-deny-all -n cks-01
```

The policy should select all pods and include both `Ingress` and `Egress`.

## Exam tips

- An empty `podSelector: {}` selects every pod in the namespace.
- A policy with `policyTypes: [Ingress, Egress]` and no allow rules blocks both directions.
- NetworkPolicy only works if the CNI plugin enforces it.

