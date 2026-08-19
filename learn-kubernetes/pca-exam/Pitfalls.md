# Pitfalls: The Mistakes That Fail Candidates

Every entry here is something people get wrong under time pressure. Read this after your first mock exam and again the day before.

## 1. Defaults That Are Not What You Assume

| Setting | People say | Actual default |
| --- | --- | --- |
| `scrape_interval` | 15s | **1m** |
| `evaluation_interval` | 15s | **1m** |
| `scrape_timeout` | 30s | **10s** |
| Retention | 30d, or "in YAML" | **15d**, set by a **command-line flag** |
| Block duration | 1h | **2h** |
| Lookback delta | 1m | **5m** |
| `group_wait` | 0 | **30s** |
| `group_interval` | 1m | **5m** |
| `repeat_interval` | 1h | **4h** |
| Relabel `action` | `keep` | **`replace`** |
| Relabel `separator` | `,` | **`;`** |

Why the confusion: nearly every tutorial and Helm chart sets `scrape_interval: 15s`, so people memorise the override rather than the default. The exam asks for the **default**.

Retention deserves special attention. There is no `retention` key in `prometheus.yml`. It is `--storage.tsdb.retention.time` and `--storage.tsdb.retention.size`. Any answer offering a YAML path for retention is a distractor.

## 2. Aggregating Before Rating

```promql
rate(sum(http_requests_total)[5m:])      # WRONG
sum(rate(http_requests_total[5m]))       # RIGHT
```

`rate()` detects counter resets **per series**. If you sum first, one instance restarting makes the total decrease, and `rate()` on the summed series interprets that as a reset, corrupting the result.

The rule, without exception: **rate first, aggregate second.** The same applies to `increase()`, `irate()`, and `delta()`.

## 3. Label Sets Must Match Exactly

```promql
# Returns nothing. The left side has a `code` label the right side lacks.
rate(http_requests_total{code=~"5.."}[5m]) / rate(http_requests_total[5m])

# Correct: aggregate both sides identically.
sum by (job) (rate(http_requests_total{code=~"5.."}[5m]))
  / sum by (job) (rate(http_requests_total[5m]))
```

This is the single most common PromQL error in practice. A binary operator between two instant vectors requires **identical label sets** for one-to-one matching. Fixes:

- Aggregate both sides with the same `by (...)` list. Preferred.
- `on (labels)` to match on a subset.
- `ignoring (labels)` to exclude labels from matching.
- `group_left` / `group_right` for many-to-one.

An empty result from a division is almost always a label mismatch, not missing data.

## 4. `group_left` Refers To The Left

`group_left` means **the left-hand side is the "many" side**. The optional label list, `group_left(nodename)`, names labels to copy **from the right** (the "one") side.

```promql
# Many CPU series on the left, one uname series per instance on the right.
node_cpu_seconds_total * on (instance) group_left (nodename) node_uname_info
```

People reverse this constantly. Say it as: **the modifier points at the many side.**

## 5. Regexes Are Fully Anchored

```promql
{job=~"api"}       # matches ONLY "api"
{job=~"api.*"}     # matches "api", "api-v2"
{job=~".*api.*"}   # matches "myapi", "api-v2"
```

PromQL uses RE2 and wraps every matcher in `^(?:...)$`. The same is true of relabeling regexes. If a "match anything containing X" question offers a bare substring, it is a distractor.

Also: `=~""` matches series where the label is empty **or absent**, because an empty label value is indistinguishable from an absent one.

## 6. `rate()` Needs Two Samples

A window shorter than two scrape intervals returns nothing.

```promql
rate(x[1m])   # empty when scrape_interval is 1m
rate(x[5m])   # fine
```

Rule of thumb: **the range must be at least 4x the scrape interval.** This is also exactly why Grafana's `$__rate_interval` exists, and why a rate panel goes blank at short time ranges but works at long ones.

## 7. Histogram Series Arithmetic

For N explicit bucket boundaries, one label combination produces:

```text
N bucket series
+ 1 for le="+Inf"
+ 1 for _sum
+ 1 for _count
= N + 3
```

10 boundaries and 4 label combinations = **52 series**, not 40 or 48.

Watch the wording. "10 buckets" is ambiguous about whether `+Inf` is included. "10 explicit boundaries" or a listed `buckets: [...]` array means `+Inf` is **additional**.

## 8. `histogram_quantile()` Misuse

```promql
# WRONG: gives the all-time quantile since process start
histogram_quantile(0.95, http_request_duration_seconds_bucket)

# WRONG: drops `le`, so there is nothing to interpolate over
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])))

# RIGHT
histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))
```

Three things must all be true: `rate()` the buckets, **keep `le`**, and quantile first in the argument list.

Interpreting the output:

- **`+Inf`** means the quantile falls in the `+Inf` bucket, so your highest finite boundary is too low.
- **`NaN`** means fewer than two buckets, or no observations in the window.
- The result is **linearly interpolated within the matched bucket**, so its accuracy is entirely a function of bucket placement. It is an estimate, never exact.

## 9. Summaries Cannot Be Aggregated

```promql
# Mathematically meaningless
avg(http_request_duration_seconds{quantile="0.99"})
```

There is no valid way to combine pre-computed quantiles from different instances. This is not an implementation limitation; averaging the 99th percentiles of two instances tells you nothing about the combined 99th percentile.

Consequence: on a multi-instance service, **default to histograms**. Summaries are for a single instance where you need an exact quantile and never aggregate.

You **can** aggregate a summary's `_sum` and `_count` to get an average, because those are counters.

## 10. Counter Versus Gauge Function Confusion

| Function | Correct on | Wrong on |
| --- | --- | --- |
| `rate`, `irate`, `increase` | Counters | Gauges |
| `delta`, `deriv`, `predict_linear` | Gauges | Counters |
| `resets` | Counters | — |
| `changes` | Either | — |

Using `delta()` on a counter mishandles resets. Using `rate()` on a gauge produces nonsense when the gauge decreases.

`irate()` uses only the **last two samples**. It is for high-resolution graphs and **never for alerting**, because it is far too spiky and can miss changes entirely between evaluations.

## 11. `up` Does Not Mean Healthy

`up == 1` means **the last scrape succeeded**. That is all. The application may be entirely broken.

- For a blackbox-probed target, the health metric is **`probe_success`**. `up` only tells you the blackbox exporter itself responded.
- For an exporter fronting a database, the health metric is typically **`<system>_up`**, e.g. `mysql_up`. `up` only reflects the exporter.
- For an application, you need explicit health metrics such as dependency reachability.

This **two-level health** distinction appears in exam scenarios repeatedly.

## 12. `external_labels` Are Not Stored Locally

```yaml
global:
  external_labels:
    cluster: prod
```

These are attached on the way **out**: remote write, federation, and alerts sent to Alertmanager. They are **not** added to locally stored series, so querying `up{cluster="prod"}` on that same server returns nothing.

They exist so a central system can distinguish sources, and so Alertmanager can tell two HA replicas apart while still deduplicating.

## 13. `relabel_configs` Versus `metric_relabel_configs`

| | `relabel_configs` | `metric_relabel_configs` |
| --- | --- | --- |
| When | **Before** the scrape | **After** the scrape |
| Acts on | **Targets** | **Samples** |
| Sees `__meta_*` | Yes | No |
| Sees `__name__` | No | Yes |
| Typical use | Filter targets, rewrite `__address__`, promote metadata | Drop expensive metrics, drop high-cardinality labels |

Two consequences worth internalising:

- You **cannot** filter by metric name in `relabel_configs`, because no metrics have been fetched yet.
- Dropping samples in `metric_relabel_configs` does **not** save scrape bandwidth. The data is fetched, then discarded. It saves storage and memory only.

And `drop` is not `labeldrop`: `drop` discards whole samples based on label **values**; `labeldrop` removes labels by **name**, leaving the samples.

## 14. Cardinality Is Multiplicative

A metric's series count is the **product** of its labels' distinct values.

```text
5 methods × 20 routes × 8 status codes = 800 series
add 1000 user IDs                       = 800,000 series
```

Never label with: user ID, email, session ID, request ID, full URL with query string, timestamp, or a raw error message.

In Kubernetes specifically, `pod` changes on every restart and `pod_template_hash` on every deploy. Aggregate away `pod` early, and drop the hash labels.

Diagnose with `/tsdb-status`, `promtool tsdb analyze`, `scrape_series_added`, or:

```promql
topk(10, count by (__name__) ({__name__=~".+"}))
```

## 15. `for` Requires Continuous Truth

An alert with `for: 10m` goes `pending` when the expression first matches, and `firing` only after **10 uninterrupted minutes**. A **single** evaluation where the expression does not match resets the timer to zero. It does not resume.

Two consequences:

- A flapping condition with a long `for` may never fire at all. That is what `keep_firing_for` addresses on the resolution side, and it is why you should smooth the expression rather than lengthening `for`.
- Restarting Prometheus loses pending state unless `ALERTS_FOR_STATE` is restored from storage.

## 16. Prometheus Fires, Alertmanager Notifies

| Prometheus | Alertmanager |
| --- | --- |
| Evaluates expressions | Receives alerts |
| Applies `for` | Deduplicates |
| Decides **when** an alert fires | Inhibits, silences |
| Attaches labels and annotations | Routes to receivers |
| Sends to Alertmanager | Groups, applies timers |
| | Sends notifications |

Alertmanager has **no** access to your metrics, cannot evaluate PromQL, and cannot see the alert's numeric value unless you rendered it into an annotation with `{{ $value }}` in the Prometheus rule. "Change the threshold in Alertmanager" is always wrong.

## 17. The Three Alertmanager Timers

| Timer | Default | Applies when |
| --- | ---: | --- |
| `group_wait` | 30s | The **first** notification for a **new** group. Buffers so related alerts arrive together |
| `group_interval` | 5m | A notification about **changes** to an existing group |
| `repeat_interval` | 4h | Re-notification when **nothing has changed** |

The distinction that gets tested: an alert joining an existing group waits for `group_interval`, **not** `group_wait`.

And `repeat_interval` cannot be shorter than `group_interval` in effect, since re-notification is checked on group intervals.

## 18. `group_by: []` Means One Group, Not No Grouping

```yaml
group_by: []       # ALL alerts collapse into a SINGLE group
group_by: [...]    # group by ALL labels, i.e. no aggregation
```

These are opposites, and both are counter-intuitive. `[]` is maximum aggregation. The literal ellipsis `[...]` is minimum aggregation.

Also: `group_by` **must** include any label used in `group_by` on child routes for grouping to behave predictably, and it should generally include `alertname` plus the labels that identify the affected thing.

## 19. Silence Versus Inhibition Versus Mute Interval

| Mechanism | Created by | Triggered by | Configured in |
| --- | --- | --- | --- |
| **Silence** | A human, at runtime | Matchers you supply, with a time window | UI, `amtool`, API. **Not the config file** |
| **Inhibition** | Config | **Another alert firing** | `inhibit_rules` in `alertmanager.yml` |
| **Mute time interval** | Config | A **schedule** | `time_intervals` + `mute_time_intervals` |

A silence cannot be defined in `alertmanager.yml`. An inhibition rule cannot be created at runtime. Questions swap these deliberately.

Inhibition needs three parts: `source_matchers`, `target_matchers`, and **`equal`**, which lists labels that must match between source and target. **Omitting `equal` means a critical alert in one cluster suppresses warnings everywhere**, which is the classic misconfiguration.

## 20. Labels Route, Annotations Describe

| Labels | Annotations |
| --- | --- |
| Part of the alert's **identity** | Purely informational |
| Used for **routing, grouping, inhibition, silencing** | Used for notification text |
| Must be **low cardinality** | Free text, templated |
| `severity`, `team`, `cluster`, `service` | `summary`, `description`, `runbook_url` |

Putting `severity` in annotations breaks routing silently. Putting `{{ $value }}` in a label changes the alert's identity on every evaluation, creating a new alert each time and defeating both `for` and deduplication. **Never template a value into a label.**

## 21. Pushgateway Misuse

Three separate traps:

1. **`honor_labels: true` is mandatory** on the Pushgateway scrape job. Without it, the pushed `job` and `instance` labels become `exported_job` and `exported_instance`, and every metric gets attributed to the Pushgateway itself.
2. **Pushed metrics never expire.** There is no TTL. A decommissioned job's last values persist forever until you `DELETE` them, so alerts keep firing on a job that no longer exists.
3. **It is not a push gateway for services.** It is for **service-level batch jobs**. Using it as a general push proxy loses `up`, makes the Pushgateway a single point of failure, and breaks instance-level health.

For **machine-level** cron output, the **node_exporter textfile collector** is the better mechanism, because node_exporter is already a target on that host and `node_textfile_mtime_seconds` gives you staleness detection for free.

## 22. The Kubernetes Metric Trio

| | Source | Prefix | Answers |
| --- | --- | --- | --- |
| **kube-state-metrics** | The **API server** | `kube_*` | What the cluster **declares** |
| **cAdvisor** | **cgroups**, inside the kubelet at `/metrics/cadvisor` | `container_*` | What containers **use** |
| **node_exporter** | Host `/proc`, `/sys` | `node_*` | What the **machine** is doing |

Common errors:

- Expecting kube-state-metrics to report CPU usage. It does not.
- Expecting cAdvisor to know about Deployments. It does not.
- Deploying cAdvisor separately in Kubernetes. It is already in the kubelet.
- Forgetting `container!=""` on cAdvisor metrics, which double-counts against the pod-level aggregate.
- Using `container_memory_usage_bytes` for OOM prediction. Use **`container_memory_working_set_bytes`**, because the former includes reclaimable page cache.

## 23. Service Discovery Role Choice

Using `role: service` to scrape application metrics load-balances across pods, so consecutive scrapes hit different instances. Counters appear to jump around and reset. Use **`role: endpoints`** or **`role: endpointslice`** for metrics, and reserve `service` and `ingress` for **blackbox probing**.

And when Kubernetes SD returns nothing at all, check **RBAC** first. It fails silently.

## 24. Grafana Interval Variables

```promql
rate(x[$__interval])         # blank at short time ranges
rate(x[$__rate_interval])    # correct
```

`$__rate_interval` = `max($__interval + scrape_interval, 4 × scrape_interval)`, which guarantees enough samples. It only works if the data source's **`timeInterval` is set to your actual scrape interval**.

Two more Grafana traps:

- A **multi-value variable** interpolates as `(a|b|c)`, so it needs **`=~`**. Using `=` silently returns nothing.
- A ratio of 0 to 1 needs the **`percentunit`** unit. Choosing `percent` displays `0.05` as `0.05%` instead of `5%`.

## 25. Recording Rule Semantics

- Within a group, rules evaluate **sequentially in declaration order**, so a rule may depend on an earlier rule in the same group.
- Across groups, evaluation is **parallel**, so a rule must never depend on a rule in a different group.
- The naming convention is **`level:metric:operations`**, e.g. `job:http_requests:rate5m`. Colons are reserved for exactly this and must never appear in a directly instrumented metric name.
- Recording rules **cannot backfill on their own**; historical data requires `promtool tsdb create-blocks-from rules`.

## 26. Alerting On Causes Instead Of Symptoms

Alerting on high CPU, a full cache, or a restarted pod produces noise, because none of those necessarily affect users. Alert on **symptoms**: elevated error ratio, elevated latency, dropped throughput, stale data.

Every paging alert must pass three tests: is it **urgent**, is it **actionable**, and does it reflect **user impact**? If any answer is no, it belongs in a ticket or a dashboard, not on a pager.

Corollary: a **static error threshold** is blind to slow burns. A steady 0.4% error rate never trips a `> 2%` alert, yet it exhausts a 99.9% budget in 7.5 days. That is the case for **burn-rate alerting**.

## 27. Burn Rate Arithmetic

```text
error budget = 1 - SLO
burn rate    = observed error ratio / error budget ratio
threshold    = burn rate × error budget ratio
```

For a 99.9% SLO, budget ratio 0.001:

- 14.4x → **0.0144**
- 6x → **0.006**
- 3x → **0.003**

The standard page-level pairs are **1h long window guarded by 5m at 14.4x**, and **6h guarded by 30m at 6x**. The short window's job is twofold: confirm the burn is still happening, and make the alert **resolve promptly** rather than lingering for the whole long window.

Always precompute long-window rates with **recording rules**. Evaluating `rate(x[6h])` every 15 seconds is extremely expensive.

## 28. Prometheus's Documented Limitations

Prometheus is explicitly **not** suitable for:

- **Billing-grade accuracy.** Sampling means individual events are lost.
- **Event or request logging.** Use a log system.
- **Per-request tracing.** Use a tracing system.
- **Long-term durable storage by itself.** Local TSDB is not clustered or replicated. Use remote write to Thanos, Mimir, or similar.
- **High-cardinality dimensions** such as per-user data.

There is **no clustering**. HA means two independent servers scraping the same targets, with Alertmanager deduplicating the alerts. Anyone offering "Prometheus replicates its TSDB across nodes" is offering a distractor.

## 29. `absent()` Versus `up == 0`

If a target disappears from service discovery entirely, its `up` series stops existing, so `up == 0` returns **nothing** and the alert never fires. Use **`absent(up{job="api"})`**, or better, **`absent_over_time(up{job="api"}[10m])`**, which is robust against a single flaky evaluation.

More generally: you cannot alert on the absence of a series with a comparison. You need `absent`, `absent_over_time`, or a `unless` against a known-good set.

## 30. Reload Behaviour

- Reload with **`SIGHUP`** or **`POST /-/reload`**, and the latter requires **`--web.enable-lifecycle`**.
- Only **YAML** content is reloadable. Every **command-line flag**, including retention, storage path, and listen address, requires a restart.
- If a reload **fails**, Prometheus keeps running the **previous** configuration. It does not exit and does not go empty. This is why `prometheus_config_last_reload_successful` matters: a silent failure means your changes are simply not in effect.
- **`file_sd_configs`** target files reload automatically on change, with no signal needed. That is the whole point of file-based SD.

## Quick Self-Test

If any of these makes you pause, go back to the corresponding file.

1. Why is `rate(sum(x)[5m:])` wrong?
2. Why does `rate(a{code="500"}[5m]) / rate(a[5m])` return nothing?
3. Which side does `group_left` refer to?
4. How many series does a histogram with 12 explicit boundaries and 5 label combinations create?
5. What does `histogram_quantile()` returning `+Inf` mean?
6. Why can you not average summary quantiles?
7. Where are `external_labels` applied?
8. What is the difference between `drop` and `labeldrop`?
9. What happens to a `for` timer when the expression stops matching for one evaluation?
10. Which component applies `for`?
11. When does `group_interval` apply rather than `group_wait`?
12. What does `group_by: []` do?
13. What breaks if you omit `equal` from an inhibition rule?
14. Why must `honor_labels: true` be set on the Pushgateway job?
15. Which component exposes `container_memory_working_set_bytes`?
16. Why does `role: service` corrupt counter rates?
17. Why is a rate panel blank at a 15-minute range but fine at 24 hours?
18. What is the 14.4x threshold for a 99.9% SLO?
19. What happens when a config reload fails?
20. Why does `up == 0` fail to detect a target removed from service discovery?

Answers, in order: reset detection is per series; label sets differ; the left; 75; the highest finite bucket is too low; there is no valid way to combine pre-computed quantiles; remote write, federation, and alerts, not local storage; values versus label names; it resets to zero; Prometheus; when an alert joins an existing group; collapses everything into one group; a critical alert anywhere suppresses warnings everywhere; otherwise pushed `job` and `instance` become `exported_*`; cAdvisor, inside the kubelet; it load-balances across pods; `$__interval` gives fewer than two samples in the window; 0.0144; the previous config keeps running; the series no longer exists, so use `absent_over_time`.
