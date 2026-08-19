# Collector (Deep Dive)

YAML pipelines. Docs: [opentelemetry.io/docs/collector](https://opentelemetry.io/docs/collector/).

```yaml
receivers:
  otlp:
    protocols: { grpc: {}, http: {} }
processors:
  memory_limiter: { check_interval: 1s, limit_percentage: 75 }
  batch: {}
exporters:
  otlp: { endpoint: tempo:4317, tls: { insecure: true } }
  debug: { verbosity: basic }
extensions:
  health_check: {}
  zpages: { endpoint: 0.0.0.0:55679 }
service:
  extensions: [health_check, zpages]
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlp, debug]
```

**Order:** memory_limiter → …transform/filter… → batch.

**Declared ≠ wired.**

**Agent** (sidecar/DaemonSet) vs **gateway** (Deployment). Tail sampling + OTTL on gateway. Trace-ID load balancing for stateful processors.

**Connectors** hop signals. **contrib** vs **core** images.

OTTL lives in `transform`. `k8sattributes` / `resourcedetection` enrich.
