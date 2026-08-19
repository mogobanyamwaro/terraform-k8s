# Flashcards

Cover the right column. Night before and morning of.

## Meta

| Prompt | Answer |
| --- | --- |
| Format | Closed-book **MCQ**, 60 / 90 min / **75%** |
| Largest domain | **API and SDK 46%** |
| Collector / Fundamentals / Debug | **26% / 18% / 10%** |
| OTel vs Prometheus exam | **OTCA vs PCA** |

## Fundamentals

| Prompt | Answer |
| --- | --- |
| Three signals | **Traces, metrics, logs** |
| Observability vs monitoring | **New questions vs known checks** |
| Required resource | **`service.name`** |
| RED | **Rate, Errors, Duration** |
| USE | **Utilization, Saturation, Errors** |
| Auto instrumentation | **Language agent / zero-code** |
| Libraries depend on | **API (no-op)** |

## API / SDK

| Prompt | Answer |
| --- | --- |
| No SDK | **No-op** |
| Providers | **Tracer / Meter / Logger** |
| Span kind inbound HTTP | **SERVER** |
| Outbound HTTP | **CLIENT** |
| Queue send/receive | **PRODUCER / CONSUMER** |
| Prod span processor | **BatchSpanProcessor** |
| Head sampling when | **Span start** |
| Keep traces whole | **ParentBased** |
| OTLP gRPC / HTTP | **4317 / 4318** |
| W3C header | **`traceparent`** |
| Baggage auto on spans? | **No** |
| Counter | **Monotonic** |
| Latency instrument | **Histogram** |
| Java zero-code | **`-javaagent:`** |
| `OTEL_SERVICE_NAME` | **Resource service.name** |
| `OTEL_SDK_DISABLED` | **Force no-op** |

## Collector

| Prompt | Answer |
| --- | --- |
| Pipeline order | **receiver → processor → exporter** |
| Declared but unwired | **Inactive** |
| First processor | **memory_limiter** |
| Last processor | **batch** |
| Agent vs gateway | **Close to app vs central** |
| Tail sampling where | **Gateway + trace-ID affinity** |
| OTTL where | **transform processor** |
| Signals hop via | **Connector** (spanmetrics) |
| zpages | **Collector debug extension** |
| contrib vs core | **Extra components** |

## Debug

| Prompt | Answer |
| --- | --- |
| Many roots | **Propagation** |
| Console OK, backend empty | **Pipeline / endpoint** |
| Export must not | **Fail the user request** |
| Convention drift | **schema_url + transform** |
