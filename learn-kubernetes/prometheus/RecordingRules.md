# Recording Rules And promtool

## Rule File Anatomy

```yaml
groups:
  - name: request_rates          # unique WITHIN the file
    interval: 30s                # defaults to global evaluation_interval (1m)
    limit: 0                     # max series per rule; 0 = unlimited
    query_offset: 0s             # delay evaluation to catch late samples
    labels:                      # group-level labels (Prometheus 3.x)
      team: platform
    rules:
      - record: job:http_requests:rate5m
        expr: sum by (job) (rate(http_requests_total[5m]))
        labels:
          tier: frontend

      - alert: HighErrorRate
        expr: job:http_errors:rate5m / job:http_requests:rate5m > 0.05
        for: 10m
        keep_firing_for: 0s
        labels:
          severity: critical
        annotations:
          summary: "{{ $labels.job }} error ratio is {{ $value | humanizePercentage }}"
          runbook_url: https://runbooks.example.com/HighErrorRate
```

Load them:

```yaml
rule_files:
  - /etc/prometheus/rules/*.yml
  - /etc/prometheus/rules/alerts/*.yml
```

Globs are **re-expanded on reload**, so a new matching file loads with just a reload.

## Evaluation Semantics

The two rules that matter:

1. **Rules within a group are evaluated sequentially, in written order.** A later rule may safely use an earlier rule's output from the same cycle.
2. **Groups are evaluated in parallel and independently.** A rule in one group must never depend on a rule in another.

```yaml
groups:
  - name: chain                  # ALL IN ONE GROUP, IN ORDER
    interval: 30s
    rules:
      - record: job:requests:rate5m
        expr: sum by (job) (rate(http_requests_total[5m]))

      - record: job:errors:rate5m
        expr: sum by (job) (rate(http_requests_total{code=~"5.."}[5m]))

      - record: job:error_ratio:rate5m
        expr: job:errors:rate5m / job:requests:rate5m       # uses both above
```

Splitting that chain across groups gives you a stale numerator against a fresh denominator, or an empty result if the dependency group has not run yet.

Group `interval` staggering: Prometheus offsets group start times deterministically (hashed from the group name) so all groups do not fire simultaneously.

## Naming Convention

```text
level:metric:operations
```

| Part | Meaning |
| --- | --- |
| `level` | The labels the result is aggregated **to**, joined with `_` |
| `metric` | The base metric name |
| `operations` | Operations applied, most recent first |

```text
instance:node_cpu_utilisation:rate5m
job:http_requests:rate5m
job_route:http_request_duration_seconds:mean5m
job_le:http_request_duration_seconds_bucket:rate5m
cluster_namespace_job:request_latency_seconds:histogram_quantile99
code:prometheus_http_requests:rate5m
```

Rules:

- **Colons are reserved for recording rules.** Never use a colon in a directly instrumented metric name. Colons are legal in metric names and unaffected by relabeling, which is exactly why the convention works as a signal.
- The `level` should list the `by` labels.
- Keep the unit from the source metric.

## What To Record

| Record | Reason |
| --- | --- |
| Aggregations used by many dashboards | Compute once, read many |
| **Subquery inner expressions** | The canonical subquery optimisation |
| Long-window rates for SLO burn alerts | `rate(...[6h])` every 15s is brutal |
| Expressions shared by several alerts | Single source of truth |
| **Federation payloads** | Federate aggregates, never raw series |
| Histogram **bucket rates with `le`** | Keeps quantiles and aggregation flexible |

What **not** to record:

- Anything queried once.
- Anything cheap to compute at query time.
- **`histogram_quantile()` results.** Record the bucket rates instead:

```yaml
      # RIGHT: le preserved, so any quantile and any re-aggregation stay possible
      - record: job_le:http_request_duration_seconds_bucket:rate5m
        expr: sum by (job, le) (rate(http_request_duration_seconds_bucket[5m]))
```

```promql
histogram_quantile(0.99, job_le:http_request_duration_seconds_bucket:rate5m)
histogram_quantile(0.50, job_le:http_request_duration_seconds_bucket:rate5m)
```

Recording the quantile locks in **both** the quantile value **and** the aggregation level, permanently.

## Group `limit`

```yaml
  - name: risky
    limit: 1000
    rules:
      - record: something:broad
        expr: some_high_cardinality_metric
```

If a rule would produce more than `limit` series, the rule **fails** (health becomes `err`) and writes **nothing**. It does not truncate. This is a safety valve against a rule accidentally producing millions of series.

## Backfilling

Recording rules only produce data **from creation forward**. To fill history:

```bash
promtool tsdb create-blocks-from rules \
  --start 2026-08-01T00:00:00Z \
  --end 2026-08-10T00:00:00Z \
  --url http://localhost:9090 \
  --output-dir ./backfill \
  --eval-interval 60s \
  rules/slo.yml

# Move the generated blocks into the TSDB directory, then reload
mv ./backfill/* /var/lib/prometheus/
curl -X POST http://localhost:9090/-/reload
```

## promtool

### Validation

```bash
promtool check config /etc/prometheus/prometheus.yml        # also validates referenced rule files
promtool check rules /etc/prometheus/rules/*.yml
promtool check metrics < exposition.txt
promtool check web-config web-config.yml
promtool check service-discovery prometheus.yml <job_name>
promtool check healthy --url=http://localhost:9090
promtool check ready   --url=http://localhost:9090
```

`promtool check metrics` catches naming and unit violations in an exposition response:

```bash
curl -s http://localhost:9100/metrics | promtool check metrics
```

### Unit testing rules

This is the part most people skip, and it is examinable.

```yaml
# tests/rules_test.yml
rule_files:
  - ../rules/alerts.yml
  - ../rules/recording.yml

evaluation_interval: 1m

# Optional: labels added to every input series
# external_labels:
#   cluster: test

tests:
  - interval: 1m
    name: "instance down fires after 5m"
    input_series:
      - series: 'up{job="api", instance="a:80"}'
        values: '1 1 0 0 0 0 0 0 0 0'

    # Assert on alert state
    alert_rule_test:
      - eval_time: 4m
        alertname: InstanceDown
        exp_alerts: []                       # still PENDING
      - eval_time: 8m
        alertname: InstanceDown
        exp_alerts:
          - exp_labels:                      # do NOT include alertname
              severity: critical
              job: api
              instance: a:80
            exp_annotations:
              summary: "a:80 is down"

    # Assert on expression results
    promql_expr_test:
      - expr: up{job="api"}
        eval_time: 8m
        exp_samples:
          - labels: 'up{job="api", instance="a:80"}'
            value: 0
```

Run it:

```bash
promtool test rules tests/rules_test.yml
promtool test rules tests/*.yml
promtool test rules --junit=results.xml tests/*.yml     # for CI
```

### Series notation

| Notation | Meaning |
| --- | --- |
| `1 2 3` | Literal values at successive intervals |
| `0+10x5` | Start at 0, **add** 10, five times: `0 10 20 30 40 50` |
| `100-10x5` | Start at 100, **subtract** 10, five times |
| `5x3` | The value 5, repeated: `5 5 5 5` |
| `_` | A **gap** (no sample) |
| `_x3` | Three consecutive gaps |
| `stale` | An explicit **staleness marker** |
| `0+0x10` | Ten samples all at 0 |

```yaml
    input_series:
      - series: 'http_requests_total{job="api", code="200"}'
        values: '0+90x20'                    # 90/min = 1.5/s
      - series: 'http_requests_total{job="api", code="500"}'
        values: '0+10x20'                    # 10/min, so a 10% error ratio
      - series: 'up{job="api"}'
        values: '1 1 1 _ _ 0 0 stale'
```

Doing the arithmetic by hand is the point: 90 per minute is `90/60 = 1.5` per second, so `rate(...[5m])` at a steady state equals 1.5.

### Other promtool commands

```bash
# Query a running server
promtool query instant  http://localhost:9090 'up == 0'
promtool query range    http://localhost:9090 'rate(up[5m])' --start=... --end=... --step=15s
promtool query series   http://localhost:9090 --match='{job="node"}'
promtool query labels   http://localhost:9090 job
promtool query analyze  --server=http://localhost:9090 --type=histogram --match='{__name__="x"}'

# PromQL tooling
promtool promql format 'sum(rate(x[5m]))/sum(rate(y[5m]))'
promtool promql explain 'sum by (job) (rate(x[5m]))'

# TSDB
promtool tsdb analyze /var/lib/prometheus
promtool tsdb list --human-readable /var/lib/prometheus
promtool tsdb dump /var/lib/prometheus --match='{__name__="up"}'
promtool tsdb create-blocks-from rules ...
promtool tsdb create-blocks-from openmetrics data.txt /var/lib/prometheus

# Debug bundles
promtool debug all      http://localhost:9090
promtool debug metrics  http://localhost:9090
promtool debug pprof    http://localhost:9090
```

`promtool promql format` is a genuinely useful habit: it canonicalises whitespace in rule files so diffs stay readable.

## Rule Health

```promql
prometheus_rule_group_last_duration_seconds
prometheus_rule_group_interval_seconds
prometheus_rule_group_last_evaluation_timestamp_seconds
prometheus_rule_evaluation_duration_seconds
prometheus_rule_evaluation_failures_total
prometheus_rule_group_iterations_total
prometheus_rule_group_iterations_missed_total

# THE health check
prometheus_rule_group_last_duration_seconds > prometheus_rule_group_interval_seconds

# Slowest groups
topk(5, prometheus_rule_group_last_duration_seconds)

# Staleness of rule evaluation
time() - prometheus_rule_group_last_evaluation_timestamp_seconds
```

If a group takes longer to evaluate than its interval, iterations are **skipped** and you silently lose data points. `prometheus_rule_group_iterations_missed_total` counts them.

```bash
curl -s http://localhost:9090/api/v1/rules | jq -r '
  .data.groups[] |
  "\(.file) :: \(.name) [interval=\(.interval)s lastEval=\(.evaluationTime)s]",
  (.rules[] | "   \(.type) \(.name) health=\(.health) err=\(.lastError // "-")")'

curl -s 'http://localhost:9090/api/v1/rules?type=record' | jq .
curl -s 'http://localhost:9090/api/v1/rules?type=alert'  | jq .
```

## A Complete Realistic Rule Set

```yaml
groups:
  # ---- SLO windows, chained in one group ----
  - name: slo_windows
    interval: 30s
    rules:
      - record: job:requests:rate5m
        expr: sum by (job) (rate(http_requests_total[5m]))
      - record: job:errors:rate5m
        expr: sum by (job) (rate(http_requests_total{code=~"5.."}[5m]))
      - record: job:error_ratio:rate5m
        expr: job:errors:rate5m / job:requests:rate5m
      - record: job:error_ratio:rate30m
        expr: |
          sum by (job) (rate(http_requests_total{code=~"5.."}[30m]))
            / sum by (job) (rate(http_requests_total[30m]))
      - record: job:error_ratio:rate1h
        expr: |
          sum by (job) (rate(http_requests_total{code=~"5.."}[1h]))
            / sum by (job) (rate(http_requests_total[1h]))
      - record: job:error_ratio:rate6h
        expr: |
          sum by (job) (rate(http_requests_total{code=~"5.."}[6h]))
            / sum by (job) (rate(http_requests_total[6h]))

  # ---- Latency: buckets with le preserved ----
  - name: latency
    interval: 30s
    rules:
      - record: job_le:http_request_duration_seconds_bucket:rate5m
        expr: sum by (job, le) (rate(http_request_duration_seconds_bucket[5m]))
      - record: job_route_le:http_request_duration_seconds_bucket:rate5m
        expr: sum by (job, route, le) (rate(http_request_duration_seconds_bucket[5m]))
      - record: job:http_request_duration_seconds:mean5m
        expr: |
          sum by (job) (rate(http_request_duration_seconds_sum[5m]))
            / sum by (job) (rate(http_request_duration_seconds_count[5m]))

  # ---- Node ----
  - name: node
    interval: 30s
    rules:
      - record: instance:node_cpu_utilisation:rate5m
        expr: 1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m]))
      - record: instance:node_num_cpu:sum
        expr: count by (instance) (count by (instance, cpu) (node_cpu_seconds_total))
      - record: instance:node_memory_utilisation:ratio
        expr: 1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)
      - record: instance_device:node_filesystem_utilisation:ratio
        expr: |
          1 - (node_filesystem_avail_bytes{fstype!~"tmpfs|overlay|squashfs"}
               / node_filesystem_size_bytes{fstype!~"tmpfs|overlay|squashfs"})
      - record: instance:node_network_receive_bytes:rate5m
        expr: sum by (instance) (rate(node_network_receive_bytes_total{device!="lo"}[5m]))

  # ---- Alerts read the recorded series, so they are cheap ----
  - name: slo_alerts
    rules:
      - alert: SLOBurnVeryFast
        expr: |
          job:error_ratio:rate1h > (14.4 * 0.001)
            and
          job:error_ratio:rate5m > (14.4 * 0.001)
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "{{ $labels.job }} burning the 30d budget 14.4x too fast ({{ $value | humanizePercentage }})"

      - alert: SLOBurnFast
        expr: |
          job:error_ratio:rate6h > (6 * 0.001)
            and
          job:error_ratio:rate30m > (6 * 0.001)
        for: 15m
        labels:
          severity: critical

  - name: meta
    rules:
      - alert: RuleGroupOverrunning
        expr: prometheus_rule_group_last_duration_seconds > prometheus_rule_group_interval_seconds
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Rule group {{ $labels.rule_group }} takes {{ $value | humanizeDuration }}"

      - alert: RuleEvaluationFailing
        expr: increase(prometheus_rule_evaluation_failures_total[10m]) > 0
        labels:
          severity: warning
```

## Traps

| Mistake | Consequence |
| --- | --- |
| Chaining rules across groups | Stale or missing dependency; groups run in parallel |
| Recording `histogram_quantile()` output | Quantile and aggregation level locked in forever |
| Dropping `le` when recording buckets | `histogram_quantile()` becomes impossible |
| Colons in instrumented metric names | Breaks the convention that signals a derived series |
| Expecting historical data from a new rule | Forward-only. Backfill explicitly |
| Ignoring `iterations_missed_total` | Silent data gaps |
| Skipping `promtool check rules` before reload | A bad rule file fails the whole reload, keeping the old config |
| Putting `alertname` in `exp_labels` | Test mismatch |
| Expecting pending alerts in `exp_alerts` | Pending equals `exp_alerts: []` |
| Duplicate group names in one file | Config error |

## Memorise

- **`level:metric:operations`**, and **colons are reserved for recording rules**.
- **Within a group: sequential, in order. Across groups: parallel.** Chain in one group.
- Group `interval` defaults to the global **`evaluation_interval` (`1m`)**.
- `limit` makes a rule **fail** rather than truncate.
- Rules are **forward-only**. Backfill with **`promtool tsdb create-blocks-from rules`**.
- **Record bucket rates keeping `le`**, never the quantile.
- Recording rules are the standard **subquery optimisation** and make long-window SLO math affordable.
- Federate **recorded aggregates only**.
- `promtool check config` / `check rules` / `check metrics` for validation, **`promtool test rules`** for logic.
- Test notation: **`a+bxn`** add, **`a-bxn`** subtract, **`vxn`** repeat, **`_`** gap, **`stale`** staleness marker.
- In alert tests: pending equals **`exp_alerts: []`**, and **omit `alertname`** from `exp_labels`.
- Health: **`prometheus_rule_group_last_duration_seconds > prometheus_rule_group_interval_seconds`** and **`prometheus_rule_group_iterations_missed_total`**.
- Group names unique **within a file**. `rule_files` globs re-expanded on reload.
- `/api/v1/rules?type=record` and `?type=alert`.
