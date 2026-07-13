# ServiceEntry Reference

Register non-Kubernetes (or extra) services in Istio's registry.

```yaml
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: httpbin-ext
  namespace: demo
spec:
  hosts: [httpbin.org]
  addresses: []
  ports:
    - number: 80
      name: http
      protocol: HTTP
  location: MESH_EXTERNAL
  resolution: DNS
  endpoints: []
  exportTo: ["*"]
  subjectAltNames: []
  workloadSelector: {}
```

## location

`MESH_EXTERNAL` — outside, no auto mTLS.
`MESH_INTERNAL` — treat as mesh service.

## resolution

`NONE` passthrough, `STATIC` use `endpoints`, `DNS`, `DNS_ROUND_ROBIN`.

## outboundTrafficPolicy

`ALLOW_ANY` (default): unknown hosts use `PassthroughCluster`.
`REGISTRY_ONLY`: unknown → `BlackHoleCluster`. Then every egress host needs a ServiceEntry.

## WorkloadEntry

```yaml
apiVersion: networking.istio.io/v1
kind: WorkloadEntry
metadata: { name: vm1, namespace: vm }
spec:
  address: 10.9.1.2
  labels: { app: legacy }
  serviceAccount: legacy
```

ServiceEntry `workloadSelector.matchLabels.app: legacy` publishes it as a service.

## TLS origination

SE + DestinationRule `tls.mode: SIMPLE` + app speaks HTTP. If app already uses HTTPS, protocol `TLS`/`HTTPS` and usually `DISABLE` extra origination.

Files: `14.md`, `15.md`.
