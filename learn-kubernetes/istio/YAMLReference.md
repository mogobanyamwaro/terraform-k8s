# YAML Skeletons

Copy, change names, apply. `apiVersion` `networking.istio.io/v1` and `security.istio.io/v1` unless the cluster is old.

## Gateway + VirtualService (HTTP ingress)

```yaml
apiVersion: networking.istio.io/v1
kind: Gateway
metadata: { name: app-gw, namespace: APPNS }
spec:
  selector: { istio: ingressgateway }
  servers:
    - port: { number: 80, name: http, protocol: HTTP }
      hosts: ["app.example.com"]
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata: { name: app, namespace: APPNS }
spec:
  hosts: ["app.example.com"]
  gateways: [app-gw]
  http:
    - route:
        - destination: { host: APP, port: { number: 80 } }
```

## HTTPS SIMPLE

```yaml
      tls:
        mode: SIMPLE
        credentialName: app-tls
```

Secret in `istio-system`.

## Subsets + weights

```yaml
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata: { name: APP, namespace: APPNS }
spec:
  host: APP
  subsets:
    - { name: v1, labels: { version: v1 } }
    - { name: v2, labels: { version: v2 } }
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata: { name: APP, namespace: APPNS }
spec:
  hosts: [APP]
  http:
    - route:
        - { destination: { host: APP, subset: v1 }, weight: 90 }
        - { destination: { host: APP, subset: v2 }, weight: 10 }
```

## Timeout / retry / fault / mirror

```yaml
    - timeout: 2s
      retries: { attempts: 3, perTryTimeout: 1s, retryOn: "5xx,connect-failure" }
      fault:
        delay: { percentage: { value: 100.0 }, fixedDelay: 1s }
        abort: { percentage: { value: 10.0 }, httpStatus: 500 }
      mirror: { host: APP, subset: v2 }
      mirrorPercentage: { value: 100.0 }
      route:
        - destination: { host: APP, subset: v1 }
```

## ServiceEntry

```yaml
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata: { name: ext, namespace: APPNS }
spec:
  hosts: [httpbin.org]
  ports: [{ number: 80, name: http, protocol: HTTP }]
  location: MESH_EXTERNAL
  resolution: DNS
```

## Sidecar

```yaml
apiVersion: networking.istio.io/v1
kind: Sidecar
metadata: { name: default, namespace: APPNS }
spec:
  egress:
    - hosts: ["./*", "istio-system/*"]
  outboundTrafficPolicy: { mode: REGISTRY_ONLY }
```

## PeerAuthentication

```yaml
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata: { name: default, namespace: APPNS }
spec:
  mtls: { mode: STRICT }
```

## RequestAuthentication + ALLOW JWT

```yaml
apiVersion: security.istio.io/v1
kind: RequestAuthentication
metadata: { name: httpbin, namespace: APPNS }
spec:
  selector: { matchLabels: { app: httpbin } }
  jwtRules:
    - issuer: "ISS"
      jwksUri: "https://..."
---
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata: { name: httpbin-jwt, namespace: APPNS }
spec:
  selector: { matchLabels: { app: httpbin } }
  action: ALLOW
  rules:
    - from: [{ source: { requestPrincipals: ["*"] } }]
```

## AuthorizationPolicy ALLOW SA

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata: { name: httpbin, namespace: APPNS }
spec:
  selector: { matchLabels: { app: httpbin } }
  action: ALLOW
  rules:
    - from:
        - source:
            principals: ["cluster.local/ns/APPNS/sa/sleep"]
      to:
        - operation: { methods: ["GET"], paths: ["/get"] }
```

## Telemetry logs

```yaml
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata: { name: logs, namespace: istio-system }
spec:
  accessLogging:
    - providers: [{ name: envoy }]
```

## Waypoint (Gateway API)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata: { name: waypoint, namespace: APPNS }
spec:
  gatewayClassName: istio-waypoint
  listeners:
    - { name: mesh, port: 15008, protocol: HBONE }
```
