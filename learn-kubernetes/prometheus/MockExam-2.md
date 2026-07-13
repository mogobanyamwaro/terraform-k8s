# Mock Exam 2

**60 questions. 90 minutes. Closed book.**

Harder than Mock Exam 1. More scenarios, more "what breaks and why", more configuration reading. Same domain weighting.

| Domain | Weight | Questions |
| --- | ---: | --- |
| Observability Concepts | 18% | 1-11 |
| Prometheus Fundamentals | 20% | 12-23 |
| PromQL | 28% | 24-40 |
| Instrumentation and Exporters | 16% | 41-50 |
| Alerting and Dashboarding | 18% | 51-60 |

Target: **48 of 60 (80%)**. If you can pass this comfortably, the real exam will feel easy.

---

## Observability Concepts (1-11)

**1.** A service reports 0.4% errors continuously for six days. The SLO is 99.9% over 30 days and the alert is `error_ratio > 0.02`. What happens?

- A. The alert fires and the budget is fine
- B. The alert never fires, yet the entire error budget is consumed in under two weeks
- C. The alert fires intermittently
- D. The budget is unaffected because 0.4% is below 2%

**2.** For a 99.9% SLO, what error ratio corresponds to a burn rate of 14.4?

- A. 0.144
- B. 0.0144
- C. 0.00144
- D. 14.4

**3.** In multi-window multi-burn-rate alerting, what is the purpose of the short window?

- A. To reduce query cost
- B. To confirm the burn is still occurring, and to make the alert resolve promptly once it stops
- C. To smooth the data
- D. To detect faster

**4.** Why should a latency SLO use a bucket boundary rather than `histogram_quantile()`?

- A. It is faster
- B. `histogram_quantile()` interpolates within buckets, so accuracy depends on bucket placement; a ratio at an exact boundary is precise
- C. `histogram_quantile()` cannot be used in rules
- D. Buckets are cheaper to store

**5.** Which statement about the pull model is **false**?

- A. Any target can be scraped manually with curl for debugging
- B. Prometheus can rate-limit its own load by choosing the interval
- C. Targets must be reachable from Prometheus
- D. Short-lived batch jobs are handled naturally

**6.** A target is `up == 1` but the application cannot reach its database. What is true?

- A. `up` would be 0
- B. `up` only reflects scrape success; you need an application-level metric or a `<system>_up`-style metric
- C. Prometheus marks the target unhealthy after three scrapes
- D. `scrape_samples_scraped` would be 0

**7.** Which best describes the difference between monitoring and observability?

- A. They are identical
- B. Monitoring watches known failure modes with predefined signals; observability is the property of being able to answer questions you did not anticipate
- C. Observability is just monitoring with more dashboards
- D. Monitoring is for infrastructure, observability for applications

**8.** Which is the primary reason metrics are cheap compared to logs?

- A. Compression
- B. They are aggregated numeric samples with bounded cardinality rather than one record per event
- C. They are stored in memory
- D. They are sampled

**9.** What links a metric observation to a trace?

- A. A label
- B. An exemplar
- C. An annotation
- D. A target label

**10.** USE stands for:

- A. Utilisation, Saturation, Errors
- B. Uptime, Saturation, Efficiency
- C. Utilisation, Speed, Errors
- D. Usage, Saturation, Events

**11.** An SLO is breached but nothing changes in the team's behaviour. What is missing?

- A. A dashboard
- B. An error budget policy
- C. An SLA
- D. Better SLIs

---

## Prometheus Fundamentals (12-23)

**12.** Consider:

```yaml
global:
  external_labels:
    cluster: prod
scrape_configs:
  - job_name: app
    static_configs:
      - targets: ["app:8080"]
```

Which is true of the `cluster` label?

- A. It appears on series stored locally in this Prometheus
- B. It is attached only on remote write, federation, and alerts sent to Alertmanager
- C. It appears in `/targets`
- D. It is dropped on remote write

**13.** A target exposes a metric with a `job` label. Prometheus stores it as `exported_job`. How do you keep the original as `job`?

- A. `honor_timestamps: true`
- B. `honor_labels: true`
- C. `labeldrop` on `job`
- D. It is impossible

**14.** Which of these can be changed by a config reload without a restart?

- A. `--storage.tsdb.retention.time`
- B. `scrape_configs`
- C. `--web.listen-address`
- D. `--storage.tsdb.path`

**15.** What does `scrape_samples_post_metric_relabeling` tell you that `scrape_samples_scraped` does not?

- A. How many samples were exposed by the target
- B. How many samples survived `metric_relabel_configs` and were actually ingested
- C. How many series are new
- D. The scrape duration

**16.** Which relabel action drops labels whose **names** match a regex?

- A. `drop`
- B. `labeldrop`
- C. `labelkeep`
- D. `keep`

**17.** In a relabel rule with no explicit `action`, what is the default?

- A. `keep`
- B. `replace`
- C. `drop`
- D. `labelmap`

**18.** What is the default `separator` when multiple `source_labels` are joined?

- A. `,`
- B. `;`
- C. `|`
- D. A space

**19.** Which is the correct exposition of a histogram bucket line?

- A. `x_bucket{le="0.5"} 12`
- B. `x_bucket{bucket="0.5"} 12`
- C. `x{le="0.5"} 12`
- D. `x_histogram{le="0.5"} 12`

**20.** A histogram is exposed with buckets `le="0.1"`, `le="0.5"`, `le="1"` and no `le="+Inf"`. What is wrong?

- A. Nothing
- B. `+Inf` is required, and its value must equal `_count`
- C. `le` must be sorted descending
- D. `_sum` is missing

**21.** Which `promtool` command validates a configuration file?

- A. `promtool check rules prometheus.yml`
- B. `promtool check config prometheus.yml`
- C. `promtool validate prometheus.yml`
- D. `promtool test config prometheus.yml`

**22.** In agent mode, which capability is lost?

- A. Scraping
- B. Local querying, alerting, and rule evaluation
- C. Service discovery
- D. Relabeling

**23.** Two Prometheus servers scrape the same targets for HA. What deduplicates the resulting alerts?

- A. Prometheus
- B. Alertmanager, which deduplicates identical alerts across its cluster
- C. Grafana
- D. Nothing; you get duplicates

---

## PromQL (24-40)

**24.** What does this return?

```promql
rate(http_requests_total[1m])
```

with a `scrape_interval` of 1m.

- A. The correct per-second rate
- B. Usually nothing, because only one sample falls in the window
- C. An error
- D. The raw counter value

**25.** Which is correct for the error ratio per job?

- A. `sum(rate(http_requests_total{code=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))`
- B. `sum by (job) (rate(http_requests_total{code=~"5.."}[5m])) / sum by (job) (rate(http_requests_total[5m]))`
- C. `rate(http_requests_total{code=~"5.."}[5m]) / rate(http_requests_total[5m])`
- D. `sum by (job, code) (rate(http_requests_total[5m]))`

**26.** Why does option C in the previous question fail?

- A. Syntax error
- B. The left side has a `code` label the right side lacks, so no vector matching occurs
- C. Division by zero
- D. It returns a scalar

**27.** What does `increase()` do that `rate()` does not?

- A. Handles counter resets
- B. Returns the total increase over the window rather than a per-second average
- C. Works on gauges
- D. Extrapolates

**28.** Which is a valid use of `delta()`?

- A. `delta(http_requests_total[5m])`
- B. `delta(node_filesystem_avail_bytes[1h])`
- C. `delta(rate(x[5m])[1h:])`
- D. `delta(up)`

**29.** What does this return when no series match?

```promql
absent_over_time(up{job="api"}[10m])
```

- A. Nothing
- B. `1`
- C. `0`
- D. An error

**30.** Which expression finds the 5 pods using the most CPU?

- A. `topk(5, container_cpu_usage_seconds_total)`
- B. `topk(5, sum by (pod) (rate(container_cpu_usage_seconds_total[5m])))`
- C. `sort_desc(container_cpu_usage_seconds_total)[0:5]`
- D. `limit(5, rate(container_cpu_usage_seconds_total[5m]))`

**31.** What does `predict_linear(node_filesystem_avail_bytes[6h], 4*3600) < 0` mean?

- A. The disk is 4 hours from being full, based on the last 6 hours of linear trend
- B. The disk has been full for 4 hours
- C. Free space fell by 4 hours' worth
- D. There is a 6 hour prediction window

**32.** Which counts distinct label values rather than series?

- A. `count(up)`
- B. `count(count by (job) (up))`
- C. `count_values("job", up)`
- D. `count by (job) (up)`

**33.** Given `a{x="1"} 5` and `b{x="1",y="2"} 3`, what does `a * b` return?

- A. `15`
- B. Nothing, because the label sets do not match exactly
- C. `{x="1"} 15`
- D. An error

**34.** How do you make the previous multiplication work?

- A. `a * on (x) group_right b`
- B. `a * ignoring (y) b`
- C. `a * b ignoring (y)`
- D. Both A and B are valid approaches

**35.** What does the `@` modifier do?

- A. Offsets the query backwards
- B. Evaluates the selector at a fixed absolute timestamp
- C. Selects a label
- D. Anchors a regex

**36.** Which is correct for "the average request duration over 5 minutes"?

- A. `avg(http_request_duration_seconds)`
- B. `rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])`
- C. `histogram_quantile(0.5, ...)`
- D. `avg_over_time(http_request_duration_seconds[5m])`

**37.** `histogram_quantile(0.99, ...)` returns `+Inf`. Why?

- A. There is no data
- B. The 99th percentile falls in the `+Inf` bucket, meaning the highest finite bucket boundary is too low
- C. The buckets are unsorted
- D. `rate()` was not applied

**38.** What is wrong with this expression?

```promql
sum by (le) (rate(x_bucket[5m])) / sum(rate(x_count[5m]))
```

- A. Nothing
- B. The left side has `le` and the right does not, so nothing matches
- C. `x_count` should be `x_bucket`
- D. `sum by (le)` is invalid

**39.** Which returns the number of times a process restarted in the last hour?

- A. `changes(process_start_time_seconds[1h])`
- B. `resets(process_start_time_seconds[1h])`
- C. `rate(process_start_time_seconds[1h])`
- D. `delta(process_start_time_seconds[1h])`

**40.** What does this compute?

```promql
max_over_time(
  sum(rate(http_requests_total[5m]))[1d:5m]
)
```

- A. An error, subqueries cannot wrap aggregations
- B. The peak 5-minute request rate over the last day
- C. The average rate over a day
- D. The rate of the maximum

---

## Instrumentation and Exporters (41-50)

**41.** An application increments a counter **before** doing work, then the work fails. What is wrong?

- A. Nothing
- B. Failures are undercounted; increment counters after the outcome is known, or use separate success and failure counters
- C. The counter will reset
- D. The counter type should be a gauge

**42.** Which is the correct way to instrument in-flight requests?

- A. A counter
- B. A gauge incremented on entry and decremented on exit, ideally in a `finally` block
- C. A histogram
- D. A summary

**43.** A batch job runs every hour. How do you alert when it has not succeeded recently?

- A. `up == 0`
- B. Push a `job_last_success_timestamp_seconds` gauge and alert on `time() - job_last_success_timestamp_seconds > 7200`
- C. `absent(job_runs_total)`
- D. `rate(job_runs_total[1h]) == 0`

**44.** A metrics endpoint's collection code throws an exception. What is the correct behaviour?

- A. Return a 500 so the scrape fails and `up` becomes 0
- B. Return partial metrics silently
- C. Return zeros
- D. Return the previous values

**45.** Which is true of the Prometheus Python client in multiprocess mode?

- A. It works identically to single process
- B. It requires `PROMETHEUS_MULTIPROC_DIR` and a `MultiProcessCollector`, and some features such as certain gauge modes behave differently
- C. It is unsupported
- D. It requires the Pushgateway

**46.** What does `probe_ssl_earliest_cert_expiry` return?

- A. Days until expiry
- B. A Unix timestamp of the earliest certificate expiry
- C. A boolean
- D. Seconds until expiry

**47.** How do you alert on a certificate expiring within 14 days?

- A. `probe_ssl_earliest_cert_expiry < 14`
- B. `probe_ssl_earliest_cert_expiry - time() < 14 * 24 * 3600`
- C. `time() - probe_ssl_earliest_cert_expiry > 14`
- D. `probe_ssl_earliest_cert_expiry < 14 * 86400`

**48.** In the blackbox exporter scrape config, what is the role of this rule?

```yaml
      - target_label: __address__
        replacement: blackbox-exporter:9115
```

- A. It sets the `instance` label
- B. It redirects the actual scrape to the exporter, while the probed URL travels in `__param_target`
- C. It changes the metrics path
- D. It is redundant

**49.** Which exposes container CPU usage in Kubernetes?

- A. kube-state-metrics
- B. cAdvisor, built into the kubelet at `/metrics/cadvisor`
- C. node_exporter
- D. The API server

**50.** Why must you filter `container!=""` on cAdvisor metrics?

- A. To reduce cardinality only
- B. Because empty-container series are the pod-level aggregate, which would double-count
- C. Because they are stale
- D. It is not necessary

---

## Alerting and Dashboarding (51-60)

**51.** Consider:

```yaml
route:
  receiver: default
  group_by: [alertname, cluster]
  routes:
    - matchers: [severity="critical"]
      receiver: pager
    - matchers: [team="db"]
      receiver: db-team
```

A critical alert with `team="db"` goes where?

- A. Both `pager` and `db-team`
- B. Only `pager`, because routing stops at the first match
- C. Only `db-team`
- D. `default`

**52.** How would you make it go to both?

- A. Add `continue: true` to the first route
- B. Reorder the routes
- C. Use `group_by: []`
- D. It is not possible

**53.** A critical alert is inhibiting a warning. The critical alert resolves. What happens to the warning?

- A. It stays suppressed
- B. It is no longer inhibited and will notify on the next group interval
- C. It is deleted
- D. It fires immediately

**54.** What does `group_by: []` mean?

- A. No grouping configuration
- B. All alerts collapse into a single group, so everything is aggregated into one notification stream
- C. Grouping is disabled and every alert notifies individually
- D. It is invalid

**55.** What does `group_by: [...]` (the literal ellipsis) mean?

- A. Group by all labels, disabling aggregation
- B. Group by nothing
- C. Inherit from the parent
- D. Invalid syntax

**56.** An alert fires and notifies. Two minutes later a second alert joins the same group. When is the next notification sent?

- A. Immediately
- B. After `group_interval` from the last notification for that group
- C. After `group_wait`
- D. After `repeat_interval`

**57.** Alertmanager has received an alert, no silence or inhibition applies, routing resolves to a receiver, but no notification arrives. Which metric would you check first?

- A. `alertmanager_alerts`
- B. `alertmanager_notifications_failed_total`
- C. `prometheus_notifications_dropped_total`
- D. `alertmanager_silences`

**58.** Prometheus's `/alerts` shows an alert firing but Alertmanager's UI shows nothing. What is the most likely cause?

- A. A silence
- B. Prometheus cannot reach Alertmanager; check `prometheus_notifications_errors_total` and the `alerting.alertmanagers` config
- C. Inhibition
- D. Wrong `group_by`

**59.** A Grafana rate panel is blank at a 15-minute range but correct at 24 hours. Why?

- A. Missing data
- B. `$__interval` resolves too small at short ranges, giving fewer than two samples in the `rate()` window; use `$__rate_interval`
- C. The data source is down
- D. The unit is wrong

**60.** Which is the correct panel and query for visualising a full latency distribution over time?

- A. A time series panel with `histogram_quantile(0.99, ...)`
- B. A heatmap panel with `sum by (le) (rate(x_bucket[$__rate_interval]))` and legend `{{le}}`
- C. A histogram panel with `x_sum / x_count`
- D. A bar gauge with `topk`

---
---

# Answer Key

## Observability Concepts

**1: B.** 0.4% is a burn rate of 4 on a 99.9% SLO (0.004 / 0.001), which exhausts a 30-day budget in 7.5 days. The static 2% threshold is blind to it. This is precisely why burn-rate alerting exists.

**2: B.** `14.4 × 0.001 = 0.0144`, i.e. 1.44% errors.

**3: B.** Both halves matter. The short window confirms the burn is ongoing, and it also makes the alert resolve without waiting out the long window.

**4: B.** Put a boundary at the SLO threshold and compute the ratio directly.

**5: D.** Short-lived jobs are the pull model's weakness; they may finish before any scrape, which is why the Pushgateway exists.

**6: B.** `up` is scrape-level only.

**7: B.** Known failure modes versus the ability to answer unanticipated questions.

**8: B.** Bounded cardinality and aggregation, rather than one record per event.

**9: B.** An exemplar, which carries a trace ID alongside a sample.

**10: A.** Utilisation, Saturation, Errors, from Brendan Gregg, for resources.

**11: B.** Without an error budget policy, an SLO is decoration.

## Prometheus Fundamentals

**12: B.** `external_labels` are applied on the way **out**: remote write, federation, and alerts. They are not stored locally, which is why querying `cluster="prod"` on the local server returns nothing.

**13: B.** `honor_labels: true` makes the target's labels win over the configured ones.

**14: B.** Only YAML content is reloadable. Command-line flags require a restart.

**15: B.** The post-relabeling count is what actually got ingested, so comparing it to `scrape_samples_scraped` shows how much your `metric_relabel_configs` dropped.

**16: B.** `labeldrop` matches label **names**. `drop` matches label **values** and discards whole samples.

**17: B.** `replace`.

**18: B.** `;`.

**19: A.** `x_bucket{le="0.5"}`. The label must be `le`, and the suffix `_bucket`.

**20: B.** `+Inf` is mandatory and must equal `_count`. Without it `histogram_quantile()` cannot work correctly.

**21: B.** `promtool check config`. Use `promtool check rules` for rule files.

**22: B.** Agent mode scrapes and remote-writes only. No querying, no alerting, no rules, and no local query API.

**23: B.** Alertmanager deduplicates identical alerts. This is the standard HA pattern: two identical Prometheus servers, one Alertmanager cluster.

## PromQL

**24: B.** `rate()` needs at least two samples. With a 1m interval and a 1m window you typically get one, so the result is empty. Rule of thumb: **window of at least 4x the scrape interval**.

**25: B.** You must aggregate both sides by the same labels.

**26: B.** The numerator has `code="5xx"` values that the denominator lacks, so one-to-one matching fails. This is the single most common PromQL mistake.

**27: B.** Total increase over the window, still with reset handling and extrapolation. Both handle resets, so A is wrong.

**28: B.** `delta()` is for **gauges**. Using it on a counter mishandles resets.

**29: B.** `absent_over_time()` returns `1` when nothing matched over the whole range, which is more robust than `absent()` against a single flaky scrape.

**30: B.** Rate first, aggregate by pod, then `topk`.

**31: A.** It extrapolates the last 6 hours of trend 4 hours into the future and asks whether it crosses zero.

**32: B.** `count(count by (job) (up))` counts the number of distinct `job` values. `count_values` counts occurrences of a **sample value**, not a label.

**33: B.** Binary operators between two instant vectors require **identical** label sets by default, so the extra `y` label breaks the match.

**34: D.** Either drop `y` from consideration with `ignoring (y)`, or match on `x` only with `on (x)` plus the appropriate group modifier. Note that `a * b ignoring (y)` is not valid placement, since the modifier follows the operator.

**35: B.** `@` pins the evaluation to an absolute timestamp, e.g. `@ 1609746000` or `@ end()`.

**36: B.** The `_sum` rate divided by the `_count` rate gives the average over the window. Option D would be for a gauge.

**37: B.** The quantile lands above the highest finite boundary. Add higher buckets.

**38: B.** `sum by (le)` keeps `le` on the left while the right side has none, so vector matching yields nothing. You would need `sum(...)` without `by (le)`, or `ignoring (le)`.

**39: A.** `changes()` counts value changes, and `process_start_time_seconds` changes on each restart. `resets()` only counts counter decreases.

**40: B.** The subquery evaluates the inner rate every 5 minutes over the last day, and `max_over_time` takes the peak. Subqueries can absolutely wrap aggregations.

## Instrumentation and Exporters

**41: B.** Increment after the outcome, or keep separate `_total` and failure counters so the ratio is computable.

**42: B.** A gauge with `finally`-style decrement, so an exception does not leak the count upward forever.

**43: B.** The last-success timestamp pattern. `up` does not exist for a job that is not scraped, and `rate()` cannot distinguish "did not run" from "ran and failed".

**44: A.** Fail loudly. A failed scrape sets `up` to 0, which is detectable. Silently returning partial or zeroed data creates false confidence and, for zeros, false alerts.

**45: B.** A shared directory plus `MultiProcessCollector`, with documented behavioural differences.

**46: B.** A Unix timestamp, following the Prometheus convention of exposing absolute timestamps rather than countdowns.

**47: B.** Subtract `time()` and compare against seconds.

**48: B.** The scrape goes to the exporter; the probed target rides along as a URL parameter. `instance` is normally set from `__param_target` in a separate rule so the series identifies the probed URL rather than the exporter.

**49: B.** cAdvisor in the kubelet.

**50: B.** The empty-container series is the pod-level rollup, so including it double-counts.

## Alerting and Dashboarding

**51: B.** Routing takes the **first** matching child and stops.

**52: A.** `continue: true` on the first route allows evaluation to continue to siblings.

**53: B.** Suppression lifts, and the notification goes out on the group's next interval rather than instantly.

**54: B.** `group_by: []` puts everything in one group. This is the opposite of "no grouping" and is a favourite trick question.

**55: A.** The literal `...` groups by all labels, effectively disabling aggregation so each distinct alert notifies separately.

**56: B.** `group_interval` (default 5m) controls notifications about **changes** to an existing group. `group_wait` applies only to the first notification for a new group; `repeat_interval` applies when nothing has changed.

**57: B.** `alertmanager_notifications_failed_total`, broken down by `integration`. That isolates delivery failure from everything upstream.

**58: B.** A delivery gap between the two components. Check `prometheus_notifications_errors_total`, `prometheus_notifications_dropped_total`, and whether the Alertmanager URL is right.

**59: B.** Too few samples in the window. `$__rate_interval` guarantees at least four scrape intervals.

**60: B.** Heatmap plus rated bucket series plus the `{{le}}` legend.

---

## Scoring

| Score | Verdict |
| --- | --- |
| **54-60** | You know this material better than the exam requires |
| **48-53** | Ready. Review the misses and sit the exam |
| **40-47** | Close. This mock is harder than the real thing, so you are probably borderline-passing. Fix your weakest domain first |
| **32-39** | Rework the numbered files for your weak domains with the lab running |
| **Below 32** | Go back to `00.md` and work forward. Do the hands-on sections; PromQL does not stick from reading |

Concept-to-file map for anything you missed:

| Questions | Read |
| --- | --- |
| 1-4, 11 | `SLO.md`, `38.md` |
| 5-10 | `01.md`-`07.md` |
| 12-14, 21-23 | `ConfigReference.md`, `Architecture.md` |
| 15-18 | `Relabeling.md` |
| 19-20 | `Exposition.md`, `Histograms.md` |
| 24-32, 35, 39-40 | `PromQL.md`, `16.md`-`26.md` |
| 33-34, 38 | `PromQL.md` vector matching section |
| 36-37 | `Histograms.md` |
| 41-45 | `Instrumentation.md`, `30.md` |
| 46-50 | `Exporters.md`, `Kubernetes.md` |
| 51-58 | `Alertmanager.md`, `35.md`, `36.md`, `39.md` |
| 59-60 | `Grafana.md`, `37.md` |

## The Distinctions This Exam Was Built To Test

If you can explain each of these out loud without notes, you are ready:

1. `relabel_configs` versus `metric_relabel_configs`, and `drop` versus `labeldrop`.
2. Why `sum()` must never come before `rate()`.
3. Why `rate(x[1m])` is empty at a 1m scrape interval.
4. Why label sets must match exactly for binary operators, and how `on`, `ignoring`, `group_left`, and `group_right` change that.
5. Which side `group_left` refers to.
6. Why summary quantiles cannot be aggregated but histogram buckets can.
7. Why `+Inf` is mandatory and what `histogram_quantile()` returning `+Inf` means.
8. Where `external_labels` are and are not applied.
9. `honor_labels`, and why the Pushgateway needs it.
10. `up` versus `probe_success` versus an application health metric.
11. `for` resetting on any gap.
12. Prometheus decides when an alert fires; Alertmanager decides who hears about it.
13. `group_wait` versus `group_interval` versus `repeat_interval`.
14. `group_by: []` versus `group_by: [...]`.
15. Silence versus inhibition versus mute time interval.
16. Labels route; annotations describe.
17. `$__interval` versus `$__rate_interval`.
18. Burn rate arithmetic, including threshold = burn rate x budget ratio.
19. kube-state-metrics versus cAdvisor versus node_exporter.
20. Textfile collector versus Pushgateway.
