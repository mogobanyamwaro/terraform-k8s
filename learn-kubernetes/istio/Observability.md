# Observability Reference

## Telemetry API

```yaml
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  accessLogging:
    - providers: [{ name: envoy }]
  metrics:
    - providers: [{ name: prometheus }]
  tracing:
    - randomSamplingPercentage: 100
```

Override per namespace/workload.

## Ports

15020 merged Prometheus, 15090 raw Envoy.

## Metrics

`istio_requests_total`, `istio_request_duration_milliseconds`, reporter `source`/`destination`.

## Addons

`kubectl apply -f samples/addons` → Prometheus, Grafana, Kiali, Jaeger. Exam may not include dashboards; logs + `pc` always exist.

## Tracing

Header propagation (B3/W3C) is automatic through Envoy. Sampling via Telemetry. Provider must be in MeshConfig `extensionProviders`.

File: `34.md`.
