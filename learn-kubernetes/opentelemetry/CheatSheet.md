# Exam-Day Cheat Sheet

Last page before OTCA. Closed book. **90 minutes, 60 questions, 75% (45/60).**

## Exam Facts

| | |
| --- | --- |
| Name | OpenTelemetry Certified Associate (OTCA) |
| Format | Multiple choice, PSI |
| Docs | **None** |
| Focus | **API vs SDK, signals, Collector YAML, OTLP** |

| Domain | Weight | ~Q |
| --- | ---: | ---: |
| **API and SDK** | **46%** | ~28 |
| Collector | 26% | ~16 |
| Fundamentals | 18% | ~11 |
| Debug pipelines | 10% | ~6 |

## Split brain

```text
In the app?     API/SDK/agent/OTEL_* / head sampler / W3C
After the app?  Collector YAML: recv → proc → exp
Broken parent?  traceparent / context / ParentBased
```

## SDK env

```text
OTEL_SERVICE_NAME
OTEL_RESOURCE_ATTRIBUTES=k=v,k2=v2
OTEL_TRACES_EXPORTER=otlp|console|none
OTEL_EXPORTER_OTLP_ENDPOINT=...
OTEL_EXPORTER_OTLP_PROTOCOL=grpc|http/protobuf
OTEL_TRACES_SAMPLER=parentbased_traceidratio
OTEL_TRACES_SAMPLER_ARG=0.1
OTEL_PROPAGATORS=tracecontext,baggage
OTEL_SDK_DISABLED=true   # silence
```

4317 gRPC · 4318 HTTP

## Span kinds / instruments

SERVER CLIENT INTERNAL PRODUCER CONSUMER  
Counter ↑ · UpDown ↔ · Histogram latency · Observable async

## Collector sketch

```yaml
service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlp]
```

Agent = sidecar/DaemonSet. Gateway = Deployment. Tail sample on gateway. OTTL = `transform`. Connector hops signals.

## W3C

`traceparent: 00-<trace>-<span>-<flags>`  
Baggage ≠ span attributes. No secrets.

## Don’t

- Crash requests on export failure  
- Tail-sample on random replicas  
- Put `user_id` on metrics  
- Confuse Javaagent with Collector  
- Confuse OTCA with PCA (PromQL)
