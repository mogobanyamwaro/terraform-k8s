# Architecture (Deep Dive)

API, SDK, Collector, backends. Docs: [opentelemetry.io](https://opentelemetry.io/docs/).

```text
App  (API no-op until SDK/agent)
  SDK: sampler → processors → OTLP exporter
           |
        OTLP 4317/4318
           |
Collector agent  (optional, node/sidecar)
           |
Collector gateway  (batch, tail sample, OTTL, fan-out)
           |
   Tempo/Jaeger | Prometheus/Mimir | Loki/vendor
```

| Piece | Process | Config |
| --- | --- | --- |
| API | In-process | None (no-op) |
| SDK / language agent | In-process | `OTEL_*` |
| Collector | Separate | YAML pipelines |
| Backend | Separate | Product-specific |

**Signals** do not hop unless a **connector** (spanmetrics) or you dual-export.

**Two agents:** Javaagent (instrument) vs Collector agent (pipeline).

OTCA does **not** test building a custom Collector component. It tests **where data flows**.
