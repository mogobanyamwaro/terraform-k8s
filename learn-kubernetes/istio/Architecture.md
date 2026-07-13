# Architecture Reference

Control plane is **istiod**. Data plane is **Envoy** (sidecar or waypoint) plus **ztunnel** in ambient. istiod is never on the request path.

## Components

| Piece | Role | Namespace |
| --- | --- | --- |
| istiod | xDS, CA, webhooks, config translation | `istio-system` |
| istio-ingressgateway | Edge Envoy, north-south in | `istio-system` (typical) |
| istio-egressgateway | Dedicated outbound Envoy | optional |
| istio-cni | Traffic redirect without privileged init | nodes |
| ztunnel | Ambient L4 HBONE / mTLS | DaemonSet |
| waypoint | Ambient L7 Envoy | per ns/service |

Historical names still appear in docs: Pilot (xDS), Citadel (CA), Galley (validation). They are **one binary** now.

## xDS

| API | Holds | `istioctl pc` |
| --- | --- | --- |
| LDS | Listeners | `listener` |
| RDS | HTTP routes | `route` |
| CDS | Clusters | `cluster` |
| EDS | Endpoints | `endpoint` |
| SDS | Certs | `secret` |

Push: CR/Service change → istiod → gRPC `:15012` → Envoy ACK. `proxy-status` watches ACKs.

## Ports

| Port | Use |
| --- | --- |
| 15000 | Envoy admin |
| 15001 | Outbound capture |
| 15006 | Inbound capture |
| 15008 | HBONE |
| 15020 | Merged metrics `/stats/prometheus` |
| 15021 | Readiness `/healthz/ready` |
| 15010 | xDS plaintext |
| 15012 | xDS + CA mTLS |
| 15014 | istiod metrics |
| 15017 | Webhooks |
| 15090 | Raw Envoy metrics |

## Discovery

Istio watches Services, EndpointSlices, Pods, Nodes, and Istio CRs. Kubernetes DNS still resolves Services; Envoy intercepts the **connection**. Headless + `PASSTHROUGH` is a special case (`17.md`).

## Traffic flow sidecar

```text
app out -> iptables -> Envoy :15001 -> (mTLS) -> remote Envoy :15006 -> iptables -> app in
```

## Resource ownership

| Question | Resource |
| --- | --- |
| Where does this HTTP request go? | VirtualService |
| How do we talk to that host (LB, TLS, pools)? | DestinationRule |
| What exists outside kube DNS? | ServiceEntry |
| Which ports/hosts does the edge accept? | Gateway |
| Who may call me? | AuthorizationPolicy |
| What mTLS do I accept? | PeerAuthentication |
| How are JWTs validated? | RequestAuthentication |
| What does this proxy get programmed with? | Sidecar |
| Logs/metrics/traces switches | Telemetry |

See numbered files `01.md`, `05.md`, `32.md`.
