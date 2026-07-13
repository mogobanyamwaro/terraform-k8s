# Mock Exam 2

Timer: **90 minutes**. 60 questions. Closed book. Passing simulation: **45/60**. Harder distractors than Mock 1.

Same mix: API/SDK ~27, Collector ~16, Fundamentals ~11, Debug ~6.

Mark answers on paper. Key at the end.

---

**1.** Baggage is:  
A. A fourth OTel **signal** equal to logs  
B. Propagated key/value **context**, not a signal  
C. The batch processor  
D. Required Resource field  

**2.** `schema_url` on a Resource:  
A. The Collector image tag  
B. Which semantic-convention **generation** produced the data  
C. `app.baseUrl`  
D. W3C `traceparent`  

**3.** Auto + manual wrapping the same HTTP handler:  
A. Always illegal  
B. Can duplicate spans; check suppression/parenting  
C. Required  
D. Disables OTLP  

**4.** Head sampling at 1% and rare 500s:  
A. Guarantees every 500 is stored  
B. May miss errors unless tail/error-aware sampling  
C. Disables metrics  
D. Replaces conventions  

**5.** `service.name` vs span `name`:  
A. Identical  
B. Resource identity vs operation name  
C. Both are Samplers  
D. Both are OTLP ports  

**6.** Exemplars / trace_id on metrics help:  
A. Compress YAML  
B. Jump from a RED alert to a trace  
C. Set span kind  
D. Open zpages  

**7.** Inventing `mycompany.httpverb` instead of HTTP conventions:  
A. Required  
B. Breaks shared processors/dashboards  
C. Faster OTLP  
D. Disables the SDK  

**8.** Monitoring “disk > 90%” is:  
A. Full observability  
B. A known-check (monitoring); traces still help unknown latency  
C. A span kind  
D. OTTL  

**9.** Profiles in the OTel ecosystem:  
A. Replace traces on OTCA  
B. Emerging; exam core is still traces/metrics/logs  
C. A Collector exporter name only  
D. W3C baggage  

**10.** Push OTLP vs Prometheus pull:  
A. OTel apps typically push; Prometheus classically pulls (Collector can do both)  
B. OTel forbids pull  
C. Prometheus forbids OTLP  
D. Identical always  

**11.** Instrumentation best practice:  
A. Only eBPF  
B. API + conventions + auto libraries + manual business spans  
C. Only `kubectl logs`  
D. Only PCA exporters  

**12.** `OTEL_EXPORTER_OTLP_ENDPOINT=http://otel:4317` with `http/protobuf`:  
A. Always correct  
B. Port/protocol mismatch risk  
C. Required for logs  
D. Disables the API  

**13.** `start_span` without making it current:  
A. Identical to `start_as_current_span`  
B. Children may not nest unless you pass the parent context  
C. Only metrics  
D. Only logs  

**14.** Forgetting `end()` :  
A. Required for metrics  
B. Span may never export  
C. Sets status OK  
D. Rotates trace_id  

**15.** PRODUCER vs CONSUMER:  
A. Metric instruments  
B. Messaging send vs receive  
C. gRPC vs HTTP ports  
D. Head vs tail  

**16.** HTTP 500 should:  
A. Change `trace_id`  
B. Set span status ERROR (plus status-code attributes)  
C. Disable MeterProvider  
D. Switch to UDP  

**17.** UpDownCounter is for:  
A. Monotonic request counts  
B. Values that go up and down (in-flight, queue depth)  
C. Stack traces  
D. Baggage  

**18.** Unbounded attributes on a Counter:  
A. Required  
B. Cardinality explosion  
C. How histograms work  
D. How Observables work  

**19.** Metric views can:  
A. Rewrite W3C headers  
B. Drop/rename/change aggregation  
C. Start the Java agent  
D. Open zpages  

**20.** `filelog` vs Logs SDK:  
A. Identical  
B. filelog tails files; SDK/bridge emits from the process  
C. filelog is the Java agent  
D. SDK tails /var/log only  

**21.** `OTEL_LOGS_EXPORTER=none`:  
A. Crashes log4j  
B. Disables OTel log **export** (local logging may continue)  
C. Disables traces  
D. Forces cumulative metrics  

**22.** Multiple trace exporters (`otlp,console`):  
A. Illegal  
B. SDK fan-out  
C. Requires two trace_ids per span  
D. Disables the API  

**23.** Batch queue full:  
A. Crashes Kubernetes  
B. Drop or backpressure — possible data loss  
C. Converts traces to metrics  
D. Rotates `service.name`  

**24.** Sampler in SDK vs Collector `tail_sampling`:  
A. Identical stage  
B. Head at start vs decision after the trace completes  
C. Both are Javaagents  
D. Both are W3C headers  

**25.** `always_off` still:  
A. Cannot propagate context  
B. Can inject `traceparent` (downstream sampling depends on ParentBased)  
C. Crashes the API  
D. Forces console  

**26.** Putting a session token in baggage:  
A. Recommended  
B. Leaks to every downstream  
C. Required by `service.name`  
D. How OTLP auth works  

**27.** `tracestate` is:  
A. A replacement for `trace_id`  
B. Vendor key=values beside W3C traceparent  
C. Log severity  
D. Histogram buckets  

**28.** Async worker new root:  
A. Always correct  
B. Often lost context  
C. Wrong OTLP port always  
D. Missing `service.name` always  

**29.** Go + `-javaagent`:  
A. The usual Go attach  
B. Wrong language; Go is not a JVM agent  
C. Required  
D. Sets delta temporality  

**30.** Operator Instrumentation vs Collector CR:  
A. Identical  
B. Instrumentation injects app agent/env; Collector CR runs the pipeline  
C. Both are span kinds  
D. Both are PromQL  

**31.** SimpleSpanProcessor in prod:  
A. Ideal  
B. Per-span export overhead; use Batch  
C. Required for OTLP  
D. Replaces Resource  

**32.** `OTEL_RESOURCE_ATTRIBUTES`:  
A. Invalid  
B. Extra resource attributes (`k=v,k=v`)  
C. Collector processors  
D. Span events  

**33.** Delta temporality:  
A. Illegal with OTLP  
B. Change since last collection/export  
C. Resource-only  
D. Always 4317  

**34.** `MeterProvider` is to metrics as:  
A. `debug` exporter is to traces  
B. `TracerProvider` is to traces  
C. `traceparent` is to baggage  
D. OTTL is to conventions  

**35.** Span **links** are for:  
A. HTML  
B. Non-parent causal relations (batch/fan-in)  
C. YAML anchors  
D. zpages  

**36.** Resource vs instrumentation scope:  
A. Identical  
B. Process/service vs library that created the signal  
C. Scope replaces `trace_id`  
D. Resource is logs-only  

**37.** `OTEL_TRACES_SAMPLER_ARG=0.1` without a ratio sampler:  
A. Always tail-samples  
B. Ignored/meaningless unless the sampler uses it  
C. Sets `service.version`  
D. Opens 4318  

**38.** Mixing B3 and W3C without configuring both ends:  
A. Ideal  
B. Broken or duplicate context  
C. Required  
D. How baggage works  

**39.** Processor order `filter` then `transform` vs reverse:  
A. YAML is sorted at runtime so order never matters  
B. Each step sees the previous output — order matters  
C. Receivers ignore processors  
D. OTLP forbids processors  

**40.** Pipeline name `traces/2`:  
A. Invalid  
B. Second traces pipeline instance  
C. SDK tail sampling  
D. W3C v2  

**41.** `prometheusremotewrite` on traces:  
A. Ideal  
B. Wrong signal  
C. Auto-converts spans  
D. Sets ParentBased  

**42.** Sidecar Collector + tail sampling:  
A. Always sees the whole mesh trace  
B. Usually incomplete; tail-sample at a gateway  
C. Required  
D. Replaces `batch`  

**43.** DaemonSet scaling for heavy OTTL:  
A. Add more DaemonSets per node  
B. Keep agents thin; scale **gateway** replicas  
C. Delete receivers  
D. Disable health_check  

**44.** Load-balancing exporter purpose:  
A. CSS  
B. Send by trace ID to stateful collectors  
C. MUI  
D. `yarn tsc`  

**45.** `sending_queue` on exporter:  
A. A Sampler  
B. Buffer when backend is slow  
C. W3C header  
D. Javaagent  

**46.** Hashing `user.email` in Collector:  
A. Illegal  
B. Privacy-preserving transform  
C. Tail sampling  
D. A Sampler name  

**47.** `resource` vs `attributes` processor:  
A. Identical always  
B. Resource edits resource; attributes edits signal attributes  
C. Resource is the SDK  
D. Attributes is W3C only  

**48.** `hostmetrics` receiver:  
A. HTTP SERVER spans  
B. Machine CPU/disk/etc  
C. Baggage  
D. OTTL only  

**49.** `otlphttp` exporter:  
A. Unix sockets only  
B. OTLP over HTTP (often 4318)  
C. SMTP  
D. PromQL  

**50.** Missing contrib receiver on core image:  
A. Silent success  
B. Collector fails that config  
C. Auto Maven download  
D. Converts to Counter  

**51.** `service.telemetry` in Collector YAML:  
A. App semantic conventions  
B. Collector process’s own logs/metrics  
C. W3C baggage  
D. Span kind  

**52.** `extensions` on the data path:  
A. Always in every pipeline  
B. Not in the graph unless a component uses them; health/zpages are auxiliary  
C. Replace exporters  
D. Set span kind  

**53.** Kafka exporter typical role:  
A. Replace W3C  
B. Telemetry bus / buffer between Collectors or backends  
C. Javaagent  
D. `always_off`  

**54.** `probabilistic_sampler` processor vs SDK sampler:  
A. Same process always  
B. Both drop; one is in-pipeline, one in-process at start  
C. Logs only  
D. Temporality only  

**55.** Data in `debug` exporter but not Tempo:  
A. Conventions  
B. Backend exporter/endpoint/auth after the debug fan-out  
C. Span kind INTERNAL  
D. Histogram unit  

**56.** zpages vs Jaeger:  
A. Identical long-term store  
B. zpages is in-memory Collector debug; Jaeger is a backend  
C. zpages replaces OTLP  
D. Jaeger is a Javaagent  

**57.** Blocking the handler until OTLP ACK:  
A. Best practice  
B. Anti-pattern  
C. Required for W3C  
D. How Observables work  

**58.** Mixed `http.method` and `http.request.method` in one fleet:  
A. Unrelated to OTCA  
B. Convention drift — transform or upgrade instrumentation  
C. A Sampler pair  
D. Agent vs gateway only  

**59.** Collector much older than SDK OTLP:  
A. Always fine  
B. Decode/feature risk — keep Collector current  
C. Enables PromQL  
D. Sets cumulative default  

**60.** Closed-book OTCA passing score:  
A. 64%  
B. 75% (45/60)  
C. 90%  
D. No score; lab only  

---

## Answer key

1B 2B 3B 4B 5B 6B 7B 8B 9B 10A  
11B 12B 13B 14B 15B 16B 17B 18B 19B 20B  
21B 22B 23B 24B 25B 26B 27B 28B 29B 30B  
31B 32B 33B 34B 35B 36B 37B 38B 39B 40B  
41B 42B 43B 44B 45B 46B 47B 48B 49B 50B  
51B 52B 53B 54B 55B 56B 57B 58B 59B 60B  

Missed 1–11 → `01.md`–`04.md`.  
Missed 12–38 → `05.md`–`14.md`, `Sampling.md`, `Propagation.md`.  
Missed 39–54 → `15.md`–`20.md`, `Collector.md`.  
Missed 55–59 → `21.md`–`22.md`.  
Score → `00.md`, `CheatSheet.md`.
