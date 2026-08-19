# Instrumentation And Client Libraries

## Official Client Libraries

| Language | Package | Notes |
| --- | --- | --- |
| **Go** | `github.com/prometheus/client_golang` | The reference implementation |
| **Java / JVM** | `io.prometheus:simpleclient` (0.x), `prometheus-metrics-core` (1.x) | Covers Scala, Kotlin, Clojure |
| **Python** | `prometheus_client` | |
| **Ruby** | `prometheus-client` | |
| **Rust** | `prometheus-client` | Officially maintained |

Unofficial but widely used: .NET, Node.js (`prom-client`), PHP, C++, Perl, Elixir, Haskell, Lua, Erlang, Bash.

**OpenTelemetry** SDKs can also export in Prometheus format, and Prometheus can ingest OTLP.

## The Standard API Surface

Every library provides:

```text
Counter    inc(), inc(n), add(n)
Gauge      set(v), inc(), dec(), add(n), sub(n), set_to_current_time(), track_inprogress()
Histogram  observe(v), time()
Summary    observe(v), time()
Registry   register(), unregister(), collect()
Exposition an HTTP handler at /metrics
```

Python:

```python
from prometheus_client import (
    Counter, Gauge, Histogram, Summary, Info, Enum,
    CollectorRegistry, REGISTRY, start_http_server, generate_latest,
    push_to_gateway, pushadd_to_gateway, delete_from_gateway,
    make_wsgi_app, multiprocess,
)

REQUESTS = Counter("myapp_requests_total", "Total requests.", ["method", "route", "code"])
REQUESTS.labels(method="GET", route="/api", code="200").inc()

QUEUE = Gauge("myapp_queue_length", "Items in the queue.")
QUEUE.set(42)

LATENCY = Histogram(
    "myapp_request_duration_seconds", "Request latency.",
    ["method", "route"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.3, 0.5, 1.0, 2.5, 5.0),
)

with LATENCY.labels(method="GET", route="/api").time():
    handle()

INFLIGHT = Gauge("myapp_requests_inflight", "In-flight requests.")

@INFLIGHT.track_inprogress()
def handler():
    ...

BUILD = Info("myapp_build", "Build info.")
BUILD.info({"version": "1.4.2", "revision": "a1b2c3", "branch": "main"})

STATE = Enum("myapp_state", "Worker state.", states=["starting", "running", "stopped"])
STATE.state("running")

# Callback gauge: evaluated at scrape time, no duplicated state
Gauge("myapp_cache_entries", "Cache size.").set_function(lambda: len(cache))

start_http_server(8000)
```

Go:

```go
import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var requests = promauto.NewCounterVec(
    prometheus.CounterOpts{
        Name: "myapp_requests_total",
        Help: "Total requests.",
    },
    []string{"method", "route", "code"},
)

var latency = promauto.NewHistogramVec(
    prometheus.HistogramOpts{
        Name:    "myapp_request_duration_seconds",
        Help:    "Request latency.",
        Buckets: prometheus.ExponentialBuckets(0.001, 2, 15),
    },
    []string{"method", "route"},
)

// Callback gauge for a value that lives elsewhere
promauto.NewGaugeFunc(prometheus.GaugeOpts{
    Name: "myapp_cache_entries",
    Help: "Cache size.",
}, func() float64 { return float64(len(cache)) })

func main() {
    http.Handle("/metrics", promhttp.Handler())
    http.ListenAndServe(":8080", nil)
}
```

Bucket generators in Go:

```go
prometheus.DefBuckets                              // .005 ... 10
prometheus.LinearBuckets(0.1, 0.1, 10)             // 0.1 0.2 ... 1.0
prometheus.ExponentialBuckets(0.001, 2, 15)        // 1ms doubling, 15 buckets
prometheus.ExponentialBucketsRange(0.001, 10, 20)  // 20 buckets from 1ms to 10s
```

`+Inf` is added automatically; do not list it.

## Registries

| Concept | Meaning |
| --- | --- |
| **Default registry** | The global one. Libraries should register here so applications get their metrics automatically |
| **Custom registry** | Isolated. Use for batch jobs, tests, or exporters that must not leak `process_*` metrics |
| **Collector** | Anything that can be collected. Metrics are collectors, and so are custom on-demand collectors |

```python
# Batch jobs MUST use a dedicated registry
registry = CollectorRegistry()
g = Gauge("batch_duration_seconds", "Duration.", registry=registry)
g.set(184.2)
push_to_gateway("localhost:9091", job="batchA", registry=registry)
```

Using the default registry for a push would ship `python_*` and `process_*` metrics from a process that is about to exit, which is meaningless.

## Custom Collectors

Use when the data already exists somewhere and you must fetch it **on scrape**.

```python
from prometheus_client.core import GaugeMetricFamily, CounterMetricFamily
from prometheus_client.registry import Collector
from prometheus_client import REGISTRY

class MyCollector(Collector):
    def collect(self):
        # Query the backing system HERE, on every scrape
        try:
            data = fetch_from_backend()
            yield GaugeMetricFamily("mysystem_up", "1 if reachable.", value=1)
        except Exception:
            yield GaugeMetricFamily("mysystem_up", "1 if reachable.", value=0)
            return

        g = GaugeMetricFamily("mysystem_queue_length", "Queue length.", labels=["queue"])
        for name, n in data.items():
            g.add_metric([name], n)
        yield g

REGISTRY.register(MyCollector())
```

```go
type myCollector struct{ desc *prometheus.Desc }

func (c *myCollector) Describe(ch chan<- *prometheus.Desc) { ch <- c.desc }
func (c *myCollector) Collect(ch chan<- prometheus.Metric) {
    v := fetchFromBackend()
    ch <- prometheus.MustNewConstMetric(c.desc, prometheus.GaugeValue, v)
}
```

**Direct instrumentation** mutates metric objects inline as the code runs. A **custom collector** fetches on demand. Use the first for your own code, the second for wrapping something else.

## Built-In Metrics You Get Free

| Library | Prefixes |
| --- | --- |
| Go | `go_goroutines`, `go_threads`, `go_gc_duration_seconds`, `go_memstats_*`, `go_info` |
| Python | `python_gc_objects_collected_total`, `python_info` |
| Java | `jvm_memory_bytes_used`, `jvm_gc_collection_seconds`, `jvm_threads_current`, `jvm_classes_loaded` |
| **All** | `process_*` |

The **`process_*` family is standardised across languages**:

```text
process_cpu_seconds_total
process_resident_memory_bytes
process_virtual_memory_bytes
process_open_fds
process_max_fds
process_start_time_seconds
```

`process_start_time_seconds` is the standard restart detector:

```promql
time() - process_start_time_seconds                  # uptime
changes(process_start_time_seconds[1h])              # restarts in the last hour
time() - process_start_time_seconds < 300            # restarted in the last 5 minutes
```

Go's handler also exposes `promhttp_metric_handler_requests_total{code}` and `promhttp_metric_handler_requests_in_flight`, which tell you how often the target is being scraped.

## Multiprocess Mode

A pre-fork server (gunicorn, uWSGI, PHP-FPM) has many worker processes. Each scrape hits a random one, so you would see only that worker's numbers.

```bash
export PROMETHEUS_MULTIPROC_DIR=/tmp/prom_multiproc
mkdir -p $PROMETHEUS_MULTIPROC_DIR
```

```python
from prometheus_client import CollectorRegistry, multiprocess, make_wsgi_app

def make_app():
    registry = CollectorRegistry()
    multiprocess.MultiProcessCollector(registry)
    return make_wsgi_app(registry)

# gunicorn hook
def child_exit(server, worker):
    multiprocess.mark_process_dead(worker.pid)
```

Limitations: gauges need an explicit mode (`all`, `liveall`, `min`, `max`, `livesum`), and some metric types behave differently. Go does not need this because it is natively multithreaded.

## What To Instrument

From the Prometheus documentation:

**Online-serving systems** (anything that answers requests): **count requests, count failures, measure latency.** That is **RED** (Rate, Errors, Duration).

**Offline-serving / batch pipelines**: items in, items out, queue depth, time per stage, and a **last-success timestamp**.

**Batch jobs**: start time, duration, records processed, success flag, last-success timestamp. Deliver via the Pushgateway or the node_exporter textfile collector.

**Libraries**: instrument anything that does I/O, takes a lock, or touches the network. Register on the **default registry**.

Three layers worth covering in any service:

```text
1. Service-level RED, in middleware, covering every route
2. Per-dependency RED, for each outbound call (database, cache, upstream API)
3. Internal resources: pools, queues, caches, in-flight counts (gauges)
```

Middleware gives you RED for free. Per-dependency instrumentation is what lets you **attribute** latency when the SLO burns.

## Choosing A Metric Type

```text
Does the value only ever go up (and reset to 0 on restart)?
    -> COUNTER, name ends _total, query with rate()

Does it go up and down?
    -> GAUGE, query directly or with *_over_time / delta / deriv / predict_linear

Do you need a distribution you will aggregate across instances?
    -> HISTOGRAM (default choice for latency and sizes)

Do you need an exact per-instance quantile and will never aggregate?
    -> SUMMARY

Do you only want a total and an average, no quantiles?
    -> SUMMARY with no quantiles configured (cheap), or a HISTOGRAM's _sum/_count

Do you need to attach metadata (version, region) to a target?
    -> INFO metric: a gauge fixed at 1 with metadata labels, joined via group_left

Do you need "which state is this in"?
    -> STATESET / Enum: one series per state, exactly one equals 1
```

## Histogram Versus Summary

| | Histogram | Summary |
| --- | --- | --- |
| Quantile computed | At **query time** in Prometheus | At **instrumentation time** in the client |
| Aggregatable | **Yes** | **No** |
| Change quantiles later | Yes, just query differently | No, needs a code change |
| Up-front choice | Bucket boundaries | Quantiles and error bounds |
| Client CPU | Low | Higher |
| Label | `le` | `quantile` |

**Default to histograms.** Always place a bucket boundary **exactly at your SLO threshold** so the ratio below it is exact rather than interpolated.

## Naming And Labelling Rules

```text
<namespace>_<subsystem>_<name>_<unit>[_total]
```

1. **Base units only.** Seconds, bytes, ratios 0-1. Never milliseconds, kilobytes, or percentages.
2. **Counters end in `_total`.**
3. Include the unit: `_seconds`, `_bytes`, `_celsius`, `_ratio`.
4. snake_case.
5. **Reserved suffixes** you must not use as base names: `_total`, `_count`, `_sum`, `_bucket`, `_created`, `_info`.
6. One metric with a label, not many metrics: `requests_total{method="GET"}`, not `requests_get_total`.
7. The name must make sense **when summed** across all its labels.
8. **Never expose a rate, ratio, average, or percentage.** Expose the counters.
9. Bounded label cardinality. **Never** user IDs, emails, request IDs, session IDs, raw URLs with IDs, or timestamps. Use **route templates**.
10. Never expose `job` or `instance` yourself; Prometheus owns them.
11. Never set your own sample timestamps.
12. Do not put the metric name in a label.

## Patterns

### The last-success timestamp

```python
LAST_SUCCESS = Gauge("myapp_last_success_timestamp_seconds", "Unix time of last success.")
LAST_SUCCESS.set_to_current_time()
```

```promql
time() - myapp_last_success_timestamp_seconds > 3600
```

Expose a **timestamp**, not an age. A timestamp stays correct when the process stalls; a self-computed age freezes at its last value and lies.

### Info metrics

```python
BUILD = Info("myapp_build", "Build information.")
BUILD.info({"version": "1.4.2", "revision": "a1b2c3"})
```

```promql
sum by (instance) (rate(myapp_requests_total[5m]))
  * on (instance) group_left (version) myapp_build_info
```

A gauge fixed at 1 carrying metadata labels. Keeps high-churn metadata (like a version string) out of every other metric, which would otherwise create new series on every deploy.

### In-flight gauge

```python
INFLIGHT = Gauge("myapp_requests_inflight", "In-flight requests.")

@INFLIGHT.track_inprogress()
def handler(): ...
```

### Counting failures

```python
# Preferred: one counter with a status label, so ratios are computable
REQUESTS = Counter("myapp_requests_total", "Requests.", ["code"])
```

```promql
sum(rate(myapp_requests_total{code=~"5.."}[5m])) / sum(rate(myapp_requests_total[5m]))
```

**Pre-initialise the label children you know about**, so the series exists from the start and `rate()` can see the first increment:

```python
for c in ("200", "404", "500", "503"):
    REQUESTS.labels(code=c)
```

Without that, a 500 appearing for the first time creates a series whose first sample `rate()` has nothing to compare against.

### Fail-safe instrumentation

```python
try:
    do_work()
except Exception:
    FAILURES.inc()
    raise
finally:
    REQUESTS.inc()
    LATENCY.observe(time.time() - start)
```

Instrumentation must **never** throw into the request path. Monitoring must not break the thing it monitors.

## Anti-Patterns

| Anti-pattern | Why it is wrong |
| --- | --- |
| User ID / email / request ID / session ID as a label | Unbounded cardinality |
| Raw URL path with IDs as a label | Unbounded. Use the route template |
| Timestamps as label values | Unbounded, and time is already an axis |
| Exposing a pre-computed rate or ratio | Cannot be re-windowed or aggregated |
| A gauge the client zeroes each scrape | Breaks with multiple scrapers and missed scrapes |
| A counter that can decrease | `rate()` reads it as a reset |
| One metric per label value | Should be one metric with a label |
| Setting your own timestamps | Interferes with staleness handling |
| Exposing `job` or `instance` | Collides, becomes `exported_*` |
| Polling into a cache on a timer instead of collecting on scrape | Stale-cache lag |
| Milliseconds, kilobytes, percentages | Violates base units |
| Default histogram buckets for minute-scale work | Everything lands in `+Inf` |

## Instrumenting For SLOs

```python
REQUESTS = Counter("http_requests_total", "Requests.", ["method", "route", "code"])
LATENCY = Histogram(
    "http_request_duration_seconds", "Latency.", ["method", "route"],
    buckets=(0.005, 0.01, 0.05, 0.1, 0.3, 0.5, 1, 2.5, 5, 10),   # 0.3 = the SLO threshold
)
```

```promql
# Availability SLI, excluding client errors from the budget
1 - (sum(rate(http_requests_total{code=~"5.."}[30d]))
     / sum(rate(http_requests_total[30d])))

# Latency SLI: exact, because 0.3 is a real bucket boundary
sum(rate(http_request_duration_seconds_bucket{le="0.3"}[5m]))
  / sum(rate(http_request_duration_seconds_count[5m]))
```

Keeping the `code` label is what makes the 4xx-versus-5xx decision possible later. That decision has to be enabled by the instrumentation.

## Validation

```bash
curl -s http://localhost:8000/metrics | promtool check metrics
curl -s http://localhost:8000/metrics | grep -c '^[a-z]'
curl -s 'http://localhost:9090/api/v1/metadata?metric=myapp_requests_total' | jq .
```

```promql
count({job="myapp"})                                   # series cost of your instrumentation
topk(10, count by (__name__) ({job="myapp"}))
scrape_samples_scraped{job="myapp"}
scrape_series_added{job="myapp"}
```

## Memorise

- Official libraries: **Go, Java/JVM, Python, Ruby, Rust**.
- **Direct instrumentation** = inline mutation of metric objects. **Custom collector** = fetch **on scrape**.
- Libraries register on the **default registry**; batch jobs use a **dedicated registry**.
- `process_*` metrics are **cross-language**; `go_*`, `python_*`, `jvm_*` are not.
- **`process_start_time_seconds`** is the restart detector.
- **Multiprocess mode** with a shared `PROMETHEUS_MULTIPROC_DIR` is required for pre-fork servers.
- **Online-serving: count requests, count failures, measure latency.** That is RED.
- **Default to histograms.** Put a bucket boundary **exactly at the SLO threshold**.
- Expose a **timestamp of last success**, never an age.
- **Info metric** = gauge fixed at 1 with metadata labels, joined with `group_left`.
- Use **callback gauges** for values that live elsewhere.
- **Pre-initialise known label children** so `rate()` works from the first increment.
- **Base units, `_total` on counters, unit in the name, snake_case.**
- Reserved suffixes: **`_total`, `_count`, `_sum`, `_bucket`, `_created`, `_info`**.
- **Never** expose rates or ratios, unbounded label values, raw paths, your own timestamps, or `job`/`instance`.
- Use **route templates**, not raw paths.
- Instrumentation must **never throw** into the request path.
- Instrument in **middleware** for service-level RED and **per dependency** for attribution.
