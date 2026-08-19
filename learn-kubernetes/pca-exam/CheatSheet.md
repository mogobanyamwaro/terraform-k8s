# Exam-Day Cheat Sheet

The last thing to read before you sit the exam. Everything here is memorisation-grade.

## Exam Facts

| | |
| --- | --- |
| Name | Prometheus Certified Associate (PCA) |
| Format | Multiple choice, online, proctored |
| Questions | ~60 |
| Duration | 90 minutes |
| Passing score | ~75% |
| Retakes | One free retake |
| Validity | 2 years (renewable at 3 years from purchase in current policy) |
| Documentation access | **None.** No browsing, closed book |

Domains and weights:

| Domain | Weight |
| --- | ---: |
| **PromQL** | **28%** |
| **Prometheus Fundamentals** | **20%** |
| **Observability Concepts** | **18%** |
| **Alerting and Dashboarding** | **18%** |
| **Instrumentation and Exporters** | **16%** |

PromQL is the largest single block. If you are short on time, spend it there.

## Strategy During The Exam

1. **First pass:** answer everything you know immediately. Flag the rest. Most people finish this pass in 35-45 minutes.
2. **Second pass:** work the flagged questions. Eliminate wrong options before choosing.
3. **Third pass:** revisit only genuine unknowns. Never leave a blank; there is no negative marking.
4. Read the question **twice** when it contains "not", "except", "least", or "always".
5. When two options look right, ask which is **more specific to Prometheus's documented behaviour**. That is usually the intended answer.
6. Watch for defaults. Many questions are just "what is the default value of X".

Distractor patterns that repeat:

- `15s` offered as the default `scrape_interval` (it is **1m**).
- Retention shown as a YAML key (it is a **flag**).
- `firing` offered where the answer is `pending`.
- `rate(sum(...))` offered where the answer is `sum(rate(...))`.
- `up` offered where the answer is `probe_success`.
- Histogram series counts that forget `+Inf`, `_sum`, and `_count`.
- `group_left` described as "the right side has more series".
- `group_by: []` described as "grouping disabled".

## The Twenty Facts Most Likely To Appear

1. Default `scrape_interval` and `evaluation_interval` are **1m**; `scrape_timeout` is **10s**.
2. Retention defaults to **15d** and is set by **command-line flags**, not YAML.
3. A series is identified by **name + full label set**; the name lives in **`__name__`**.
4. **`up`** means the last **scrape** succeeded, nothing more.
5. `relabel_configs` acts on **targets before** the scrape; `metric_relabel_configs` on **samples after**.
6. Default relabel action is **`replace`**; default separator is **`;`**; regexes are **fully anchored**.
7. A histogram with N explicit boundaries yields **N + 3** series. **`le="+Inf"` is mandatory** and equals `_count`.
8. **Always `sum(rate(x[5m]))`, never `rate(sum(x)[5m])`.**
9. `rate()` needs **at least two samples**; use a window of **4x the scrape interval**.
10. Binary operators need **identical label sets**; fix with `on`/`ignoring`, and **`group_left` means the left side is the "many" side**.
11. `histogram_quantile(q, sum by (le) (rate(x_bucket[5m])))` — keep `le`, rate the buckets.
12. **Summary quantiles cannot be aggregated.** Histograms can.
13. Alert states are **inactive → pending → firing**; `for` must be **continuously** true.
14. **Prometheus decides when an alert fires. Alertmanager decides who is notified.**
15. Alertmanager defaults: **`group_wait` 30s, `group_interval` 5m, `repeat_interval` 4h**.
16. Alertmanager routing takes the **first match** unless `continue: true`.
17. **Labels route; annotations describe.** `severity` goes in labels.
18. Pushgateway needs **`honor_labels: true`** and **never expires** data.
19. **kube-state-metrics = `kube_*` object state. cAdvisor = `container_*` usage, inside the kubelet. node_exporter = `node_*` host.**
20. In Grafana, use **`$__rate_interval`** inside `rate()`.

## PromQL Patterns To Have Memorised

```promql
# Rate
sum by (job) (rate(http_requests_total[5m]))

# Error ratio, both sides aggregated identically
sum by (job) (rate(http_requests_total{code=~"5.."}[5m]))
  / sum by (job) (rate(http_requests_total[5m]))

# Quantile from a histogram
histogram_quantile(0.99, sum by (le, job) (rate(http_request_duration_seconds_bucket[5m])))

# Average duration
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])

# Ratio under a threshold, exact
sum(rate(http_request_duration_seconds_bucket{le="0.3"}[5m]))
  / sum(rate(http_request_duration_seconds_count[5m]))

# CPU utilisation fraction
1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m]))

# Memory used fraction
1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)

# Disk will fill within 4 hours
predict_linear(node_filesystem_avail_bytes{fstype!~"tmpfs"}[6h], 4*3600) < 0

# Restarts
changes(process_start_time_seconds[1h]) > 0

# Missing target
absent(up{job="api"}) == 1
absent_over_time(up{job="api"}[10m])

# Top consumers
topk(5, sum by (pod) (rate(container_cpu_usage_seconds_total{container!=""}[5m])))

# Peak rate over a day
max_over_time(sum(rate(http_requests_total[5m]))[1d:5m])

# Cardinality of a metric
count(count by (__name__) ({__name__=~".+"}))
topk(10, count by (job) ({__name__=~".+"}))

# Certificate expiry
probe_ssl_earliest_cert_expiry - time() < 14 * 24 * 3600

# Join usage to a limit across two exporters
sum by (namespace, pod) (container_memory_working_set_bytes{container!=""})
  / sum by (namespace, pod) (kube_pod_container_resource_limits{resource="memory"})

# Set difference: objects lacking a property
kube_pod_container_info unless on (namespace, pod, container)
  kube_pod_container_resource_requests{resource="cpu"}

# Copy a label from a one-side series
node_cpu_seconds_total * on (instance) group_left (nodename) node_uname_info
```

## Config Skeletons

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  scrape_timeout: 10s
  external_labels:
    cluster: prod            # applied on remote write, federation, alerts only

rule_files:
  - /etc/prometheus/rules/*.yml

alerting:
  alertmanagers:
    - static_configs:
        - targets: ["alertmanager:9093"]

scrape_configs:
  - job_name: node
    static_configs:
      - targets: ["node1:9100", "node2:9100"]
    relabel_configs:
      - source_labels: [__address__]
        regex: '([^:]+):\d+'
        target_label: host
        replacement: $1
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'node_scrape_collector_.*'
        action: drop
```

```yaml
# rules
groups:
  - name: example
    interval: 30s
    rules:
      - record: job:http_requests:rate5m
        expr: sum by (job) (rate(http_requests_total[5m]))

      - alert: HighErrorRate
        expr: |
          sum by (job) (rate(http_requests_total{code=~"5.."}[5m]))
            / sum by (job) (rate(http_requests_total[5m])) > 0.05
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: "{{ $labels.job }} error ratio is {{ $value | humanizePercentage }}"
          runbook_url: https://runbooks.example.com/HighErrorRate
```

```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m

route:
  receiver: default
  group_by: [alertname, cluster, service]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  routes:
    - matchers: [severity="critical"]
      receiver: pager
      continue: true
    - matchers: [team=~"db|storage"]
      receiver: db-team

inhibit_rules:
  - source_matchers: [severity="critical"]
    target_matchers: [severity="warning"]
    equal: [alertname, cluster, service]

receivers:
  - name: default
  - name: pager
    pagerduty_configs:
      - routing_key: xxx
        send_resolved: true      # false by default for PagerDuty
  - name: db-team
    slack_configs:
      - api_url: https://hooks.slack.com/...
        channel: "#db-alerts"
```

## Commands

```bash
# Validation
promtool check config prometheus.yml
promtool check rules rules/*.yml
promtool check metrics < metrics.txt
promtool test rules tests.yml
promtool check service-discovery prometheus.yml node

# Query
promtool query instant http://localhost:9090 'up == 0'
promtool query range   http://localhost:9090 'rate(x[5m])' --start=... --end=... --step=15s
promtool query series  --match='{__name__=~"node_.*"}' http://localhost:9090
promtool query labels  http://localhost:9090 job

# TSDB
promtool tsdb analyze /var/lib/prometheus
promtool tsdb list /var/lib/prometheus

# Reload and health
kill -HUP $(pidof prometheus)
curl -X POST http://localhost:9090/-/reload
curl http://localhost:9090/-/healthy
curl http://localhost:9090/-/ready

# Inspect
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job:.labels.job, health, lastError}'
curl -s http://localhost:9090/api/v1/rules   | jq '.data.groups[].rules[] | {name, health, state}'
curl -s http://localhost:9090/api/v1/status/tsdb | jq '.data.seriesCountByMetricName[:10]'
curl -s 'http://localhost:9090/api/v1/query?query=up' | jq

# Alertmanager
amtool alert query
amtool alert query alertname=HighErrorRate
amtool silence add alertname=HighErrorRate --duration=2h --comment="maintenance"
amtool silence query
amtool silence expire <id>
amtool config routes test --config.file=alertmanager.yml severity=critical team=db
amtool check-config alertmanager.yml

# Pushgateway
echo 'job_duration_seconds 42' | curl --data-binary @- http://pg:9091/metrics/job/backup/instance/db1
curl -X DELETE http://pg:9091/metrics/job/backup/instance/db1
```

## Confusion Pairs

| A | B | The distinction |
| --- | --- | --- |
| `relabel_configs` | `metric_relabel_configs` | Targets before the scrape / samples after |
| `drop` | `labeldrop` | Discards samples by label **value** / removes labels by **name** |
| `rate` | `irate` | Whole-window average, for alerts / last two samples, for graphs |
| `rate` | `increase` | Per-second / total over the window |
| `delta` | `increase` | Gauges / counters |
| `changes` | `resets` | Any value change / counter decreases only |
| `absent` | `absent_over_time` | Missing now / missing over a whole range |
| `count` | `count_values` | Number of series / occurrences of a sample value |
| `by` | `without` | Keep listed labels / keep everything else |
| `on` | `ignoring` | Match on only these / match on all but these |
| `group_left` | `group_right` | Left is "many" / right is "many" |
| Histogram | Summary | Buckets, aggregatable, query-time quantiles / pre-computed, not aggregatable |
| Counter | Gauge | Only increases, always `rate()` it / any direction, read directly |
| `up` | `probe_success` | Scrape of the exporter worked / the probed target is healthy |
| `pending` | `firing` | Within `for` / `for` has elapsed |
| Labels | Annotations | Identify and route / describe |
| `group_wait` | `group_interval` | First notification for a new group / notifications about changes |
| `group_interval` | `repeat_interval` | Something changed / nothing changed |
| Silence | Inhibition | Human-created, matcher-based / triggered by another firing alert |
| Silence | Mute time interval | Ad-hoc runtime / configured schedule |
| `group_by: []` | `group_by: [...]` | One group for everything / a group per unique label set |
| `$__interval` | `$__rate_interval` | Panel resolution / at least 4 scrape intervals |
| `percent` | `percentunit` | Value already 0-100 / ratio 0-1 |
| Textfile collector | Pushgateway | Machine-level cron output / service-level batch jobs |
| kube-state-metrics | cAdvisor | Declared object state / container resource usage |
| Server mode | Agent mode | Full features / scrape and remote write only |
| WAL | Block | Crash-recovery log for the head / immutable 2h on-disk unit |
| SLI | SLO | Measurement / internal target |
| SLO | SLA | Internal target / external contract with penalties |
| RED | USE | Services / resources |

## Diagnosis Order

**Metrics missing:**

```text
/service-discovery  -> was the target discovered? did relabeling drop it?
/targets            -> is it up? what is lastError?
curl the endpoint   -> does the target actually expose it?
scrape_samples_scraped vs scrape_samples_post_metric_relabeling
                    -> did metric_relabel_configs eat it?
/graph              -> is the selector wrong? regexes are anchored
```

**Alert not firing:**

```text
1  Does the expression return data in /graph right now?
2  Is the rule loaded and healthy in /rules?
3  Has the condition been continuously true for the full `for`?
4  Check ALERTS{alertname="..."} to see pending vs firing
```

**Alert firing but nobody notified:**

```text
1  /alerts in Prometheus shows firing?
2  prometheus_notifications_errors_total / _dropped_total  -> can Prometheus reach AM?
3  Alertmanager UI shows the alert?
4  amtool silence query                                    -> silenced?
5  Inhibition: is a source alert firing with matching `equal` labels?
6  Mute time interval active?
7  amtool config routes test ...                           -> correct receiver?
8  group_wait / group_interval / repeat_interval            -> just waiting?
9  alertmanager_notifications_failed_total{integration=...}  -> delivery failure
10 alertmanager_cluster_members                             -> HA gossip healthy?
```

## Last Ten Minutes Before You Start

Say these out loud:

- Scrape interval **1m**, timeout **10s**, retention **15d** by **flag**.
- `group_wait` **30s**, `group_interval` **5m**, `repeat_interval` **4h**.
- Ports: **9090, 9091, 9093, 9100, 9115**.
- N buckets → **N + 3** series. **`+Inf` is required.**
- **`sum(rate(...))`**, never the other way round.
- **`group_left` = left side is many.**
- **pending** before **firing**; `for` must be continuous.
- **Prometheus fires; Alertmanager notifies.**
- **Labels route; annotations describe.**
- **`honor_labels: true`** for the Pushgateway, which never expires data.
- **`probe_success`**, not `up`, for blackbox targets.
- **`$__rate_interval`** in Grafana.
- **Error budget = 1 - SLO.** 99.9% is **43 minutes per 30 days**.
- **Threshold = burn rate × budget ratio.** 14.4 × 0.001 = **0.0144**.

Good luck.
