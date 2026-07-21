# 03. Allow Egress Only To DNS And API Server

**Domain:** Cluster Setup

## Question

In namespace `cks-03`, apply egress restrictions so application pods can resolve DNS and connect to the Kubernetes API server, but cannot call arbitrary external IPs.

## Answer

Create the namespace:

```bash
kubectl create namespace cks-03
kubectl run app -n cks-03 --image=busybox:1.36 --restart=Never --labels=app=restricted -- sleep 3600
```

Find the Kubernetes service IP:

```bash
kubectl get svc kubernetes -n default
```

Find the CoreDNS service IP and namespace labels:

```bash
kubectl get svc kube-dns -n kube-system
kubectl get namespace kube-system --show-labels
```

Most clusters have the namespace label `kubernetes.io/metadata.name=kube-system`.

Create the policy:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-and-api-egress
  namespace: cks-03
spec:
  podSelector:
    matchLabels:
      app: restricted
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
  - to:
    - ipBlock:
        cidr: 10.96.0.1/32
    ports:
    - protocol: TCP
      port: 443
```

Important: replace `10.96.0.1/32` with the real ClusterIP of the `kubernetes` service in your cluster.

Apply:

```bash
kubectl apply -f allow-dns-and-api-egress.yaml
```

## Verify

DNS should work:

```bash
kubectl exec -n cks-03 app -- nslookup kubernetes.default.svc.cluster.local
```

API service should connect:

```bash
kubectl exec -n cks-03 app -- wget -T 3 --spider https://kubernetes.default.svc
```

External access should fail:

```bash
kubectl exec -n cks-03 app -- wget -T 3 -qO- http://example.com
```

## Exam tips

- Egress deny starts when a pod is selected by an egress NetworkPolicy.
- DNS needs UDP 53 and sometimes TCP 53.
- `namespaceSelector` plus `podSelector` in the same item means both must match.

