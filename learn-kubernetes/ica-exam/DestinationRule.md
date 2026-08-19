# DestinationRule Reference

**How** to talk to a host after the VS picks it.

```yaml
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: reviews
  namespace: bookinfo
spec:
  host: reviews
  exportTo: ["*"]
  trafficPolicy:
    loadBalancer: { simple: LEAST_REQUEST }
    connectionPool:
      tcp: { maxConnections: 100, connectTimeout: 30ms }
      http:
        http1MaxPendingRequests: 10
        http2MaxRequests: 10
        maxRequestsPerConnection: 1
        maxRetries: 3
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 10s
      baseEjectionTime: 30s
      maxEjectionPercent: 10
      minHealthPercent: 0
    tls: { mode: ISTIO_MUTUAL }
    portLevelSettings:
      - port: { number: 9080 }
        tls: { mode: ISTIO_MUTUAL }
  subsets:
    - name: v1
      labels: { version: v1 }
    - name: v2
      labels: { version: v2 }
      trafficPolicy:
        loadBalancer: { simple: ROUND_ROBIN }
```

## Subsets

Referenced by VS `destination.subset`. **Undefined subset = 503 NR**, not a webhook error.

Subset `trafficPolicy` **replaces** parent (does not merge).

## tls.mode

`DISABLE` | `SIMPLE` | `MUTUAL` | `ISTIO_MUTUAL`

Client side. PeerAuthentication is server side (`23.md`).

## loadBalancer

`simple`: `LEAST_REQUEST` (default), `ROUND_ROBIN`, `RANDOM`, `PASSTHROUGH`

`consistentHash`: header, cookie, source IP, query param (`17.md`)

`localityLbSetting`: distribute / failover + **outlierDetection required for failover** (`21.md`)

## Host

Same namespace short name, or FQDN, or ServiceEntry host.

Files: `11.md`, `17.md`, `19.md`, `21.md`.
