# Mock Exam 1

Timer: **90 minutes**. 60 questions. Closed book. Passing simulation: **45/60**.

Mix ≈ exam: API/SDK ~27, Collector ~16, Fundamentals ~11, Debug ~6.

Mark answers on paper. Key at the end.

---

**1.** The three OpenTelemetry signals are:  
A. CPU, RAM, disk  
B. Traces, metrics, logs  
C. gRPC, HTTP, UDP  
D. Agent, gateway, backend  

**2.** Observability vs monitoring:  
A. Identical  
B. Observability answers new questions from telemetry; monitoring watches known checks  
C. Monitoring is only traces  
D. Observability forbids alerts  

**3.** Required resource attribute for a service:  
A. `http.route`  
B. `exception.stacktrace`  
C. `service.name`  
D. `host.cpu.cache.l2`  

**4.** RED is:  
A. Receiver, Exporter, DaemonSet  
B. Resource, Event, Debug  
C. gRPC, HTTP, UDP  
D. Rate, Errors, Duration  

**5.** Zero-code instrumentation typically uses:  
A. Only Grafana  
B. A language agent / auto SDK  
C. Only Collector OTTL  
D. Only PromQL  

**6.** Libraries should depend on:  
A. A vendor Jaeger client only  
B. The Collector binary  
C. The OpenTelemetry API  
D. PromQL  

**7.** High-cardinality `user_id` belongs on:  
A. Metric counters as a default  
B. Traces/logs more often than metrics  
C. `OTEL_PROPAGATORS`  
D. Span kind  

**8.** Semantic conventions exist to:  
A. Compress OTLP  
B. Replace the Collector  
C. Standardise attribute names across languages/vendors  
D. Disable sampling  

**9.** Correlation of a log to a trace uses:  
A. Hostname only  
B. `memory_limiter`  
C. YAML indent  
D. `trace_id` (and usually `span_id`)  

**10.** USE is typically for:  
A. A single checkout span  
B. Resources: Utilization, Saturation, Errors  
C. W3C headers  
D. Schema URLs only  

**11.** OpenTelemetry’s primary job is to:  
A. Replace Kubernetes  
B. Generate, process, and export telemetry vendor-neutrally  
C. Store traces long-term as Jaeger  
D. Write PromQL  

**12.** Without an SDK, the API:  
A. Crashes  
B. No-ops  
C. Starts a Collector  
D. Always samples 100%  

**13.** `TracerProvider` is:  
A. A Collector receiver  
B. A span kind  
C. The SDK factory/holder of Tracers  
D. `tracestate` only  

**14.** Default local OTLP HTTP port:  
A. 9090  
B. 4318  
C. 3000  
D. 7007  

**15.** Default OTLP gRPC port:  
A. 4317  
B. 6443  
C. 2379  
D. 16686  

**16.** `OTEL_SERVICE_NAME=checkout` sets:  
A. The Sampler  
B. Span kind  
C. Resource `service.name`  
D. OTLP protocol  

**17.** Production span processor:  
A. SimpleSpanProcessor only  
B. BatchSpanProcessor  
C. No exporter  
D. PromQL  

**18.** Head sampling runs:  
A. Only in Grafana  
B. At span start in the SDK  
C. Only after Collector tail windows  
D. Only for logs  

**19.** `parentbased_traceidratio` exists so:  
A. Metrics become logs  
B. OTTL is disabled  
C. Child services honour the parent sampled flag  
D. Ports swap  

**20.** Span kind for inbound HTTP:  
A. CLIENT  
B. SERVER  
C. PRODUCER  
D. CONSUMER  

**21.** Span kind for outbound HTTP:  
A. SERVER  
B. INTERNAL only  
C. CLIENT  
D. CONSUMER  

**22.** A Counter should:  
A. Decrease when a request ends  
B. Store stack traces  
C. Only increase  
D. Replace traces  

**23.** Request latency instrument:  
A. Counter of milliseconds  
B. Histogram  
C. Baggage  
D. Span kind CONSUMER  

**24.** W3C `traceparent` carries:  
A. PromQL  
B. OTTL  
C. Version, trace-id, parent span-id, flags  
D. Pipeline names  

**25.** Baggage is automatically:  
A. Every span attribute  
B. Propagated context you must opt into copying onto spans  
C. Metric temporality  
D. A span kind  

**26.** Java zero-code attach:  
A. A Collector receiver  
B. `iptables`  
C. `-javaagent:` OpenTelemetry Java agent  
D. A span kind  

**27.** Agent vs Collector:  
A. Identical binary  
B. Agent is in-process instrumentation/SDK; Collector is a pipeline service  
C. Agent is only YAML  
D. Collector is a Javaagent  

**28.** `OTEL_SDK_DISABLED=true`:  
A. Enables debug exporter  
B. Forces tail sampling  
C. Disables the SDK (no-op)  
D. Opens zpages  

**29.** `OTEL_PROPAGATORS=tracecontext,baggage`:  
A. Disables HTTP  
B. Inject/extract W3C Trace Context and Baggage  
C. Enables PromQL  
D. Sets temporality  

**30.** `OTEL_TRACES_EXPORTER=console`:  
A. Starts Jaeger  
B. Enables tail sampling  
C. Prints spans to stdout  
D. Opens 55679  

**31.** Non-recording span:  
A. Always a bug  
B. Normal when not sampled  
C. Means Collector is down  
D. Means logs disabled  

**32.** ObservableGauge is:  
A. A Collector exporter  
B. W3C `traceparent`  
C. An async instrument collected on scrape/export  
D. A Sampler  

**33.** Cumulative temporality:  
A. Delta since last export  
B. Running total since start  
C. Tail sampling  
D. Log severity  

**34.** Logs Bridge exists to:  
A. Replace the Collector  
B. Sample traces  
C. Connect existing loggers to OTel context/export  
D. Define span kinds  

**35.** One span per log line:  
A. Best practice  
B. Usually wrong  
C. Required by OTLP  
D. How Observables work  

**36.** Broken traces (many roots) often mean:  
A. Too much batching  
B. `service.name` too long  
C. Context not propagated  
D. zpages enabled  

**37.** `record_exception` :  
A. Configures OTTL  
B. Attaches exception info on the span  
C. Starts the Java agent  
D. Sets `OTEL_SDK_DISABLED`  

**38.** Prefer app → Collector via:  
A. SMTP  
B. FTP  
C. OTLP  
D. `kubectl exec`  

**39.** Collector pipeline order:  
A. exporters → receivers → processors  
B. receivers → processors → exporters  
C. extensions → Sampler → API  
D. logs auto-merge into traces  

**40.** Declared receiver not in any pipeline:  
A. Still receives  
B. Inactive  
C. Becomes an exporter  
D. Sets `service.name`  

**41.** `memory_limiter` should be:  
A. After all exporters  
B. Early in processors  
C. Only in the SDK  
D. Only for logs  

**42.** `batch` processor typically:  
A. First processor  
B. A propagator  
C. Near the end before export  
D. A Sampler  

**43.** Agent Collector deployment:  
A. Only regional SaaS  
B. Sidecar or node DaemonSet near the app  
C. Only Grafana  
D. Only the Javaagent  

**44.** Tail sampling belongs on:  
A. Every sidecar always  
B. MeterProvider  
C. A gateway that can see whole traces  
D. Baggage  

**45.** Two exporters on one traces pipeline:  
A. Illegal  
B. Fan-out  
C. Splits `trace_id`  
D. Disables batching  

**46.** `spanmetrics` is a:  
A. Java Sampler  
B. W3C header  
C. Connector traces → metrics  
D. Log severity  

**47.** OTTL lives in:  
A. The Java API only  
B. W3C `traceparent`  
C. PromQL  
D. Collector transform processor  

**48.** Tail sampling on two random replicas:  
A. Ideal  
B. Splits traces; hash by trace ID  
C. Required  
D. Replaces `service.name`  

**49.** `k8sattributes` processor:  
A. A span kind  
B. Adds pod/namespace metadata  
C. Replaces OTLP  
D. Is the Javaagent  

**50.** `debug` exporter:  
A. Stores 13 months  
B. Replaces OTLP in production always  
C. Prints telemetry for troubleshooting  
D. Is ParentBased  

**51.** Metrics exporter on a traces pipeline:  
A. Ideal  
B. Wrong signal  
C. Converts spans automatically  
D. Sets ParentBased  

**52.** `filelog` receiver:  
A. The Logs SDK  
B. A span kind  
C. Tails files into the logs pipeline  
D. `OTEL_LOGS_EXPORTER`  

**53.** contrib vs core image:  
A. Identical always  
B. Contrib has extra components  
C. Contrib is the Java agent  
D. Core cannot receive OTLP  

**54.** Operator `Instrumentation` CR:  
A. A Prometheus Rule  
B. Injects agent/env into workloads  
C. A span event  
D. W3C only  

**55.** First check if the app emits nothing:  
A. Grafana JSON  
B. SDK exporter/env / no-op  
C. etcd  
D. Helm  

**56.** Console exporter works, Jaeger empty:  
A. Semantic conventions  
B. Span kind INTERNAL  
C. Path after the SDK (endpoint, Collector, backend)  
D. Histogram unit  

**57.** zpages are:  
A. 13-month storage  
B. Collector in-process debug pages  
C. A replacement for OTLP  
D. `service.name`  

**58.** Telemetry export failure should:  
A. Crash checkout  
B. Not fail the user request  
C. Delete `service.name`  
D. Disable Kubernetes  

**59.** `schema_url` means:  
A. App REST baseUrl  
B. OTLP port  
C. Which semantic-convention schema produced the data  
D. zpages path  

**60.** OTCA exam format:  
A. 2h live cluster  
B. 60 MCQ, 90 min, 75%, closed book  
C. Oral  
D. Open book otel.io  

---

## Answer key

1B 2B 3C 4D 5B 6C 7B 8C 9D 10B  
11B 12B 13C 14B 15A 16C 17B 18B 19C 20B  
21C 22C 23B 24C 25B 26C 27B 28C 29B 30C  
31B 32C 33B 34C 35B 36C 37B 38C 39B 40B  
41B 42C 43B 44C 45B 46C 47D 48B 49B 50C  
51B 52C 53B 54B 55B 56C 57B 58B 59C 60B  

Missed 1–11 → `01.md`–`04.md`, `Signals.md`.  
Missed 12–38 → `05.md`–`14.md`, `Architecture.md`, `Propagation.md`, `Sampling.md`.  
Missed 39–54 → `15.md`–`20.md`, `Collector.md`.  
Missed 55–59 → `21.md`–`22.md`.  
Format → `00.md`.
