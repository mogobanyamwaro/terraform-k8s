# PromQL Reference

The biggest domain at 28%. This is the complete function and operator reference, organised for recall rather than for browsing.

## Data Types

| Type | Description | Example |
| --- | --- | --- |
| **Instant vector** | One sample per series, all at the same timestamp | `up`, `rate(x[5m])` |
| **Range vector** | A range of samples per series | `up[5m]` |
| **Scalar** | A single numeric value, no labels | `42`, `time()`, `scalar(up)` |
| **String** | A string literal. Only used as function arguments | `"foo"` |

Type rules that get tested:

- `rate()`, `increase()`, `*_over_time()` require a **range vector** and return an **instant vector**.
- Aggregations (`sum`, `avg`, ...) require an **instant vector**.
- **You cannot graph a range vector.** `up[5m]` errors in the graph view but works in the table view.
- **You cannot nest a range selector on a function result** directly. `rate(sum(x)[5m])` is invalid; use a subquery: `rate(sum(x)[5m:1m])`.
- `histogram_quantile()` requires an instant vector with an `le` label.

## Selectors

```promql
http_requests_total                              # all series with this name
http_requests_total{job="api"}                   # equality
http_requests_total{job!="api"}                  # inequality
http_requests_total{job=~"api|web"}              # regex match
http_requests_total{job!~"canary.*"}             # regex not-match
{__name__="http_requests_total", job="api"}      # name via __name__
{__name__=~"http_.+"}                            # all metrics matching a pattern
{job="api"}                                      # all metrics from a job
```

| Matcher | Meaning |
| --- | --- |
| `=` | Equal |
| `!=` | Not equal |
| `=~` | Regex match |
| `!~` | Regex not match |

Rules:

- Regexes use **RE2** and are **fully anchored**. `job=~"api"` matches only `api`, not `api-v2`. Use `.*api.*` for a substring.
- RE2 has **no backreferences and no lookahead/lookbehind**.
- A selector must match at least one non-empty matcher. `{job=~".*"}` is invalid on its own because it can match empty; `{job=~".+"}` is fine.
- `=~""` matches series where the label is **absent or empty**. `!=""` matches series where the label **exists and is non-empty**.

### Range and offset

```promql
http_requests_total[5m]                  # range vector, last 5 minutes
http_requests_total offset 1h            # value as of 1 hour ago
http_requests_total[5m] offset 1w        # range vector from a week ago
rate(http_requests_total[5m] offset 1d)  # offset goes on the selector
http_requests_total @ 1609746000         # value at an absolute timestamp
http_requests_total @ start()            # value at the query range start
http_requests_total @ end()              # value at the query range end
```

Duration units: `ms`, `s`, `m`, `h`, `d`, `w`, `y`. Combinable: `1h30m`, `1w2d`. **No months**, because month length varies. `1d` is always 24h and `1y` is always 365d.

Offset must come **after** the range selector and **before** `@`.

## Operators

### Arithmetic

`+` `-` `*` `/` `%` `^`

Between two instant vectors, matching series pair up by identical label sets and **the metric name is dropped** from the result.

```promql
node_memory_MemFree_bytes / node_memory_MemTotal_bytes
node_memory_MemTotal_bytes - node_memory_MemFree_bytes
rate(x[5m]) * 60                          # per-second to per-minute
```

Division by zero gives `+Inf`, `-Inf`, or `NaN` (for `0/0`).

### Comparison

`==` `!=` `>` `<` `>=` `<=`

By default a comparison **filters**: series where the comparison is false are removed.

```promql
up == 0                       # only series where up is 0
node_load1 > 4                # only overloaded instances
```

With the `bool` modifier it **returns 0 or 1** for every series instead of filtering, and drops the metric name.

```promql
up == bool 0                  # 1 or 0 for every series
sum(up == bool 1)             # count of healthy targets
count(node_load1 > bool 4)    # counts ALL series, because none are filtered
```

That last line is a trap: `count(x > bool 4)` counts everything, while `count(x > 4)` counts only those above 4.

### Logical / set

Only defined between two **instant vectors**.

| Operator | Meaning |
| --- | --- |
| `and` | Series on the left that have a matching series on the right. Values come from the **left** |
| `or` | All series on the left, plus series on the right that have no match on the left |
| `unless` | Series on the left that have **no** matching series on the right |

```promql
node_load1 > 4 and node_cpu_utilisation > 0.9
up == 0 or absent(up{job="api"})
node_filesystem_avail_bytes unless on (instance) node_maintenance_mode
```

`unless` is set difference and is the standard way to express exceptions.

### Operator precedence

Highest to lowest:

```text
1. ^            (right associative)
2. * / % atan2
3. + -
4. == != <= < >= >
5. and unless
6. or
```

`^` is right-associative: `2 ^ 3 ^ 2` is `2 ^ 9`, not `8 ^ 2`. All others are left-associative.

## Vector Matching

### One-to-one

Both sides must have **identical label sets** after any `on`/`ignoring`.

```promql
# Restrict matching to specific labels
method_code:http_errors:rate5m / on (method) method:http_requests:rate5m

# Ignore specific labels when matching
method_code:http_errors:rate5m / ignoring (code) method:http_requests:rate5m
```

| Modifier | Meaning |
| --- | --- |
| `on (l1, l2)` | Match using **only** these labels |
| `ignoring (l1, l2)` | Match using all labels **except** these |

`on ()` with an empty list matches everything to everything, useful with a single-series right side.

### Many-to-one and one-to-many

Required when one side has more series than the other. The `group_` modifier points at the **"many"** side.

```promql
# Many on the left, one on the right
rate(errors_total[5m]) / on (job) group_left rate(requests_total[5m])

# One on the left, many on the right
rate(requests_total[5m]) / on (job) group_right rate(errors_total[5m])
```

`group_left(labels)` copies the listed **extra labels from the right side** onto the result. That is the info-metric join pattern:

```promql
sum by (instance) (rate(node_cpu_seconds_total[5m]))
  * on (instance) group_left (version, nodename)
  node_uname_info
```

Remember: **`group_left` means the left side is the "many" side**, and the optional label list comes from the **other** (one) side.

Error messages to recognise:

| Error | Cause |
| --- | --- |
| `found duplicate series for the match group` | Many-to-one without `group_left`/`group_right` |
| `multiple matches for labels: grouping labels must ensure unique matches` | Same, or many-to-many which is never allowed |
| Empty result | No label sets matched at all |

**Many-to-many matching is not possible.** If both sides have duplicates for a match group, you must aggregate one side first.

## Aggregation Operators

Aggregate an instant vector **across series**, reducing dimensions.

| Operator | Result |
| --- | --- |
| `sum` | Sum |
| `min` / `max` | Extremes |
| `avg` | Arithmetic mean |
| `group` | All values become 1, useful for set operations |
| `stddev` / `stdvar` | Population standard deviation / variance |
| `count` | Number of series |
| `count_values("label", x)` | Counts series **by value**, putting the value in a new label |
| `topk(k, x)` / `bottomk(k, x)` | The k series with highest/lowest values, **preserving labels and original values** |
| `quantile(φ, x)` | The φ-quantile **across series**, not over time |
| `limitk(k, x)` / `limit_ratio(r, x)` | Sample k series / a ratio of series (Prometheus 2.50+, experimental) |

```promql
sum(rate(http_requests_total[5m]))                     # one number
sum by (job) (rate(http_requests_total[5m]))           # one per job
sum without (instance) (rate(http_requests_total[5m])) # keep everything except instance
avg by (instance) (rate(node_cpu_seconds_total[5m]))
count by (job) (up)
count(count by (instance) (up))                        # count distinct instances
topk(5, sum by (route) (rate(requests_total[5m])))
count_values("version", node_uname_info)
quantile(0.9, node_load1)                              # 90th percentile ACROSS machines
stddev by (job) (node_load1)
```

Rules:

- `by (...)` **keeps only** the listed labels. `without (...)` **removes** the listed labels and keeps the rest.
- The clause may go before or after the expression: `sum by (job) (x)` and `sum(x) by (job)` are equivalent. Prefer the first.
- The metric name is **always dropped** by aggregation.
- `topk`/`bottomk` **cannot** be used with `by` in the intuitive "top k per group" way without care:

```promql
topk(3, sum by (route) (rate(requests_total[5m])))       # top 3 routes overall
topk(3, sum by (job, route) (rate(requests_total[5m])))  # top 3 (job,route) pairs overall
sum by (job, route) (rate(requests_total[5m]))           # then
topk(3, ...) by (job)                                    # top 3 routes WITHIN each job
```

The last form, `topk(3, expr) by (job)`, is per-group. Without `by`, `topk` is global.

- `quantile()` aggregates **across series at one instant**. To get a quantile **over time**, use `quantile_over_time()`. To get a latency quantile from a histogram, use `histogram_quantile()`. Three different things.
- `topk` and `bottomk` are the only aggregators that **preserve the original labels and values**; the rest produce new series.

## Counter Functions

These require a **counter** and a range vector.

| Function | Returns | Use |
| --- | --- | --- |
| `rate(v[d])` | Per-second average rate, extrapolated, reset-aware | **The default. Use this.** |
| `irate(v[d])` | Per-second rate from the **last two samples only** | High-resolution graphs of volatile counters. **Never for alerting** |
| `increase(v[d])` | Total increase over the window, reset-aware. Equals `rate * seconds` | Human-readable totals |
| `resets(v[d])` | Number of counter resets in the window | Restart detection |

```promql
rate(http_requests_total[5m])
increase(http_requests_total[1h])
sum(rate(http_requests_total[5m])) * 3600        # requests per hour
resets(process_cpu_seconds_total[1h])
```

Critical facts:

- **`rate()` needs at least two samples** in the window. Use a window of **at least 4x the scrape interval** as a rule of thumb.
- `rate()` **extrapolates** to the window boundaries, which is why `increase()` can return non-integer values like `73.4` for an integer counter. This is expected and correct.
- `rate()` handles resets by assuming any decrease is a reset back to zero.
- **`rate()` then `sum()`, never `sum()` then `rate()`.** Summing counters first destroys reset detection.

```promql
sum(rate(http_requests_total[5m]))     # CORRECT
rate(sum(http_requests_total)[5m:])    # WRONG, and needs a subquery to even parse
```

- `avg(rate(x[5m]))` and `rate(avg(x)[5m:])` are different. The first is right.

## Gauge Delta Functions

| Function | Returns |
| --- | --- |
| `delta(v[d])` | Difference between first and last value, extrapolated. **Not** reset-aware |
| `idelta(v[d])` | Difference between the last two samples |
| `deriv(v[d])` | Per-second derivative via simple linear regression |
| `predict_linear(v[d], t)` | Predicted value `t` seconds from now, via linear regression |

```promql
delta(cpu_temp_celsius[2h])
deriv(node_filesystem_avail_bytes[1h])
predict_linear(node_filesystem_avail_bytes[6h], 4 * 3600) < 0
```

`delta`/`deriv`/`predict_linear` are for **gauges**. `rate`/`increase`/`irate` are for **counters**.

## `_over_time` Functions

Aggregate a **range vector over time**, per series.

| Function | Returns |
| --- | --- |
| `avg_over_time(v[d])` | Mean of the values |
| `min_over_time(v[d])` / `max_over_time(v[d])` | Extremes |
| `sum_over_time(v[d])` | Sum of the values |
| `count_over_time(v[d])` | **Number of samples** in the window |
| `stddev_over_time(v[d])` / `stdvar_over_time(v[d])` | Deviation / variance |
| `quantile_over_time(φ, v[d])` | φ-quantile of the values over time |
| `last_over_time(v[d])` | Most recent value |
| `first_over_time(v[d])` | Oldest value in the window |
| `present_over_time(v[d])` | 1 for each series with at least one sample |
| `absent_over_time(v[d])` | 1 if the range vector is **empty** |
| `mad_over_time(v[d])` | Median absolute deviation (experimental) |
| `ts_of_max_over_time`, `ts_of_min_over_time`, `ts_of_last_over_time` | Timestamps of extremes (experimental) |

```promql
avg_over_time(node_load1[1h])
max_over_time(node_load1[24h])
count_over_time(up[1h])                       # samples seen, a scrape-health signal
quantile_over_time(0.95, node_load1[1h])
absent_over_time(myapp_requests_total[30m])
```

`count_over_time(up[1h])` is useful: with a 15s interval you expect 240; fewer means missed scrapes.

## Absent Functions

| Function | Returns |
| --- | --- |
| `absent(v)` | `1` with the selector's labels if the **instant vector is empty**, nothing otherwise |
| `absent_over_time(v[d])` | `1` if the **range vector is empty** |

```promql
absent(up{job="critical-api"})
absent(nonexistent_metric{job="api", env="prod"})       # returns {job="api", env="prod"} = 1
absent_over_time(up{job="critical-api"}[10m])
```

`absent()` only carries labels it can derive from **equality matchers** in the selector. Regex matchers contribute nothing.

These exist because a **vanished series returns no result**, so `up == 0` cannot detect a target that disappeared entirely.

## Histogram Functions

| Function | Purpose |
| --- | --- |
| `histogram_quantile(φ, buckets)` | Estimate the φ-quantile from cumulative buckets |
| `histogram_count(v)` / `histogram_sum(v)` | Count and sum of a **native** histogram |
| `histogram_avg(v)` | Average of a native histogram |
| `histogram_fraction(lower, upper, v)` | Fraction of observations in a range, native histograms |
| `histogram_stddev(v)` / `histogram_stdvar(v)` | Deviation of a native histogram |

```promql
# Classic histogram: ALWAYS rate() the buckets first, and keep le
histogram_quantile(0.95,
  sum by (le, job) (rate(http_request_duration_seconds_bucket[5m])))

# Average latency, no quantile involved
rate(http_request_duration_seconds_sum[5m])
  / rate(http_request_duration_seconds_count[5m])

# Exact ratio below a bucket boundary: better than a quantile when you have the boundary
sum(rate(http_request_duration_seconds_bucket{le="0.3"}[5m]))
  / sum(rate(http_request_duration_seconds_count[5m]))
```

Rules:

- The bucket series **must** retain the `le` label, so `sum by (le, ...)`.
- `histogram_quantile` **interpolates linearly** within the matched bucket, so accuracy depends entirely on bucket boundaries.
- If the quantile falls in the `+Inf` bucket, the result is the **upper bound of the last finite bucket**.
- Results outside the observed range return `NaN`.
- **Summary quantiles cannot be aggregated.** `avg(http_request_duration_seconds{quantile="0.99"})` is mathematically meaningless.

## Time Functions

| Function | Returns |
| --- | --- |
| `time()` | Evaluation timestamp as a Unix scalar |
| `timestamp(v)` | The timestamp of **each sample** in an instant vector |
| `minute(v)`, `hour(v)`, `day_of_month(v)`, `day_of_week(v)`, `day_of_year(v)`, `days_in_month(v)`, `month(v)`, `year(v)` | Calendar components, UTC |

```promql
time() - process_start_time_seconds                  # uptime in seconds
time() - node_boot_time_seconds
(probe_ssl_earliest_cert_expiry - time()) / 86400     # days to cert expiry
timestamp(up)                                        # when each sample was recorded
time() - timestamp(myapp_last_success)               # sample freshness

day_of_week() == 0                                   # Sunday (0 = Sunday, 6 = Saturday)
hour() >= 9 and hour() < 17                          # business hours, UTC
day_of_month() == days_in_month()                    # last day of the month
```

All calendar functions default to `vector(time())` when called with no argument, and all work in **UTC**.

## Type and Label Functions

| Function | Purpose |
| --- | --- |
| `vector(s)` | Convert a scalar to a single-series instant vector with no labels |
| `scalar(v)` | Convert a single-series instant vector to a scalar. `NaN` if not exactly one series |
| `label_replace(v, dst, repl, src, regex)` | Regex-based label rewriting with `$1` capture groups |
| `label_join(v, dst, sep, src1, src2, ...)` | Concatenate labels |
| `sort(v)` / `sort_desc(v)` | Sort by value |
| `sort_by_label(v, l...)` / `sort_by_label_desc(v, l...)` | Sort by label values |
| `info(v, selectors)` | Automatic info-metric join (experimental) |

```promql
vector(1)                                            # always-firing alert expression
vector(0)                                            # a zero fallback for `or`
scalar(count(up))
up or vector(0)                                       # supply a default when empty

label_replace(up, "host", "$1", "instance", "([^:]+):.*")
label_replace(up, "job_upper", "$1", "job", "(.*)")
label_join(up, "target", "/", "job", "instance")
sort_desc(sum by (route) (rate(requests_total[5m])))
```

`label_replace` notes: the regex must match the **whole** source label value or nothing happens. Setting the destination to an empty string **deletes** the label. `__name__` can be rewritten.

## Math Functions

`abs` `ceil` `floor` `round(v, to_nearest)` `exp` `ln` `log2` `log10` `sqrt` `sgn` `clamp(v, min, max)` `clamp_min(v, min)` `clamp_max(v, max)`

Trigonometric: `sin` `cos` `tan` `asin` `acos` `atan` `sinh` `cosh` `tanh` `asinh` `acosh` `atanh` `rad` `deg` `pi()` `atan2`

```promql
abs(delta(cpu_temp[1h]))
round(rate(requests_total[5m]), 0.1)
clamp_max(node_load1, 10)
ceil(sum(rate(requests_total[5m])))
```

## Subqueries

```promql
<instant_vector_expr>[<range>:<resolution>]
```

The resolution defaults to the global `evaluation_interval` if omitted (note the trailing colon is still required).

```promql
max_over_time(rate(http_requests_total[5m])[1h:1m])
max_over_time(rate(http_requests_total[5m])[1h:])
avg_over_time((sum(rate(x[5m])))[6h:5m])
quantile_over_time(0.95, rate(errors_total[5m])[24h:5m])
max_over_time(deriv(node_filesystem_avail_bytes[1h])[6h:10m])
```

Subqueries are how you apply a range function to the **result** of another range function. They are **expensive**: the inner expression is evaluated once per resolution step. `[24h:1m]` evaluates the inner expression 1,440 times.

**The standard optimisation is to replace the inner expression with a recording rule.**

## Evaluation Semantics

### Lookback delta

For an instant vector selector, Prometheus looks **back up to 5 minutes** (`--query.lookback-delta`) for the most recent sample. If none exists, the series is absent from the result.

Consequences:

- A series whose target went away keeps returning its last value for up to 5 minutes, then vanishes.
- A `scrape_interval` **longer than 5 minutes** produces gaps. Never exceed the lookback delta.

### Staleness markers

When a target disappears or a series stops being reported, Prometheus writes an explicit **stale marker**. A series with a stale marker is immediately absent from instant queries, without waiting for the lookback delta.

Stale markers are written when:

- A target is removed from service discovery.
- A previously present series is absent from a successful scrape.
- A rule stops producing a series.

### Range vector boundaries

A range `[5m]` at time `T` is **left-open and right-closed**: `(T-5m, T]`. The sample exactly at `T-5m` is excluded; the sample at `T` is included.

### Step and alignment

`query_range` evaluates the expression independently at each step. Steps are aligned to **absolute Unix time multiples of the step**, not to the start time. That is why graphs from different queries line up.

`@` modifiers and `offset` shift which data is read, not when evaluation happens.

### Query cost

```promql
# The cost model, roughly
samples_scanned ≈ series_selected × samples_per_series_in_window × evaluation_steps
```

Limits:

| Flag | Default | Effect |
| --- | --- | --- |
| `--query.max-samples` | 50,000,000 | Max samples loaded into memory for one query |
| `--query.timeout` | `2m` | Query timeout |
| `--query.max-concurrency` | `20` | Concurrent queries |
| `--query.lookback-delta` | `5m` | Instant selector lookback |

Diagnose with the stats parameter:

```bash
curl -s -G http://localhost:9090/api/v1/query \
  --data-urlencode 'query=sum(rate(http_requests_total[5m]))' \
  --data-urlencode 'stats=true' | jq '.data.stats'
```

## The HTTP API

```bash
# Instant query
curl -s -G localhost:9090/api/v1/query \
  --data-urlencode 'query=up' --data-urlencode 'time=1755500000'

# Range query
curl -s -G localhost:9090/api/v1/query_range \
  --data-urlencode 'query=rate(up[5m])' \
  --data-urlencode 'start=1755490000' \
  --data-urlencode 'end=1755500000' \
  --data-urlencode 'step=15s'

# Metadata
curl -s -G localhost:9090/api/v1/series --data-urlencode 'match[]=up{job="api"}'
curl -s localhost:9090/api/v1/labels
curl -s localhost:9090/api/v1/label/job/values
curl -s localhost:9090/api/v1/metadata

# Status
curl -s localhost:9090/api/v1/targets
curl -s localhost:9090/api/v1/rules
curl -s localhost:9090/api/v1/alerts
curl -s localhost:9090/api/v1/status/tsdb
curl -s localhost:9090/api/v1/status/config

# Federation
curl -s -G localhost:9090/federate --data-urlencode 'match[]={job="api"}'

# Admin (needs --web.enable-admin-api)
curl -X POST -g 'localhost:9090/api/v1/admin/tsdb/delete_series?match[]=up{job="old"}'
curl -X POST localhost:9090/api/v1/admin/tsdb/clean_tombstones
curl -X POST localhost:9090/api/v1/admin/tsdb/snapshot
```

Response `resultType` values: `vector`, `matrix`, `scalar`, `string`.

- `/api/v1/query` returns `vector` (or `scalar`/`string`).
- `/api/v1/query_range` returns `matrix`.
- Querying a range vector via `/api/v1/query` also returns `matrix`.

## Recipes

```promql
# Requests per second, by job
sum by (job) (rate(http_requests_total[5m]))

# Error ratio
sum(rate(http_requests_total{code=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))

# Error ratio per job, safely
sum by (job) (rate(http_requests_total{code=~"5.."}[5m]))
  / sum by (job) (rate(http_requests_total[5m]))

# p95 latency per job
histogram_quantile(0.95, sum by (le, job) (rate(http_request_duration_seconds_bucket[5m])))

# Average latency
sum(rate(http_request_duration_seconds_sum[5m])) / sum(rate(http_request_duration_seconds_count[5m]))

# Fraction under an SLO threshold (exact, needs a bucket at 0.3)
sum(rate(http_request_duration_seconds_bucket{le="0.3"}[5m]))
  / sum(rate(http_request_duration_seconds_count[5m]))

# CPU utilisation per instance
1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m]))

# Number of cores per instance
count by (instance) (count by (instance, cpu) (node_cpu_seconds_total))

# Memory utilisation
1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)

# Filesystem utilisation, excluding virtual filesystems
1 - (node_filesystem_avail_bytes{fstype!~"tmpfs|overlay|squashfs"}
     / node_filesystem_size_bytes{fstype!~"tmpfs|overlay|squashfs"})

# Disk will fill in 4 hours
predict_linear(node_filesystem_avail_bytes[6h], 4*3600) < 0

# Network throughput
sum by (instance) (rate(node_network_receive_bytes_total{device!="lo"}[5m]))

# Targets down
up == 0
count by (job) (up == 0)
count by (job) (up == 1) / count by (job) (up)          # fraction healthy

# Target that vanished entirely
absent(up{job="critical-api"})

# Uptime
time() - process_start_time_seconds

# Restarts in the last hour
changes(process_start_time_seconds[1h])
resets(process_cpu_seconds_total[1h])

# Top 5 metrics by series count
topk(5, count by (__name__) ({__name__=~".+"}))

# Cardinality of one metric
count(http_requests_total)
count(count by (instance) (http_requests_total))

# Week-over-week comparison
sum(rate(http_requests_total[5m]))
  / sum(rate(http_requests_total[5m] offset 1w))

# Max rate seen in the last day
max_over_time(sum(rate(http_requests_total[5m]))[1d:5m])

# Join version info onto a rate
sum by (instance) (rate(http_requests_total[5m]))
  * on (instance) group_left (version) node_uname_info

# Error budget remaining for a 99.9% SLO over 30 days
1 - (sum(increase(http_requests_total{code=~"5.."}[30d]))
     / (0.001 * sum(increase(http_requests_total[30d]))))

# Burn rate
(sum(rate(http_requests_total{code=~"5.."}[1h])) / sum(rate(http_requests_total[1h]))) / 0.001

# Batch job staleness
time() - push_time_seconds > 86400

# Certificate days remaining
(probe_ssl_earliest_cert_expiry - time()) / 86400

# Scrape health
count_over_time(up[1h])
scrape_duration_seconds > 5
scrape_samples_scraped
```

## Traps

| Wrong | Right | Why |
| --- | --- | --- |
| `sum(http_requests_total)` then rate | `sum(rate(http_requests_total[5m]))` | Summing counters destroys reset detection |
| `avg(rate(x[5m]))` for total throughput | `sum(rate(x[5m]))` | Average is per-series, not total |
| `irate()` in an alert | `rate()` | `irate` uses two samples, extremely spiky |
| `rate(gauge[5m])` | `deriv(gauge[5m])` or `delta(gauge[5m])` | `rate` assumes monotonic |
| `delta(counter[5m])` | `increase(counter[5m])` | `delta` is not reset-aware |
| `histogram_quantile(0.99, http_request_duration_seconds_bucket)` | `histogram_quantile(0.99, rate(..._bucket[5m]))` | Raw cumulative counters give the all-time quantile |
| `sum by (job) (rate(..._bucket[5m]))` into `histogram_quantile` | `sum by (job, le) (...)` | `le` must survive |
| `avg(x{quantile="0.99"})` | Use a histogram | Summary quantiles cannot be averaged |
| `quantile(0.99, latency)` for p99 latency | `histogram_quantile(0.99, ...)` | `quantile()` aggregates across series, not observations |
| `count(x > bool 0)` | `count(x > 0)` | `bool` stops the filtering, so everything is counted |
| `up == 0` for a vanished target | `absent(up{...})` | No series means no result |
| `job=~"api"` expecting a substring match | `job=~".*api.*"` | Regexes are fully anchored |
| `rate(x[15s])` with a 15s scrape interval | `rate(x[1m])` | Needs at least two samples |
| `rate(sum(x)[5m])` | `sum(rate(x[5m]))` or a subquery | Cannot range-select a function result |
| `x / y` with mismatched labels | `x / on (l) y` or `ignoring (l)` | Otherwise the result is empty |
| Many-to-one without `group_left` | Add `group_left` | "duplicate series for the match group" |
| `scrape_interval: 10m` | Keep it under 5m | Exceeds the lookback delta, producing gaps |

## Numbers To Memorise

| Thing | Value |
| --- | --- |
| Lookback delta | `5m` |
| Query max samples | 50,000,000 |
| Query timeout | `2m` |
| Query max concurrency | `20` |
| Minimum `rate()` window | 2 samples, practically 4x the scrape interval |
| Range vector boundaries | Left-open, right-closed: `(T-d, T]` |
| Duration units | `ms s m h d w y`, **no months** |
| `1d` | Always 24h |
| `1y` | Always 365d |
| `day_of_week()` | 0 = Sunday, 6 = Saturday |
| Regex engine | RE2, fully anchored, no backreferences |
