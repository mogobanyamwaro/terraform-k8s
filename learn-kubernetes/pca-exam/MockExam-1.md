# Mock Exam 1

**60 questions. 90 minutes. Closed book.**

Weighted like the real exam:

| Domain | Weight | Questions |
| --- | ---: | --- |
| Observability Concepts | 18% | 1-11 |
| Prometheus Fundamentals | 20% | 12-23 |
| PromQL | 28% | 24-40 |
| Instrumentation and Exporters | 16% | 41-50 |
| Alerting and Dashboarding | 18% | 51-60 |

Rules for a useful attempt:

- Set a **90 minute timer**. Do not stop it.
- No notes, no docs, no Prometheus instance.
- Write your answers down before scrolling to the key.
- Flag anything you guess, even if you get it right. Those are the ones to review.

Target: **45 of 60 (75%)**.

---

## Observability Concepts (1-11)

**1.** Which of the following is Prometheus a poor fit for?

- A. Alerting on service error rates
- B. Per-request billing that must be 100% accurate
- C. Graphing CPU utilisation over time
- D. Tracking queue depth

**2.** What are the three pillars of observability?

- A. Metrics, logs, traces
- B. Metrics, alerts, dashboards
- C. Monitoring, logging, alerting
- D. Counters, gauges, histograms

**3.** Which pillar answers "where in the request path did the latency come from"?

- A. Metrics
- B. Logs
- C. Traces
- D. Events

**4.** What is the decisive advantage of the pull model over push?

- A. Lower network usage
- B. Service discovery defines which targets should exist, so missing targets are detectable
- C. Better security
- D. Higher resolution

**5.** Which is a genuine advantage of push over pull?

- A. Automatic target liveness
- B. It works through NAT and firewalls without inbound access
- C. Easier debugging
- D. Rate limiting by the server

**6.** What does the `up` metric represent?

- A. Whether the application is healthy
- B. Whether the last scrape of that target succeeded
- C. Process uptime
- D. Whether the target is in service discovery

**7.** What is an SLI?

- A. A contract with a customer including penalties
- B. A measurement of some aspect of service quality
- C. An internal reliability target
- D. An alerting rule

**8.** Which relationship must hold?

- A. The SLA must be stricter than the SLO
- B. The SLO must be stricter than the SLA
- C. They must be equal
- D. There is no relationship

**9.** For a 99.9% availability SLO, what is the error budget over 30 days?

- A. About 7.2 hours
- B. About 43 minutes
- C. About 4.3 minutes
- D. About 3 days

**10.** What are the Four Golden Signals?

- A. Rate, Errors, Duration, Saturation
- B. Latency, Traffic, Errors, Saturation
- C. Utilisation, Saturation, Errors, Latency
- D. Metrics, Logs, Traces, Events

**11.** RED stands for Rate, Errors, Duration and applies to:

- A. Resources such as CPU and disk
- B. Request-driven services
- C. Batch jobs
- D. Networks

---

## Prometheus Fundamentals (12-23)

**12.** What uniquely identifies a time series?

- A. The metric name
- B. The metric name plus the complete set of label name/value pairs
- C. The `job` and `instance` labels
- D. The `__name__` label alone

**13.** Which label holds the metric name?

- A. `__metric__`
- B. `__name__`
- C. `name`
- D. `metric`

**14.** What is the default `scrape_interval`?

- A. 15s
- B. 30s
- C. 1m
- D. 5m

**15.** What is the default TSDB retention time?

- A. 7 days
- B. 15 days
- C. 30 days
- D. Unlimited

**16.** Where is retention configured?

- A. `global.retention` in `prometheus.yml`
- B. `storage.tsdb.retention` in `prometheus.yml`
- C. A command-line flag, `--storage.tsdb.retention.time`
- D. Per scrape config

**17.** Which block operates on **targets before** the scrape?

- A. `metric_relabel_configs`
- B. `relabel_configs`
- C. `write_relabel_configs`
- D. `alert_relabel_configs`

**18.** A histogram with 10 explicit bucket boundaries and 3 label combinations produces how many series?

- A. 30
- B. 36
- C. 39
- D. 33

**19.** Which is true of OpenMetrics but not the Prometheus text format?

- A. `HELP` and `TYPE` lines
- B. A mandatory `# EOF` terminator
- C. Histograms
- D. Label values

**20.** What is the default block range (head block duration)?

- A. 30 minutes
- B. 2 hours
- C. 6 hours
- D. 24 hours

**21.** Roughly how much disk does one compressed sample use?

- A. 1 to 2 bytes
- B. 8 bytes
- C. 16 bytes
- D. 64 bytes

**22.** How do you reload the configuration without restarting?

- A. `SIGTERM`
- B. `SIGHUP`, or `POST /-/reload` with `--web.enable-lifecycle`
- C. `POST /-/quit`
- D. It is not possible

**23.** A config reload fails. What happens?

- A. Prometheus exits
- B. Prometheus keeps running with the previous configuration
- C. Prometheus starts with an empty configuration
- D. All targets are dropped

---

## PromQL (24-40)

**24.** Which is a range vector?

- A. `up`
- B. `up[5m]`
- C. `rate(up[5m])`
- D. `sum(up)`

**25.** Are PromQL regex matchers anchored?

- A. No
- B. Yes, fully anchored
- C. Only at the start
- D. Configurable

**26.** `job=~"api"` matches which values?

- A. `api`, `api-v2`, `myapi`
- B. Only `api`
- C. `api-v2` only
- D. Nothing

**27.** Which is correct for total requests per second across all instances?

- A. `avg(rate(http_requests_total[5m]))`
- B. `sum(rate(http_requests_total[5m]))`
- C. `rate(sum(http_requests_total)[5m])`
- D. `sum(increase(http_requests_total[5m]))`

**28.** Why must you never `sum()` a counter before applying `rate()`?

- A. It is slower
- B. Summing destroys the per-series information `rate()` needs to detect resets
- C. It is a syntax error
- D. The result would be a scalar

**29.** Which function should be used in alerting rules?

- A. `irate()`
- B. `rate()`
- C. `delta()`
- D. `idelta()`

**30.** What is the minimum requirement for `rate()` to return a value?

- A. One sample in the window
- B. At least two samples in the window
- C. A full window of samples
- D. A monotonic counter with no resets

**31.** What does the `bool` modifier do?

- A. Filters series where the comparison is false
- B. Returns 0 or 1 for every series instead of filtering
- C. Converts to a scalar
- D. Inverts the comparison

**32.** Which set operator returns series on the left with no match on the right?

- A. `and`
- B. `or`
- C. `unless`
- D. `not`

**33.** In `a / on (job) group_left b`, which side is the "many" side?

- A. The left
- B. The right
- C. Both
- D. Neither

**34.** Which is the correct p95 latency from a classic histogram?

- A. `histogram_quantile(0.95, http_request_duration_seconds_bucket)`
- B. `histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))`
- C. `quantile(0.95, http_request_duration_seconds)`
- D. `quantile_over_time(0.95, http_request_duration_seconds[5m])`

**35.** Why can summary quantiles not be aggregated across instances?

- A. They lack an `le` label
- B. There is no mathematically valid way to combine pre-computed quantiles
- C. They are counters
- D. They are stored differently

**36.** Which detects a target that vanished from service discovery entirely?

- A. `up == 0`
- B. `absent(up{job="api"})`
- C. `changes(up[5m]) > 0`
- D. `rate(up[5m]) < 0`

**37.** What is the default lookback delta?

- A. 1 minute
- B. 5 minutes
- C. 15 minutes
- D. 1 hour

**38.** What does `count_over_time(up[1h])` return?

- A. The number of times `up` changed
- B. The number of samples in the last hour
- C. The average of `up`
- D. The uptime fraction

**39.** Which expression gives node CPU utilisation as a fraction?

- A. `rate(node_cpu_seconds_total[5m])`
- B. `1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m]))`
- C. `sum by (instance) (rate(node_cpu_seconds_total{mode!="idle"}[5m]))`
- D. `avg(node_cpu_seconds_total)`

**40.** What is the syntax for a subquery?

- A. `expr[5m]`
- B. `expr[1h:1m]`
- C. `subquery(expr, 1h, 1m)`
- D. `expr offset 1h`

---

## Instrumentation and Exporters (41-50)

**41.** Which is a correctly named counter?

- A. `service_bytes_sent`
- B. `service_sent_bytes_total`
- C. `service_kilobytes_sent_total`
- D. `service_sent_bytes_count`

**42.** What unit should a duration metric use?

- A. Milliseconds
- B. Seconds
- C. Microseconds
- D. Whatever the source uses

**43.** Which label value is dangerous?

- A. HTTP method
- B. Route template
- C. User ID
- D. Status code

**44.** Why default to histograms rather than summaries for latency?

- A. Fewer series
- B. Histogram buckets aggregate across instances and quantiles are chosen at query time
- C. Better accuracy
- D. Summaries are deprecated

**45.** What is node_exporter's default port?

- A. 9090
- B. 9091
- C. 9100
- D. 9115

**46.** Which metric indicates whether a blackbox-probed endpoint is healthy?

- A. `up`
- B. `probe_success`
- C. `probe_duration_seconds`
- D. `probe_http_status_code`

**47.** Which setting is mandatory on the Pushgateway scrape job?

- A. `honor_timestamps: true`
- B. `honor_labels: true`
- C. `metrics_path: /push`
- D. `scheme: https`

**48.** How long does the Pushgateway retain pushed metrics?

- A. 5 minutes
- B. Until the next scrape
- C. Indefinitely, until explicitly deleted
- D. 15 days

**49.** Which component exposes `kube_deployment_spec_replicas`?

- A. cAdvisor
- B. kube-state-metrics
- C. node_exporter
- D. The kubelet

**50.** For a machine-level cron job producing a host-specific metric, which mechanism is preferred?

- A. Pushgateway
- B. node_exporter textfile collector
- C. Remote write
- D. A long-running HTTP server

---

## Alerting and Dashboarding (51-60)

**51.** An alert has `for: 5m`. The expression has just become true for the first time. What is the state?

- A. firing
- B. pending
- C. inactive
- D. resolved

**52.** The expression stops matching partway through the `for` period, then matches again. What happens to the timer?

- A. It resumes
- B. It resets to zero
- C. The alert fires immediately
- D. The alert resolves

**53.** Which component decides **when** an alert fires?

- A. Alertmanager
- B. Prometheus
- C. Grafana
- D. The exporter

**54.** What are the default `group_wait`, `group_interval`, and `repeat_interval`?

- A. 10s, 1m, 1h
- B. 30s, 5m, 4h
- C. 1m, 5m, 12h
- D. 30s, 1m, 4h

**55.** Which suppression mechanism is driven by another alert firing?

- A. A silence
- B. An inhibition rule
- C. A mute time interval
- D. `keep_firing_for`

**56.** Which suppression mechanism is created by a human at runtime?

- A. An inhibition rule
- B. A silence
- C. A mute time interval
- D. `alert_relabel_configs`

**57.** Where should `severity` be placed on an alert?

- A. In `annotations`
- B. In `labels`
- C. In the expression
- D. In the group name

**58.** Can an Alertmanager notification template access the metric value?

- A. Yes, via `.Value`
- B. No. Render it into an annotation with `{{ $value }}` in the Prometheus rule
- C. Yes, via `.Alerts.Value`
- D. Only for gauges

**59.** Which Grafana variable belongs inside `rate()`?

- A. `$__interval`
- B. `$__rate_interval`
- C. `$__range`
- D. `$interval`

**60.** What is the recording rule naming convention?

- A. `metric:level:operations`
- B. `level:metric:operations`
- C. `operations_level_metric`
- D. `metric_level_operations`

---
---

# Answer Key

Do not read this until your timer has stopped.

## Observability Concepts

**1: B.** Prometheus samples on a scrape interval, so it is explicitly documented as unsuitable for per-request accounting or billing.

**2: A.** Metrics, logs, traces.

**3: C.** Traces show the request's journey across services with per-span timing.

**4: B.** Service discovery gives you the intended target list, so a target that never appears is detectable via `up == 0` or `absent()`. With push, a target that never checks in is invisible.

**5: B.** NAT and firewall traversal is the genuine push advantage. A, C, and D are pull advantages.

**6: B.** `up` reflects only whether the **scrape** succeeded. A target can be `up == 1` while the application is broken, which is why `<system>_up` and `probe_success` exist.

**7: B.** SLI = Indicator = measurement.

**8: B.** The SLO must be stricter, so you have room to act before breaching a contract with penalties.

**9: B.** 0.1% of 30 days is about 43.2 minutes.

**10: B.** Latency, Traffic, Errors, Saturation, from the Google SRE book.

**11: B.** RED is for request-driven services. USE is for resources.

## Prometheus Fundamentals

**12: B.** Name plus the complete label set. Changing any label value creates a new series.

**13: B.** `__name__`.

**14: C.** `1m`. Note that most real configs override it to 15s, which is why people get this wrong.

**15: B.** 15 days.

**16: C.** A command-line flag. Retention is not in YAML, and this is a favourite question.

**17: B.** `relabel_configs` operates on targets before the scrape. `metric_relabel_configs` operates on samples after.

**18: C.** 10 boundaries plus the implicit `+Inf` = 11 bucket series, plus `_sum` and `_count` = 13 per combination. 13 x 3 = 39.

**19: B.** `# EOF` is mandatory in OpenMetrics.

**20: B.** 2 hours.

**21: A.** 1 to 2 bytes, thanks to delta-of-delta timestamp and XOR value encoding.

**22: B.** SIGHUP or the lifecycle endpoint.

**23: B.** The previous configuration keeps running, which is why `prometheus_config_last_reload_successful` matters.

## PromQL

**24: B.** `up[5m]`. `rate(up[5m])` returns an instant vector.

**25: B.** Fully anchored, using RE2.

**26: B.** Only exactly `api`, because of anchoring. You would need `.*api.*` for a substring.

**27: B.** `sum(rate(...))`. Option A averages per series; option C is invalid without a subquery.

**28: B.** Reset detection is per series, so summing first makes a restart on one instance look like a decrease in the total.

**29: B.** `rate()`. `irate()` uses only the last two samples and is far too spiky for alerting.

**30: B.** Two samples. This is why a window shorter than two scrape intervals returns nothing.

**31: B.** It stops the filtering and returns 0 or 1 for every series, also dropping the metric name.

**32: C.** `unless` is set difference.

**33: A.** `group_left` means the **left** side has more series. The optional label list in `group_left(...)` comes from the right side.

**34: B.** Rate the buckets, keep `le`. Option A gives the all-time quantile since process start; C and D aggregate the wrong dimension.

**35: B.** There is no valid way to average or sum quantiles. This is a mathematical limitation, not an implementation gap.

**36: B.** `absent()`. If the series is gone, `up == 0` returns nothing at all.

**37: B.** 5 minutes, which is also why `scrape_interval` must stay below 5m.

**38: B.** The number of samples. With a 15s interval you expect 240 in an hour, so fewer indicates missed scrapes.

**39: B.** Average the idle rate across cores and subtract from 1. Option C sums non-idle rates, giving core-seconds rather than a fraction.

**40: B.** `expr[range:resolution]`.

## Instrumentation and Exporters

**41: B.** Base unit `bytes`, `_total` for a counter, unit before `_total`.

**42: B.** Seconds. Always convert in the exporter.

**43: C.** User ID is unbounded.

**44: B.** Aggregatability plus query-time quantile choice.

**45: C.** 9100.

**46: B.** `probe_success`. `up` only tells you whether Prometheus could reach the blackbox exporter.

**47: B.** `honor_labels: true`. Without it, pushed `job` and `instance` become `exported_job` and `exported_instance`.

**48: C.** Indefinitely. There is no TTL, which is the Pushgateway's main hazard.

**49: B.** kube-state-metrics reflects declared API object state.

**50: B.** The textfile collector, because node_exporter is already a target on that host and gives you `node_textfile_mtime_seconds` for staleness.

## Alerting and Dashboarding

**51: B.** `pending`. It only becomes `firing` after `for` has elapsed continuously.

**52: B.** It resets. `for` requires **continuous** truth.

**53: B.** Prometheus. Alertmanager only decides who is notified and how.

**54: B.** 30s, 5m, 4h.

**55: B.** Inhibition.

**56: B.** A silence.

**57: B.** Labels, because routing, grouping, and inhibition all use labels. Annotations are text only.

**58: B.** Alertmanager never receives the value.

**59: B.** `$__rate_interval`, which guarantees at least four scrape intervals of window.

**60: B.** `level:metric:operations`.

---

## Scoring And What To Do Next

| Score | Verdict | Action |
| --- | --- | --- |
| **54-60 (90%+)** | Comfortably ready | Skim `Flashcards.md` and `CheatSheet.md`, then book the exam |
| **45-53 (75-89%)** | Passing, but tighten up | Review every wrong answer against the named deep-dive file, then sit `MockExam-2.md` |
| **36-44 (60-74%)** | Not yet | Identify your weakest domain from the table below, rework those numbered files including the hands-on, then retake this |
| **Below 36** | Significant gaps | Work through `01.md` to `40.md` again with the lab running. Reading is not enough for PromQL |

Map wrong answers to study material:

| Questions wrong | Read |
| --- | --- |
| 1-11 | `01.md`-`07.md`, `SLO.md` |
| 12-23 | `08.md`-`15.md`, `Architecture.md`, `ConfigReference.md`, `Exposition.md`, `Storage.md` |
| 24-40 | `16.md`-`26.md`, `PromQL.md`, `Histograms.md` |
| 41-50 | `27.md`-`32.md`, `Instrumentation.md`, `Exporters.md` |
| 51-60 | `33.md`-`40.md`, `Alertmanager.md`, `RecordingRules.md`, `Grafana.md` |

Also review **anything you guessed correctly**. A lucky guess is a gap.

The questions most people miss on a first attempt are **14 (scrape_interval default is 1m, not 15s), 16 (retention is a flag), 18 (histogram series arithmetic), 26 (regex anchoring), 33 (which side `group_left` refers to), 48 (no Pushgateway TTL), and 51 (pending, not firing)**. If you got those right, you are in good shape.
