# Signals (Deep Dive)

Traces, metrics, logs. Spec: [opentelemetry.io/docs/concepts/signals](https://opentelemetry.io/docs/concepts/signals/).

## Traces

- Trace = spans with one `trace_id`
- Span: name, context, parent, kind, status, attributes, events, links, times
- Kind: INTERNAL, SERVER, CLIENT, PRODUCER, CONSUMER
- Status: UNSET, OK, ERROR

## Metrics

| Instrument | Use |
| --- | --- |
| Counter | Monotonic |
| UpDownCounter | Bidirectional |
| Histogram | Distribution (latency) |
| Gauge / ObservableGauge | Last value / async |
| ObservableCounter / UpDown | Async collect |

Temporality: **cumulative** vs **delta**. Cardinality kills metric backends.

## Logs

LogRecord + **Logs Bridge**. Attach `trace_id` when a span is current. Collector `filelog` is **not** the SDK.

## Resource vs attributes vs scope

- Resource: `service.name` (required for services)
- Signal attributes: this operation/point
- Instrumentation scope: library identity

## Correlation

Same `trace_id` on spans, log records, and metric exemplars.
