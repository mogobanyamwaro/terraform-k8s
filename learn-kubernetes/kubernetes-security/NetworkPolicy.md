# NetworkPolicy CKS Notes

NetworkPolicy controls pod traffic at Layer 3 and Layer 4.

It is a major CKS topic because segmentation limits blast radius after compromise.

## Mental Model

```text
spec.podSelector = destination pods protected by this policy
ingress.from     = allowed sources
egress.to        = allowed destinations
ports            = allowed ports
```

For egress policies:

```text
spec.podSelector = source pods restricted by this policy
egress.to        = allowed destinations
```

## Default Deny All

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: secure
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

## Allow Same Namespace App To App

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-api
  namespace: secure
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

## Allow Cross Namespace

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-namespace
  namespace: api
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
          kubernetes.io/metadata.name: web
      podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
```

## Allow DNS Egress

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: secure
spec:
  podSelector: {}
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
```

## Test Commands

Create client:

```bash
kubectl run client -n secure --image=busybox:1.36 --restart=Never -- sleep 3600
```

Test HTTP:

```bash
kubectl exec -n secure client -- wget -T 3 -qO- http://service-name:80
```

Test DNS:

```bash
kubectl exec -n secure client -- nslookup kubernetes.default
```

## Common Mistakes

- Creating the policy in the wrong namespace.
- Forgetting egress DNS after default-deny egress.
- Confusing source and destination selectors.
- Using separate `from` entries when you meant namespace AND pod selector together.

## Exam tips

- NetworkPolicy enforcement depends on the CNI.
- Policies are additive. One allow policy cannot deny what another allows.
- Empty `podSelector` selects all pods in the policy namespace.

