# Gateway Reference

Two objects share the English word "gateway":

1. **Workloads** `istio-ingressgateway` / `istio-egressgateway` — Envoy Deployments.
2. **CRD** `Gateway` (`networking.istio.io`) — which ports/hosts/TLS those Envoys accept.

Kubernetes **Gateway API** (`gateway.networking.k8s.io`) is the newer CRD. Istio implements it (`GatewayAPI.md`). ICA still tests the Istio Gateway CR heavily.

## Istio Gateway

```yaml
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: shop
  namespace: shop
spec:
  selector:
    istio: ingressgateway
  servers:
    - port: { number: 80, name: http, protocol: HTTP }
      hosts: ["shop.example.com"]
```

- `selector` matches **pod labels**, default `istio=ingressgateway`.
- `port.name` prefix must match protocol (`http`, `https`, `tls`, `tcp`, `grpc`, `http2`, `mongo`, `redis`, `mysql`).
- VirtualService `spec.gateways` must list this Gateway; `hosts` must **intersect**.
- Cross-namespace: `gateways: ["istio-system/my-gw"]`.

## Bind VS

```yaml
spec:
  hosts: ["shop.example.com"]
  gateways:
    - shop          # same ns
    - mesh          # also east-west
```

Omit `gateways` → `[mesh]` only → ingress 404.

## TLS

See `TLS.md` / `27.md`. `credentialName` Secret is in the **gateway pod namespace**.

## Egress

`selector: istio: egressgateway` plus the four-object recipe (`15.md`).

## Get the VIP

```bash
kubectl -n istio-system get svc istio-ingressgateway
export INGRESS_HOST=$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

Files: `08.md`, `15.md`, `27.md`.
