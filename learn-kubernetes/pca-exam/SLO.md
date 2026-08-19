# SLIs, SLOs, SLAs, And Error Budgets

## The Three Terms

| Term | Definition | Audience | Consequence of breach |
| --- | --- | --- | --- |
| **SLI** — Service Level **Indicator** | A **measurement** of some aspect of service quality, usually a ratio of good events to total events | Engineering | None. It is just a number |
| **SLO** — Service Level **Objective** | A **target** for an SLI over a window. Internal | Engineering, product | Engineering action: freeze features, prioritise reliability |
| **SLA** — Service Level **Agreement** | A **contract** with a customer, including penalties | Legal, customers | **Financial or contractual penalties** |

The relationships you must be able to state:

- **SLI is the measurement. SLO is the internal target. SLA is the external contract with penalties.**
- The **SLO should always be stricter than the SLA**, so you have room to react before breaching a contract.
- You can have an SLO without an SLA. Most internal services do.
- An SLA without an SLO is unmanageable, because nothing warns you before the penalty.

```text
SLI: 99.95% of requests succeeded over the last 30 days     <- what happened
SLO: 99.9% of requests must succeed over 30 days            <- internal target
SLA: 99.5% or the customer gets a 10% credit                <- contract
     └── deliberately looser than the SLO
```

## Writing An SLI

The standard form is a ratio:

```text
SLI = good events / valid events
```

```promql
# Availability
sum(rate(http_requests_total{code!~"5.."}[30d]))
  / sum(rate(http_requests_total[30d]))

# Latency: fraction of requests faster than the threshold
sum(rate(http_request_duration_seconds_bucket{le="0.3"}[30d]))
  / sum(rate(http_request_duration_seconds_count[30d]))

# Freshness (for a pipeline)
sum(rate(records_processed_within_sla_total[30d]))
  / sum(rate(records_processed_total[30d]))

# Correctness
sum(rate(records_validated_ok_total[30d]))
  / sum(rate(records_validated_total[30d]))
```

Design rules:

1. Measure **as close to the user as possible**. A load-balancer-level SLI beats an application-level one, because it also captures the cases where the application never received the request.
2. Define **valid events** explicitly. 4xx is usually excluded from availability because it is client error. That decision must be enabled by keeping the `code` label.
3. **Latency SLIs need a bucket boundary exactly at the threshold**, so the ratio is exact rather than interpolated from `histogram_quantile()`.
4. Prefer **request-based** SLIs (fraction of good requests) over **time-based** ones (fraction of good minutes) unless there is no request stream.
5. Do not chase 100%. It is unachievable and the cost curve is vertical near the top.

### Why a bucket boundary, not a quantile

```promql
# Interpolated. Accuracy depends entirely on bucket placement.
histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket[5m]))) < 0.3

# Exact, because le="0.3" is a real boundary.
sum(rate(http_request_duration_seconds_bucket{le="0.3"}[5m]))
  / sum(rate(http_request_duration_seconds_count[5m])) > 0.99
```

The second form is the correct way to express "99% of requests under 300ms". This is examinable.

## Error Budgets

```text
error budget = 1 - SLO
```

| SLO | Error budget ratio | Downtime per 30 days | Per year |
| --- | ---: | --- | --- |
| 90% | 0.1 | 3 days | 36.5 days |
| 99% | 0.01 | 7.2 hours | 3.65 days |
| 99.5% | 0.005 | 3.6 hours | 1.83 days |
| 99.9% ("three nines") | **0.001** | **43.2 minutes** | 8.77 hours |
| 99.95% | 0.0005 | 21.6 minutes | 4.38 hours |
| 99.99% ("four nines") | **0.0001** | **4.32 minutes** | 52.6 minutes |
| 99.999% ("five nines") | 0.00001 | 26 seconds | 5.26 minutes |

Memorise at least **99.9% = 0.001 = ~43 minutes per 30 days** and **99.99% = 0.0001 = ~4.3 minutes**.

Budget remaining, as a fraction:

```promql
1 - (
  sum(increase(http_requests_total{code=~"5.."}[30d]))
    /
  (0.001 * sum(increase(http_requests_total[30d])))
)
```

Returns 1 when untouched, 0 when exhausted, negative when overspent.

The **error budget policy** is what makes an SLO real:

```text
budget healthy       -> ship features freely
budget below 25%     -> reliability work is prioritised
budget exhausted     -> feature freeze until the budget recovers
```

Without a policy, an SLO is just a number on a dashboard.

## Burn Rate

```text
burn rate = observed error ratio / error budget ratio
          = observed error ratio / (1 - SLO)
```

| Burn rate | Budget exhausted in (30-day window) |
| ---: | --- |
| 1 | 30 days, exactly at the window's end |
| 2 | 15 days |
| 3 | 10 days |
| 6 | 5 days |
| 10 | 3 days |
| **14.4** | **~2 days** |
| 100 | ~7.2 hours |
| 720 | 1 hour (100% errors) |

To convert a burn rate into a threshold: **threshold = burn rate x error budget ratio**.

```text
99.9% SLO, budget 0.001
  burn 1     -> 0.001    (0.1% errors)
  burn 3     -> 0.003    (0.3% errors)
  burn 6     -> 0.006    (0.6% errors)
  burn 14.4  -> 0.0144   (1.44% errors)
```

Budget consumed by a burn rate over a window:

```text
fraction of budget = burn_rate × (window / SLO_window)

14.4 × (1h / 720h)  = 2%
6    × (6h / 720h)  = 5%
3    × (24h / 720h) = 10%
1    × (72h / 720h) = 10%
```

## Why Static Thresholds Fail

| Failure | Example |
| --- | --- |
| **Too sensitive** | A 30-second spike to 5% errors pages you, having consumed almost none of the budget |
| **Too insensitive** | A sustained 0.5% error rate never crosses a 2% threshold, yet burns the whole 99.9% budget in six days |

The second failure is the important one, because it is silent. A `> 2%` alert on a 99.9% SLO is blind to a 5x burn.

## Multi-Window Multi-Burn-Rate Alerting

The reference pattern from the Google SRE Workbook. This is **the** answer to "how should you alert on an SLO".

| Severity | Burn rate | Long window | Short window | Budget consumed | Detection |
| --- | ---: | --- | --- | ---: | --- |
| **Page** | **14.4** | **1h** | **5m** | **2%** | Fast |
| **Page** | **6** | **6h** | **30m** | **5%** | Medium |
| Ticket | 3 | 1d | 2h | 10% | Slow |
| Ticket | 1 | 3d | 6h | 10% | Very slow |

The **long window** decides whether the burn is significant. The **short window** is an `and` guard requiring the burn to **still be happening**, which:

- prevents alerting on a burn that already ended, and
- makes the alert **resolve quickly** once the burn stops, instead of lingering for the whole long window.

Both effects matter, and the resolution behaviour is the more commonly missed one.

```yaml
groups:
  # Record the windows once. Long-window rates every 15s are expensive.
  - name: slo_windows
    interval: 30s
    rules:
      - record: job:slo_errors:ratio_rate5m
        expr: |
          sum by (job) (rate(http_requests_total{code=~"5.."}[5m]))
            / sum by (job) (rate(http_requests_total[5m]))
      - record: job:slo_errors:ratio_rate30m
        expr: |
          sum by (job) (rate(http_requests_total{code=~"5.."}[30m]))
            / sum by (job) (rate(http_requests_total[30m]))
      - record: job:slo_errors:ratio_rate1h
        expr: |
          sum by (job) (rate(http_requests_total{code=~"5.."}[1h]))
            / sum by (job) (rate(http_requests_total[1h]))
      - record: job:slo_errors:ratio_rate2h
        expr: |
          sum by (job) (rate(http_requests_total{code=~"5.."}[2h]))
            / sum by (job) (rate(http_requests_total[2h]))
      - record: job:slo_errors:ratio_rate6h
        expr: |
          sum by (job) (rate(http_requests_total{code=~"5.."}[6h]))
            / sum by (job) (rate(http_requests_total[6h]))
      - record: job:slo_errors:ratio_rate1d
        expr: |
          sum by (job) (rate(http_requests_total{code=~"5.."}[1d]))
            / sum by (job) (rate(http_requests_total[1d]))

      # Burn rates, for dashboards
      - record: job:slo_burnrate1h:ratio
        expr: job:slo_errors:ratio_rate1h / 0.001
      - record: job:slo_burnrate6h:ratio
        expr: job:slo_errors:ratio_rate6h / 0.001

  - name: slo_burn_alerts
    rules:
      - alert: SLOBurnRateVeryFast
        expr: |
          job:slo_errors:ratio_rate1h  > (14.4 * 0.001)
            and
          job:slo_errors:ratio_rate5m  > (14.4 * 0.001)
        for: 2m
        labels:
          severity: critical
          slo: availability
        annotations:
          summary: "{{ $labels.job }} burning the 30d budget 14.4x too fast ({{ $value | humanizePercentage }})"
          description: "2% of the 30-day error budget is consumed every hour at this rate."
          runbook_url: https://runbooks.example.com/SLOBurn

      - alert: SLOBurnRateFast
        expr: |
          job:slo_errors:ratio_rate6h  > (6 * 0.001)
            and
          job:slo_errors:ratio_rate30m > (6 * 0.001)
        for: 15m
        labels:
          severity: critical
          slo: availability

      - alert: SLOBurnRateSlow
        expr: |
          job:slo_errors:ratio_rate1d > (3 * 0.001)
            and
          job:slo_errors:ratio_rate2h > (3 * 0.001)
        for: 1h
        labels:
          severity: warning
          slo: availability
```

## Dashboard Panels For An SLO

```promql
# Current SLI over the picker range
1 - (sum(increase(http_requests_total{code=~"5.."}[$__range]))
     / sum(increase(http_requests_total[$__range])))

# Error budget remaining (30 days)
1 - (sum(increase(http_requests_total{code=~"5.."}[30d]))
     / (0.001 * sum(increase(http_requests_total[30d]))))

# Current burn rate
job:slo_burnrate1h:ratio

# Hours until budget exhaustion at the current burn rate
(30 * 24) / job:slo_burnrate1h:ratio

# Latency SLI, exact
sum(rate(http_request_duration_seconds_bucket{le="0.3"}[$__rate_interval]))
  / sum(rate(http_request_duration_seconds_count[$__rate_interval]))
```

The "hours until exhaustion" panel is the one that makes burn rates intuitive for non-specialists.

## The Golden Signals And Their Cousins

Three overlapping frameworks. Know all three and who they come from.

### Four Golden Signals (Google SRE)

| Signal | Meaning | PromQL |
| --- | --- | --- |
| **Latency** | How long requests take, **separating successful from failed** | `histogram_quantile(0.99, sum by (le) (rate(duration_bucket[5m])))` |
| **Traffic** | Demand on the system | `sum(rate(requests_total[5m]))` |
| **Errors** | Rate of failed requests | `sum(rate(requests_total{code=~"5.."}[5m])) / sum(rate(requests_total[5m]))` |
| **Saturation** | How full the most constrained resource is | `1 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m]))` |

The latency nuance matters: a fast 500 can hide in an aggregate latency figure, so measure success and failure latency separately.

### RED (Tom Wilkie) — for services

| Signal | Meaning |
| --- | --- |
| **Rate** | Requests per second |
| **Errors** | Failed requests per second, or the ratio |
| **Duration** | Latency distribution |

RED is the golden signals minus saturation, and it maps directly onto "count requests, count failures, measure latency", which is exactly what the Prometheus docs prescribe for online-serving systems.

### USE (Brendan Gregg) — for resources

| Signal | Meaning |
| --- | --- |
| **Utilisation** | Fraction of time the resource was busy |
| **Saturation** | Amount of queued work the resource could not service |
| **Errors** | Error events |

| Framework | Applies to | Author |
| --- | --- | --- |
| **Golden Signals** | User-facing services | Google SRE book |
| **RED** | Services / request-driven systems | Tom Wilkie |
| **USE** | Resources: CPU, disk, network, pools | Brendan Gregg |

Rule of thumb: **RED for services, USE for resources, golden signals as the superset.**

## The Observability Pillars, In SLO Context

| Pillar | Answers | Prometheus role |
| --- | --- | --- |
| **Metrics** | "Is something wrong, and how bad?" | This is Prometheus's job |
| **Logs** | "What exactly happened in this one case?" | Not Prometheus. Loki, Elasticsearch |
| **Traces** | "Where in the request path did the time go?" | Not Prometheus. Jaeger, Tempo, Zipkin |

Metrics are cheap, aggregatable, and bounded in cardinality. Logs and traces are per-event and therefore expensive. **Alert on metrics, then use logs and traces to diagnose.**

**Exemplars** are the bridge: a trace ID attached to a specific histogram observation, so a slow bucket links straight to a trace.

## Traps

| Mistake | Why it is wrong |
| --- | --- |
| Confusing SLI, SLO, and SLA | SLI measures, SLO targets internally, SLA contracts externally with penalties |
| SLO looser than the SLA | You breach the contract before the SLO warns you |
| Targeting 100% | Unachievable, and the cost curve is vertical |
| Measuring the SLI inside the application only | Misses requests that never arrived |
| Including 4xx in an availability budget | Client errors are not your failure |
| Using `histogram_quantile()` for a latency SLO | Interpolated. Use a bucket boundary at the threshold |
| A single static error threshold | Blind to slow burns, noisy on brief spikes |
| Omitting the short window in a burn-rate alert | Fires after the burn ended, and resolves an hour late |
| Computing `rate(...[6h])` in an alert every 15s | Enormously expensive. Use recording rules |
| An SLO with no error budget policy | Nothing changes when it is breached |
| Defining an SLO per component rather than per user journey | Users do not care about your components |

## Memorise

- **SLI = measurement. SLO = internal target. SLA = external contract with penalties.** The **SLO must be stricter than the SLA**.
- `SLI = good events / valid events`. Measure **as close to the user as possible**.
- **Error budget = `1 - SLO`.** 99.9% → **0.001** → **~43 minutes per 30 days**. 99.99% → **0.0001** → **~4.3 minutes**.
- **Burn rate = observed error ratio / (1 - SLO).** Burn rate 1 exhausts the budget exactly at the window's end.
- **Threshold = burn rate x error budget ratio.** 14.4x on 99.9% is **0.0144**; 6x is **0.006**.
- Standard table: **14.4x over 1h guarded by 5m (2% of budget, page)**, **6x over 6h guarded by 30m (5%, page)**, **3x over 1d guarded by 2h (10%, ticket)**.
- The **short window** is an `and` guard: it confirms the burn is ongoing **and** makes the alert resolve quickly.
- Use **recording rules** for long-window rates.
- For a latency SLO, put a **bucket boundary exactly at the threshold** and compute the ratio; do not interpolate a quantile.
- Exclude **4xx** from availability budgets, which requires keeping the `code` label.
- **Four Golden Signals: Latency, Traffic, Errors, Saturation** (Google). Measure success and failure latency separately.
- **RED: Rate, Errors, Duration** (Wilkie), for **services**.
- **USE: Utilisation, Saturation, Errors** (Gregg), for **resources**.
- **Metrics for detection, logs and traces for diagnosis.** Exemplars link them.
- An SLO without an **error budget policy** changes nothing.
