# OTCA Lab Setup

The exam is closed-book. One local Collector plus a tiny instrumented app makes OTLP and YAML obvious.

Needs: Docker (or a binary Collector), optional Python/Go/Java for SDK labs.

## Collector (OTLP in, debug out)

Save as `otel-collector.yaml`:

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
processors:
  batch:
exporters:
  debug:
    verbosity: detailed
extensions:
  health_check:
  zpages:
    endpoint: 0.0.0.0:55679
service:
  extensions: [health_check, zpages]
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug]
    logs:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug]
```

```bash
docker run --rm -p 4317:4317 -p 4318:4318 -p 55679:55679 \
  -v "$PWD/otel-collector.yaml:/etc/otelcol/config.yaml" \
  otel/opentelemetry-collector:latest
```

zpages: [http://localhost:55679/debug/tracez](http://localhost:55679/debug/tracez)

## App → OTLP (no Collector)

Many languages dump to console with env only:

```bash
export OTEL_SERVICE_NAME=demo
export OTEL_TRACES_EXPORTER=console
export OTEL_METRICS_EXPORTER=console
# or send to Collector:
export OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318
export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
```

Java zero-code: attach the OpenTelemetry Java agent JAR (`-javaagent:`) with the same `OTEL_*` variables.

## What to notice

- `service.name` appears as a **resource** attribute.
- A SERVER span and a CLIENT span share a **trace_id** when W3C `traceparent` is forwarded.
- Collector `debug` exporter prints the same data the backend would have received.

Do not spend OTCA prep writing a custom Collector component in Go. **Read YAML pipelines** and **SDK env/config**.
