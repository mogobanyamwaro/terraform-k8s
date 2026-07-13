# Ambient Reference

Ambient = sidecarless mesh. GA since 1.24. ICA tests the split between **ztunnel (L4)** and **waypoints (L7)**.

## Enable

```bash
istioctl install --set profile=ambient -y
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
kubectl label ns shop istio.io/dataplane-mode=ambient
```

Pods stay **1/1**. No restart required to enrol (unlike sidecars).

## ztunnel

DaemonSet, Rust, HBONE on **15008**, mTLS, L4 AuthorizationPolicy (principals, IPs, ports), TCP telemetry.

```bash
kubectl -n istio-system get ds ztunnel
istioctl ztunnel-config workload
istioctl ztunnel-config certificate
```

## Waypoints

```bash
istioctl waypoint apply -n shop
istioctl waypoint apply -n shop --name reviews --for service
kubectl label svc reviews -n shop istio.io/use-waypoint=waypoint
kubectl label ns shop istio.io/use-waypoint=waypoint
istioctl waypoint list
```

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: waypoint
  namespace: shop
spec:
  gatewayClassName: istio-waypoint
  listeners:
    - name: mesh
      port: 15008
      protocol: HBONE
```

Without this, VirtualService timeouts/retries/faults/HTTP authz **do nothing**.

## Labels

| Label | Meaning |
| --- | --- |
| `istio.io/dataplane-mode=ambient` | Enrol ns/pod |
| `istio.io/dataplane-mode=none` | Opt out a pod |
| `istio.io/use-waypoint=<name>` | Send L7 to waypoint |
| `istio.io/waypoint-for` | service \| workload \| all |

Never combine with `istio-injection=enabled`.

## vs sidecar

| | Sidecar | Ambient |
| --- | --- | --- |
| Enrol restart | yes | no |
| L7 always on | yes | only with waypoint |
| Debug app pod | `pc` on pod | `ztunnel-config` / waypoint `pc` |

Files: `05.md`, `36.md`.
