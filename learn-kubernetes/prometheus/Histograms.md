# Histograms And Summaries

The single most examined technical topic in PromQL. Learn it cold.

## The Problem

An average hides everything.

```text
1000 requests: 999 at 10ms, 1 at 10 seconds
average = 20ms          <- looks fine
p99.9   = 10 seconds    <- one user had a terrible time
```

You need the **distribution**, and you need it in a form that can be **aggregated across instances**. That is what histograms give you.

## Classic Histograms

A histogram observation increments **every bucket whose upper bound is greater than or equal to the value**. Buckets are **cumulative**.

Exposed as three families:

```text
<name>_bucket{le="<upper bound>"}   counter, one per bucket, CUMULATIVE
<name>_sum                          counter, sum of all observed values
<name>_count                        counter, number of observations
```

```text
# HELP http_request_duration_seconds Request latency.
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.1"}   240
http_request_duration_seconds_bucket{le="0.25"}  680
http_request_duration_seconds_bucket{le="0.5"}   890
http_request_duration_seconds_bucket{le="1.0"}   970
http_request_duration_seconds_bucket{le="+Inf"} 1000
http_request_duration_seconds_sum               287.4
http_request_duration_seconds_count             1000
```

Read it as: 240 requests were **at or under** 0.1s, 680 were at or under 0.25s (so 440 fell between 0.1 and 0.25), and 1000 total.

Facts:

- The **`+Inf` bucket always exists** and always equals `_count`.
- Buckets are **cumulative**, so each is a superset of the previous.
- Every bucket, `_sum`, and `_count` is a **counter**, so they all need `rate()`.
- `le` values are **strings** in the label, so `le="0.5"` and `le="0.50"` are different label values. Client libraries normalise this; hand-written exposition can get it wrong.
- The default buckets are `.005 .01 .025 .05 .075 .1 .25 .5 .75 1 2.5 5 7.5 10`, tuned for **sub-second web requests**.

### Series count

```text
series per label combination = (number of explicit boundaries) + 1 (+Inf) + 2 (_sum, _count)
total = that x number of label combinations
```

10 explicit boundaries with 4 label combinations gives `(10 + 1 + 2) x 4 = 52` series. Histograms are the main driver of cardinality in most instrumented applications.

### Querying

```promql
# ALWAYS rate() the buckets. ALWAYS keep le.
histogram_quantile(0.95,
  sum by (le) (rate(http_request_duration_seconds_bucket[5m])))

# Per job
histogram_quantile(0.95,
  sum by (le, job) (rate(http_request_duration_seconds_bucket[5m])))

# Per job and route
histogram_quantile(0.99,
  sum by (le, job, route) (rate(http_request_duration_seconds_bucket[5m])))

# Average latency: no quantile involved
rate(http_request_duration_seconds_sum[5m])
  / rate(http_request_duration_seconds_count[5m])

# Aggregated average
sum(rate(http_request_duration_seconds_sum[5m]))
  / sum(rate(http_request_duration_seconds_count[5m]))

# Request rate, from the histogram
sum(rate(http_request_duration_seconds_count[5m]))

# Exact fraction under a boundary. Better than a quantile when the boundary exists.
sum(rate(http_request_duration_seconds_bucket{le="0.3"}[5m]))
  / sum(rate(http_request_duration_seconds_count[5m]))

# Requests SLOWER than 1s
sum(rate(http_request_duration_seconds_count[5m]))
  - sum(rate(http_request_duration_seconds_bucket{le="1.0"}[5m]))

# Count in a single bucket range (0.25 to 0.5)
sum(rate(http_request_duration_seconds_bucket{le="0.5"}[5m]))
  - sum(rate(http_request_duration_seconds_bucket{le="0.25"}[5m]))

# Apdex-style score: (satisfied + tolerating/2) / total
(
  sum(rate(http_request_duration_seconds_bucket{le="0.3"}[5m]))
  + sum(rate(http_request_duration_seconds_bucket{le="1.2"}[5m]))
) / 2 / sum(rate(http_request_duration_seconds_count[5m]))
```

### How `histogram_quantile` works

1. Compute `_count` from the `+Inf` bucket.
2. Find the target rank: `φ × count`.
3. Find the bucket containing that rank.
4. **Linearly interpolate** between the bucket's lower and upper bounds.

Consequences you must know:

| Situation | Result |
| --- | --- |
| Quantile falls in the `+Inf` bucket | Returns the **upper bound of the last finite bucket** |
| Quantile falls in the lowest bucket | Interpolates between **0** and that bucket's bound (assumes a 0 lower bound) |
| Fewer than two buckets, or no `le` | `NaN` |
| φ outside `[0, 1]` | `+Inf` or `-Inf` |
| No observations in the window | `NaN` |

**Accuracy is entirely determined by your bucket boundaries.** If you have buckets at 1 and 10 and the true p99 is 2, the interpolated answer will be badly wrong. Put a boundary near the value you care about.

The corollary for SLOs: **put a bucket boundary exactly at your SLO threshold** and compute the ratio directly instead of interpolating a quantile.

## Summaries

A summary computes quantiles **inside the client**, over a sliding time window.

```text
<name>{quantile="0.5"}   gauge
<name>{quantile="0.9"}   gauge
<name>{quantile="0.99"}  gauge
<name>_sum               counter
<name>_count             counter
```

```text
# TYPE rpc_duration_seconds summary
rpc_duration_seconds{quantile="0.5"}  0.012
rpc_duration_seconds{quantile="0.9"}  0.048
rpc_duration_seconds{quantile="0.99"} 0.310
rpc_duration_seconds_sum   1234.5
rpc_duration_seconds_count 98765
```

The critical limitation: **quantiles cannot be aggregated.** There is no mathematically valid way to combine the p99 of instance A with the p99 of instance B.

```promql
avg(rpc_duration_seconds{quantile="0.99"})   # MEANINGLESS
max(rpc_duration_seconds{quantile="0.99"})   # the worst instance's p99, at least defensible
```

To change which quantiles you get, you must **change the code and redeploy**. With a histogram you just query differently.

Summaries are still legitimate when:

- You need an exact single-instance quantile and will never aggregate.
- You want only `_sum` and `_count` and configure **no quantiles at all**, which is cheap and gives you an average.

### Comparison

| | Histogram | Summary |
| --- | --- | --- |
| Quantile computed | **At query time**, in Prometheus | **At instrumentation time**, in the client |
| Aggregatable across instances | **Yes** | **No** |
| Change quantiles later | Yes, just query differently | No, needs a code change |
| Bucket/quantile choice up front | Buckets required | Quantiles required |
| Accuracy | Depends on bucket placement | Configurable error bound, per instance |
| Client CPU cost | Low (just counter increments) | Higher (streaming quantile estimation) |
| Series | 1 per bucket + `+Inf` + `_sum` + `_count` | 1 per quantile + `_sum` + `_count` |
| Label used | **`le`** | **`quantile`** |
| Needs `rate()` on the quantile series | N/A | No, they are gauges |
| Needs `histogram_quantile()` | Yes | No |

**Default to histograms.** That is the documented recommendation.

## Native Histograms

Introduced in Prometheus 2.40 as an experimental feature, stabilising through the 3.x line. Enable with:

```bash
prometheus --enable-feature=native-histograms
```

Instead of fixed buckets, a native histogram uses **exponentially spaced buckets** determined by a **schema** (resolution) parameter, stored as a single sample.

| | Classic | Native |
| --- | --- | --- |
| Buckets | Fixed, chosen at instrumentation time | Automatic, exponential, resolution-based |
| Storage | One series per bucket | **One series total** |
| Series count for one histogram | 13+ | **1** |
| Boundaries | Must be guessed in advance | Cover any range automatically |
| Exposition | Text format | **Protobuf required** for scraping |
| Resolution | Whatever you configured | Adjustable, can be reduced automatically |

```promql
# Native histograms use the same function, but the argument is the metric itself
histogram_quantile(0.95, rate(http_request_duration_seconds[5m]))

# Native-only helpers
histogram_count(rate(http_request_duration_seconds[5m]))
histogram_sum(rate(http_request_duration_seconds[5m]))
histogram_avg(rate(http_request_duration_seconds[5m]))
histogram_fraction(0, 0.3, rate(http_request_duration_seconds[5m]))
histogram_stddev(rate(http_request_duration_seconds[5m]))
```

Note the difference: for a **classic** histogram you pass `rate(..._bucket[5m])`; for a **native** histogram you pass `rate(...[5m])` on the metric itself. And `histogram_fraction(0, 0.3, ...)` is the native equivalent of the `le="0.3"` ratio trick.

Exam-relevant summary: **native histograms give you far fewer series and no bucket guessing, require Protobuf exposition, and are the direction Prometheus is heading.**

## OpenMetrics Extras

OpenMetrics adds a `GaugeHistogram`, whose buckets can go **down** as well as up (it measures a current distribution rather than cumulative observations). It also standardises `_created` timestamps for counters, histograms, and summaries.

## Bucket Selection

Rules:

1. **Put a boundary exactly at every SLO threshold.**
2. Span the actual observed range. Everything above the last finite bucket is invisible except through `_sum`.
3. More buckets means better accuracy and more series. 10 to 15 is typical.
4. Use exponential spacing for latency, since latency distributions are long-tailed.
5. The library defaults are for **sub-second web requests**. Override them for anything else.

```go
// Go generators
prometheus.LinearBuckets(0.1, 0.1, 10)         // 0.1 0.2 ... 1.0
prometheus.ExponentialBuckets(0.001, 2, 15)    // 1ms doubling, 15 buckets
prometheus.DefBuckets                          // the defaults
```

```python
# Python: explicit is best. +Inf is added automatically.
Histogram("x_seconds", "…", buckets=(0.01, 0.05, 0.1, 0.3, 0.5, 1, 2.5, 5, 10))
```

Examples by workload:

| Workload | Buckets (seconds) |
| --- | --- |
| Web request latency | `.005 .01 .025 .05 .1 .25 .3 .5 1 2.5 5 10` |
| Database query | `.0001 .0005 .001 .005 .01 .05 .1 .5 1` |
| Batch job duration | `30 60 120 300 600 1800 3600 7200` |
| Response size (bytes) | `100 1000 10000 100000 1000000 10000000` |

## Recording Rules For Histograms

**Record the bucket rates, keeping `le`. Never record the quantile.**

```yaml
      # Right
      - record: job_le:http_request_duration_seconds_bucket:rate5m
        expr: sum by (job, le) (rate(http_request_duration_seconds_bucket[5m]))

      - record: job_route_le:http_request_duration_seconds_bucket:rate5m
        expr: sum by (job, route, le) (rate(http_request_duration_seconds_bucket[5m]))
```

```promql
# Any quantile, any time
histogram_quantile(0.99, job_le:http_request_duration_seconds_bucket:rate5m)

# And you can still re-aggregate upward
histogram_quantile(0.99, sum by (job, le) (job_route_le:http_request_duration_seconds_bucket:rate5m))
```

Recording `histogram_quantile()` output locks in both the quantile **and** the aggregation level forever.

## Traps

| Wrong | Right | Why |
| --- | --- | --- |
| `histogram_quantile(0.99, http_request_duration_seconds_bucket)` | `histogram_quantile(0.99, rate(..._bucket[5m]))` | Raw counters give the all-time quantile since process start |
| `histogram_quantile(0.99, sum by (job) (rate(..._bucket[5m])))` | `sum by (job, le) (...)` | `le` must survive the aggregation |
| `avg(x{quantile="0.99"})` | Use a histogram | Summary quantiles cannot be aggregated |
| `histogram_quantile` on a summary | Use the `quantile` label directly | Summaries have no `le` |
| `rate(x{quantile="0.99"}[5m])` | Use the value directly | Summary quantile series are **gauges** |
| Trusting a p99 with buckets at 1 and 10 | Add boundaries near the real values | Linear interpolation is only as good as the bounds |
| Using default buckets for a 10-minute job | Define your own | Everything lands in `+Inf` |
| `quantile(0.99, latency_seconds)` | `histogram_quantile(0.99, ...)` | `quantile()` aggregates **across series**, not observations |
| `quantile_over_time(0.99, latency[1h])` for request latency | `histogram_quantile` | That gives the quantile of the **sampled series values** over time, not of individual requests |
| Recording `histogram_quantile()` output | Record the bucket rates with `le` | Locks the quantile and aggregation level |
| Assuming a p99 above the last finite bucket is accurate | Add a higher bucket | It clamps to the last finite bound |

The three "quantile" functions, which are constantly confused:

| Function | Aggregates over | Example |
| --- | --- | --- |
| `quantile(φ, v)` | **Series**, at one instant | "the 90th percentile machine by load" |
| `quantile_over_time(φ, v[d])` | **Time**, per series | "the 90th percentile value this series reached in the last hour" |
| `histogram_quantile(φ, buckets)` | **Observations**, via buckets | "the 90th percentile request latency" |

## Memorise

- Histogram series: **`_bucket{le}` + `_sum` + `_count`**, all **counters**, buckets **cumulative**, `+Inf` always present and equal to `_count`.
- Summary series: **`{quantile}` (gauges) + `_sum` + `_count`**.
- **`le` for histograms, `quantile` for summaries.**
- **Always `rate()` the buckets, always keep `le`** when aggregating.
- `histogram_quantile()` **interpolates linearly**; accuracy depends entirely on bucket placement.
- A quantile in the `+Inf` bucket returns the **last finite bucket's upper bound**.
- **Summary quantiles cannot be aggregated.** Histograms can.
- Quantiles are chosen at **query time** for histograms and at **instrumentation time** for summaries.
- **Put a bucket boundary exactly at your SLO threshold** and compute the ratio directly.
- Series count = **(explicit boundaries + 1 + 2) x label combinations**.
- Default buckets are for **sub-second web latency**.
- Average latency = **`rate(_sum) / rate(_count)`**, valid for both types.
- **Native histograms**: one series instead of many, automatic exponential buckets, need **Protobuf** exposition, use `histogram_quantile(φ, rate(metric[5m]))` and the `histogram_*` helper functions.
- **Record bucket rates with `le`, never the quantile.**
- **`quantile()` across series, `quantile_over_time()` across time, `histogram_quantile()` across observations.**
