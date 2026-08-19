# Exposition Format And Data Model

## The Data Model

A time series is uniquely identified by its **metric name plus the complete set of label name/value pairs**.

```text
http_requests_total{job="api", instance="a:80", method="GET", code="200"}
└──────┬──────────┘ └──────────────────────┬──────────────────────────┘
   metric name                        label set
```

Facts:

- The metric name is itself stored in the reserved label **`__name__`**. So `up{job="x"}` and `{__name__="up", job="x"}` are the same selector.
- Changing **any** label value creates a **different** series.
- A sample is a **float64** value plus a **millisecond-precision** timestamp. Native histograms are the only non-float sample type.
- Special float values `+Inf`, `-Inf`, and `NaN` are valid sample values.

### Naming rules

| Item | Allowed characters (classic) |
| --- | --- |
| Metric name | `[a-zA-Z_:][a-zA-Z0-9_:]*` |
| Label name | `[a-zA-Z_][a-zA-Z0-9_]*` |
| Label value | Any UTF-8 |

- **Colons are valid in metric names but not in label names.** They are reserved by convention for **recording rules**.
- Label names beginning with **`__`** are reserved for internal use.
- An **empty label value** is equivalent to the label not existing at all. `{foo=""}` and a series without `foo` are the same series.
- Prometheus 3.x supports UTF-8 metric and label names with a quoting syntax (`{"my.metric", "label.name"="v"}`), but the classic charset is what the exam expects.

## Prometheus Text Format

Version `0.0.4`. Content type:

```text
text/plain; version=0.0.4; charset=utf-8
```

```text
# HELP http_requests_total The total number of HTTP requests.
# TYPE http_requests_total counter
http_requests_total{method="post",code="200"} 1027 1395066363000
http_requests_total{method="post",code="400"}    3 1395066363000

# Minimalistic line
metric_without_timestamp_and_labels 12.47

# A weird metric from before the epoch
something_weird{problem="division by zero"} +Inf -3982045

# HELP http_request_duration_seconds A histogram of request durations.
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.05"} 24054
http_request_duration_seconds_bucket{le="0.1"}  33444
http_request_duration_seconds_bucket{le="+Inf"} 144320
http_request_duration_seconds_sum 53423
http_request_duration_seconds_count 144320

# HELP rpc_duration_seconds A summary of RPC durations.
# TYPE rpc_duration_seconds summary
rpc_duration_seconds{quantile="0.5"} 4773
rpc_duration_seconds{quantile="0.99"} 76656
rpc_duration_seconds_sum 1.7560473e+07
rpc_duration_seconds_count 2693
```

### Syntax rules

```text
# HELP <metric_name> <docstring>
# TYPE <metric_name> <counter|gauge|histogram|summary|untyped>
<metric_name>[{<label>="<value>", ...}] <value> [<timestamp>]
```

- **Line-oriented**, `\n` separated. `\r\n` is **not** allowed.
- The last line must end with a newline.
- Lines starting with `#` are comments, unless the first token after `#` is `HELP` or `TYPE`.
- `HELP` and `TYPE` are **optional**. Without `TYPE`, the metric is `untyped`.
- Each metric name may have **at most one** `HELP` and one `TYPE` line.
- **All lines for one metric name must be grouped together**, with the `HELP`/`TYPE` first.
- Values are Go-parseable floats. `+Inf`, `-Inf`, `Nan`/`NaN` are allowed. Scientific notation like `1.7560473e+07` is allowed.
- Timestamps are **int64 milliseconds** since the epoch, and are **optional**. Omit them and Prometheus uses the scrape time, which is what you want.
- Whitespace between tokens is flexible but there must be at least one space before the value.

### Escaping

| Context | Escapes |
| --- | --- |
| `HELP` docstring | `\\` and `\n` |
| Label values | `\\`, `\"`, `\n` |

```text
# HELP msg_total A metric with a backslash \\ and a newline \n in the help.
msg_total{path="C:\\temp",note="line1\nline2",quote="say \"hi\""} 1
```

Note that `\t` is **not** an escape in label values in the classic text format.

### Type-specific requirements

| Type | Required lines |
| --- | --- |
| `counter` | Convention: name ends `_total` |
| `gauge` | Nothing special |
| `histogram` | `_bucket{le="..."}` for each bucket **including `+Inf`**, plus `_sum` and `_count` |
| `summary` | `{quantile="..."}` for each quantile (optional), plus `_sum` and `_count` |
| `untyped` | Anything |

For histograms, `le` values must be **valid floats as strings**, `+Inf` must be present, and buckets should be listed in increasing order (Prometheus tolerates other orders but tooling may not).

## OpenMetrics

Version `1.0.0`, a CNCF standard derived from the Prometheus text format. Content type:

```text
application/openmetrics-text; version=1.0.0; charset=utf-8
```

```text
# TYPE http_requests counter
# UNIT http_requests requests
# HELP http_requests Total requests.
http_requests_total{code="200"} 1027
http_requests_created{code="200"} 1520430000.123
# TYPE build info
# HELP build Build information.
build_info{version="1.4.2",revision="a1b2c3"} 1
# TYPE process_state stateset
# HELP process_state Current state.
process_state{process_state="starting"} 0
process_state{process_state="running"} 1
process_state{process_state="stopped"} 0
# EOF
```

### Differences from the Prometheus text format

| | Prometheus text | OpenMetrics |
| --- | --- | --- |
| Terminator | None | **`# EOF` is mandatory** |
| Content type | `text/plain; version=0.0.4` | `application/openmetrics-text; version=1.0.0` |
| `UNIT` metadata | No | **Yes**, and the unit must be the metric name suffix |
| Counter naming | `_total` by convention | **`_total` is required** in the sample line, while `TYPE` uses the base name |
| `_created` timestamps | No | **Yes**, optional per counter/histogram/summary |
| Metric types | counter, gauge, histogram, summary, untyped | **plus `info`, `stateset`, `gaugehistogram`, and `unknown`** instead of untyped |
| Timestamps | int64 milliseconds | **Float seconds** |
| Exemplars | No | **Yes**, appended with `#` after the value |
| `NaN` spelling | `Nan` or `NaN` | `NaN` only |

An important subtlety: in OpenMetrics, a counter declared as `# TYPE http_requests counter` has its sample written as `http_requests_total`. The `TYPE` line uses the **base** name; the sample line adds `_total`.

### Exemplars

```text
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.1"} 33444 # {trace_id="a1b2c3d4"} 0.087 1520430000.123
```

An exemplar attaches a **trace ID** (or any labels) to a specific observation, with its value and timestamp. This is the metrics-to-traces bridge, and it is why exemplars matter for observability.

Enable storage with:

```bash
prometheus --enable-feature=exemplar-storage
```

Query with:

```bash
curl -s -G localhost:9090/api/v1/query_exemplars \
  --data-urlencode 'query=http_request_duration_seconds_bucket' \
  --data-urlencode 'start=...' --data-urlencode 'end=...'
```

Exemplar storage is **in-memory and fixed-size**, not persisted to blocks.

## Content Negotiation

Prometheus sends an `Accept` header advertising what it can parse:

```text
Accept: application/openmetrics-text;version=1.0.0;q=0.75,
        text/plain;version=0.0.4;q=0.5,
        application/vnd.google.protobuf;...;q=0.25,
        */*;q=0.1
```

The target picks a format. Facts:

- **Protobuf is required for native histograms.** The text formats cannot express them.
- Prometheus can parse Protobuf but the text formats are what almost everything uses.
- The Protobuf format was historically the primary format, was deprecated in favour of text, and returned for native histograms.

Prometheus also sends:

```text
X-Prometheus-Scrape-Timeout-Seconds: 10
User-Agent: Prometheus/3.5.0
```

A well-behaved exporter should honour that timeout header.

## Metric Types In Detail

| Type | Semantics | Can decrease | Query with |
| --- | --- | --- | --- |
| **Counter** | Cumulative, monotonically increasing, resets to 0 on restart | No | `rate()`, `increase()` |
| **Gauge** | A current value that goes up and down | Yes | Directly, or `*_over_time()`, `delta()`, `deriv()`, `predict_linear()` |
| **Histogram** | Cumulative bucket counters plus `_sum` and `_count` | No | `histogram_quantile(φ, rate(_bucket[5m]))` |
| **Summary** | Client-computed quantiles plus `_sum` and `_count` | Quantile gauges can | Read `quantile` directly; **cannot aggregate** |
| **Info** (OM) | A gauge fixed at 1 carrying metadata labels | n/a | Join with `group_left` |
| **StateSet** (OM) | One series per state, exactly one is 1 | n/a | `== 1` |
| **GaugeHistogram** (OM) | Bucket counts that can go up **and down** | Yes | Current distribution, not cumulative observations |
| **Untyped / Unknown** | No semantics declared | n/a | Careful |

Prometheus itself **stores no type information** for the classic types; the `TYPE` metadata is exposed through `/api/v1/metadata` and used by tooling and the UI, but the TSDB just stores samples. That is why nothing stops you from calling `rate()` on a gauge; it just gives nonsense.

Reserved suffixes you must not use as base metric names:

```text
_total     counter
_count     histogram/summary count
_sum       histogram/summary sum
_bucket    histogram bucket
_created   OpenMetrics creation timestamp
_info      OpenMetrics info
_gcount / _gsum   gaugehistogram
```

## Naming Conventions

```text
<library_or_application>_<subsystem>_<measurement>_<unit>[_total]
```

Rules:

1. **Use base units.** Seconds, bytes, ratios (0-1), meters, volts, amperes, joules, grams, celsius. **Not** milliseconds, kilobytes, or percentages.
2. **Counters end in `_total`.**
3. Include the **unit** in the name: `_seconds`, `_bytes`, `_celsius`, `_ratio`.
4. Use **snake_case**.
5. One metric per **logical measurement**, with variation in labels. Not `requests_get_total` and `requests_post_total`, but `requests_total{method="GET"}`.
6. The name should make sense **when aggregated**. If summing across all label values is nonsense, the design is wrong.
7. **Do not** expose pre-computed rates, ratios, averages, or percentages. Expose the raw counters.
8. Prefix with the exporting system's name for exporters: `mysql_`, `node_`, `redis_`.
9. Dimensionless counts get `_total` without a unit: `errors_total`, `exceptions_total`.

Examples:

| Good | Bad | Why |
| --- | --- | --- |
| `http_request_duration_seconds` | `http_request_duration_ms` | Base units |
| `node_memory_MemFree_bytes` | `node_memory_free_kb` | Base units |
| `http_requests_total` | `http_requests` | Counters get `_total` |
| `http_requests_total{code="500"}` | `http_500_responses_total` | Variation belongs in labels |
| `queue_items` | `queue_items_count` | `_count` is reserved |
| `cpu_usage_ratio` | `cpu_usage_percent` | Ratios 0-1 |
| `process_cpu_seconds_total` | `process_cpu_usage` | Unit and `_total` |
| `disk_errors_total` | `disk_error_rate` | Never expose a rate |

## Labels

Rules:

1. Labels are **dimensions**, meant to be aggregated over.
2. **Cardinality must be bounded.** Never user IDs, emails, request IDs, session IDs, raw URLs, timestamps, or free-form text.
3. Use **route templates** (`/user/:id`) rather than raw paths.
4. Do **not** put the metric name in a label: `{type="requests"}` is wrong.
5. Reserved: `job`, `instance`, `le`, `quantile`, and anything starting with `__`.
6. An empty label value equals an absent label.
7. Keep the label set stable. Series that appear and disappear cause churn.

### Cardinality arithmetic

```text
total series = number of distinct label-value combinations, per metric name
```

```text
node_cpu_seconds_total{cpu, mode}   with 16 cores x 8 modes  = 128 series per host
http_requests_total{method, code, route}
  5 methods x 20 codes x 50 routes                            = 5,000 series per instance
  x 100 instances                                             = 500,000 series
```

Rough memory rule: **roughly 1 to 3 KB of RAM per active series**, so a million series is a few gigabytes before query overhead. This is why cardinality is Prometheus's dominant failure mode.

Find it:

```promql
topk(10, count by (__name__) ({__name__=~".+"}))
count by (job) ({__name__=~".+"})
prometheus_tsdb_head_series
scrape_series_added
topk(5, scrape_samples_scraped)
```

```bash
curl -s http://localhost:9090/api/v1/status/tsdb | jq '{
  seriesCountByMetricName: .data.seriesCountByMetricName[:10],
  labelValueCountByLabelName: .data.labelValueCountByLabelName[:10],
  memoryInBytesByLabelName: .data.memoryInBytesByLabelName[:10]
}'
```

Mitigate with `metric_relabel_configs` (`drop`, `labeldrop`) or by fixing the instrumentation.

## Validation

```bash
# Validate an exposition response
curl -s http://localhost:9100/metrics | promtool check metrics

# Validate config and rules
promtool check config prometheus.yml
promtool check rules rules/*.yml

# Check what metadata Prometheus recorded
curl -s 'http://localhost:9090/api/v1/metadata?metric=up' | jq .
curl -s 'http://localhost:9090/api/v1/targets/metadata?match_target={job="node"}' | jq '.data[:5]'
```

`promtool check metrics` catches missing `_total` suffixes, non-base units, reserved suffix misuse, and inconsistent `HELP`/`TYPE`.

## Traps

| Mistake | Consequence |
| --- | --- |
| Exposing milliseconds | Every consumer must know to divide. Violates the convention |
| Percentages instead of ratios 0-1 | `humanizePercentage` and Grafana `percentunit` both break |
| Omitting `_total` on a counter | Tooling cannot tell it is a counter |
| Using `_count` or `_sum` as a base name | Collides with histogram/summary conventions |
| Setting your own timestamps | Interferes with staleness handling |
| Exposing `job` or `instance` from an exporter | Collides with target labels, becomes `exported_*` |
| A counter that decreases | `rate()` reads it as a reset |
| Unbounded label values | Cardinality explosion, OOM |
| Metric name in a label | Cannot be selected by name, breaks tooling |
| Missing `+Inf` bucket | Invalid histogram, `histogram_quantile` misbehaves |
| Missing `# EOF` in OpenMetrics | Parse failure |
| `\r\n` line endings | Parse failure |
| Text format for native histograms | Not expressible. Protobuf required |

## Memorise

- A series is **metric name plus the full label set**. The name lives in **`__name__`**.
- Samples are **float64 plus millisecond timestamps**.
- Metric names: `[a-zA-Z_:][a-zA-Z0-9_:]*`. Label names: `[a-zA-Z_][a-zA-Z0-9_]*`. **Colons in names, never in label names.**
- **`__`-prefixed label names are reserved.** An **empty label value equals no label**.
- Text format is **version 0.0.4**, `text/plain`. OpenMetrics is **1.0.0**, `application/openmetrics-text`.
- **OpenMetrics requires `# EOF`**, adds **`UNIT`**, **`_created`**, **exemplars**, **`info`**, **`stateset`**, **`gaugehistogram`**, uses **float seconds** timestamps, and **requires** the `_total` suffix on counter samples.
- `HELP` and `TYPE` are **optional**; missing `TYPE` means `untyped`. One of each per metric, grouped together.
- Escapes: `\\`, `\n` in HELP; `\\`, `\"`, `\n` in label values.
- Timestamps are optional and **should be omitted**.
- **Protobuf is required for native histograms.**
- Reserved suffixes: **`_total`, `_count`, `_sum`, `_bucket`, `_created`, `_info`**.
- Reserved labels: **`job`, `instance`, `le`, `quantile`, `__*`**.
- **Base units always**: seconds, bytes, ratios 0-1.
- **Never expose rates, ratios, averages, or percentages.** Expose counters.
- Cardinality **multiplies**. Roughly **1-3 KB RAM per series**.
- Validate exposition with **`promtool check metrics`**.
