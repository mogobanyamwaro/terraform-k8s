# Gateway API Reference

Kubernetes Gateway API is first-class in Istio 1.26+. ICA may use it for ingress and **requires** it for ambient waypoints.

## Ingress

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: shop
  namespace: shop
spec:
  gatewayClassName: istio
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      hostname: shop.example.com
      allowedRoutes:
        namespaces:
          from: Same
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: shop
  namespace: shop
spec:
  parentRefs:
    - name: shop
  hostnames: ["shop.example.com"]
  rules:
    - matches:
        - path: { type: PathPrefix, value: / }
      backendRefs:
        - name: frontend
          port: 80
```

`gatewayClassName: **istio**` for north-south. Istio creates a Deployment/Service for the Gateway.

TLS: `listeners.tls.certificateRefs` to a Secret in the Gateway namespace (ReferenceGrant if cross-ns).

## Weighted canary

`backendRefs` with `weight`.

## Waypoint

`gatewayClassName: **istio-waypoint**`, listener protocol `HBONE` port 15008. See `Ambient.md`.

## Mixing

You can still attach Istio VirtualService to a Gateway API Gateway in some versions; prefer HTTPRoute when the task says Gateway API.

Install CRDs if missing (`Lab-Setup.md`).

File: `05.md`, `08.md`.
