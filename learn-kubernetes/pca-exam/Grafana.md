# Dashboarding: Grafana And Console Templates

## Prometheus Is Not A Dashboarding Tool

The Prometheus documentation states this explicitly. The built-in UI is for **ad-hoc exploration and debugging**. **Grafana is the recommended dashboarding solution.**

Know what each built-in page is for, because scenario questions use them:

| Page | Answers |
| --- | --- |
| `/graph` | "What does this expression return?" Table and graph views, one expression at a time |
| `/targets` | "Is this target up, and what was the last error?" |
| `/service-discovery` | "What did SD find, and what did relabeling do to it?" Shows `__meta_*` **before and after** |
| `/alerts` | "Which alerts are pending or firing, and since when?" |
| `/rules` | "Are my rules loaded, healthy, and fast enough?" |
| `/config` | "What configuration is actually running?" |
| `/tsdb-status` | "Why is memory high?" Top label names, label values, and metric names by series count |
| `/status` | Build info, runtime info, storage stats, flags |
| `/flags` | Command-line flags in effect |

`/graph` cannot save anything, arrange panels, or template variables. That is the boundary.

## Grafana Data Source

```yaml
# provisioning/datasources/prometheus.yml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    jsonData:
      httpMethod: POST          # POST avoids URL length limits on big queries
      timeInterval: 15s         # SET THIS TO YOUR scrape_interval
      queryTimeout: 60s
      exemplarTraceIdDestinations:
        - name: trace_id
          datasourceUid: tempo
```

`timeInterval` is the single most important setting. It tells Grafana your scrape interval, which determines the floor for `$__interval` and the value of `$__rate_interval`. Getting it wrong produces blank rate graphs.

`access: proxy` means Grafana's backend queries Prometheus, so the browser never contacts it directly. That is what you want.

## The Interval Variables

The most misunderstood part of Grafana with Prometheus.

| Variable | Value |
| --- | --- |
| `$__interval` | Time range divided by panel width in pixels, floored to `timeInterval` |
| **`$__rate_interval`** | **`max($__interval + scrape_interval, 4 × scrape_interval)`** |
| `$__range` | The full selected dashboard time range, e.g. `6h` |
| `$__interval_ms` | `$__interval` in milliseconds |
| `$__range_s`, `$__range_ms` | The range in seconds / milliseconds |
| `$__from`, `$__to` | Range boundaries as epoch milliseconds |

**Always use `$__rate_interval` inside `rate()`, `irate()`, and `increase()`.**

```promql
rate(http_requests_total[$__rate_interval])           # correct
rate(http_requests_total[$__interval])                # wrong
```

Why: `rate()` needs **at least two samples** in its window. On a wide panel with a short time range, `$__interval` can resolve to a single scrape interval, giving zero or one sample and therefore **no result**. `$__rate_interval` guarantees at least four scrape intervals.

The diagnostic signature: **the graph is blank at short time ranges and correct at long ones.** That is the canonical symptom, and it is a likely exam question.

Use `$__range` for anything that should span the whole picker window:

```promql
1 - (sum(increase(http_requests_total{code=~"5.."}[$__range]))
     / sum(increase(http_requests_total[$__range])))
```

## Panel Types

| Panel | Use | Typical query |
| --- | --- | --- |
| **Time series** | The default: rates, utilisation, latency over time | `sum by (route) (rate(x[$__rate_interval]))` |
| **Stat** | One big current number | `sum(rate(x[$__rate_interval]))` |
| **Gauge** | One value against a range, good for utilisation | `1 - avg(rate(node_cpu_seconds_total{mode="idle"}[$__rate_interval]))` |
| **Bar gauge** | Compare across many series at one instant | `topk(10, sum by (route) (rate(x[$__rate_interval])))`, Instant |
| **Table** | Instant results, target lists, top-N tables | `up`, Instant, Table format |
| **Heatmap** | **A histogram's full distribution over time** | `sum by (le) (rate(x_bucket[$__rate_interval]))`, Heatmap format, `{{le}}` legend |
| **State timeline** | Discrete state over time | `up` |
| **Histogram** | Distribution of the current values | any |
| **Logs** | Loki, not Prometheus | |

The **heatmap** point is examinable: it is how you visualise the whole latency distribution rather than a single quantile. Query the `_bucket` series with `rate()`, set the format to **Heatmap**, and use `{{le}}` as the legend.

## Query Options

| Option | Meaning |
| --- | --- |
| **Legend** | `{{instance}}` interpolates a label. `{{le}}` for heatmaps |
| **Format** | `Time series`, `Table`, or `Heatmap` |
| **Type** | **Range** uses `/api/v1/query_range`; **Instant** uses `/api/v1/query` and returns only the latest value |
| **Min step** | Lower bound on the requested step |
| **Resolution** | Divides the number of requested data points |
| **Exemplars** | Overlay trace exemplars |

Use **Instant** for Stat, Gauge, Bar gauge, and Table panels. Using Range for them wastes query capacity.

## Variables

```text
Query        label_values(up, job)
             label_values(up{job="$job"}, instance)
             label_names()
             metrics(node_)
             query_result(topk(10, sum by (route) (rate(x[5m]))))
Custom       prod,staging,dev
Interval     1m,5m,10m,1h
Constant     a fixed value
Textbox      free text
Datasource   switch data sources
Ad hoc filters  arbitrary label filters applied to every query
```

| Grafana function | Prometheus API endpoint |
| --- | --- |
| `label_values(label)` | `/api/v1/label/<name>/values` |
| `label_values(metric, label)` | `/api/v1/series` |
| `label_names()` | `/api/v1/labels` |
| `metrics(regex)` | `/api/v1/label/__name__/values` |
| `query_result(expr)` | `/api/v1/query` |

Chained variables are the standard pattern:

```text
$job      = label_values(up, job)
$instance = label_values(up{job="$job"}, instance)
```

Changing `$job` repopulates `$instance` automatically.

Multi-value variables interpolate as a **regex alternation** `(a|b|c)`, so you **must** use `=~`:

```promql
up{job="$job", instance=~"$instance"}
```

Using `=` with a multi-value variable silently returns nothing. That is a common trap.

Formatting options: `${var:regex}`, `${var:pipe}`, `${var:csv}`, `${var:json}`, `${var:text}`.

## A Golden-Signals Dashboard Layout

```text
Row: Overview                       (the most important panel goes TOP-LEFT)
  Stat           request rate               unit: reqps
  Stat           error ratio                unit: percentunit, thresholds at 1% and 5%
  Stat           p99 latency                unit: s
  Stat           error budget remaining     unit: percentunit
  State timeline up per instance

Row: Traffic (Rate)
  Time series    sum by (route) (rate(requests_total[$__rate_interval]))

Row: Errors
  Time series    error ratio by route
  Bar gauge      topk(10, 5xx rate by route)          Instant

Row: Latency (Duration)
  Time series    p50, p90, p99, mean                  four queries in one panel
  Heatmap        sum by (le) (rate(duration_bucket[$__rate_interval]))

Row: Saturation
  Time series    CPU, memory, connection pool, queue depth
```

Queries:

```promql
# Rate
sum(rate(http_requests_total[$__rate_interval]))
sum by (route) (rate(http_requests_total[$__rate_interval]))

# Errors
sum(rate(http_requests_total{code=~"5.."}[$__rate_interval]))
  / sum(rate(http_requests_total[$__rate_interval]))

# Duration: p50/p90/p99 plus the mean, as separate queries in one panel
histogram_quantile(0.50, sum by (le) (rate(http_request_duration_seconds_bucket[$__rate_interval])))
histogram_quantile(0.90, sum by (le) (rate(http_request_duration_seconds_bucket[$__rate_interval])))
histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket[$__rate_interval])))
sum(rate(http_request_duration_seconds_sum[$__rate_interval]))
  / sum(rate(http_request_duration_seconds_count[$__rate_interval]))

# Heatmap
sum by (le) (rate(http_request_duration_seconds_bucket[$__rate_interval]))

# Saturation
1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[$__rate_interval]))
1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)

# Availability over the picker range
1 - (sum(increase(http_requests_total{code=~"5.."}[$__range]))
     / sum(increase(http_requests_total[$__range])))
```

## Units

Getting units wrong is the most common dashboard defect.

| Data | Grafana unit |
| --- | --- |
| Seconds | `s` (Grafana formats to ms/µs automatically) |
| Bytes | `bytes(IEC)` or `bytes(SI)` |
| Bytes per second | `Bps` |
| A **ratio 0-1** | **`percentunit`** |
| A number already 0-100 | `percent` |
| Requests per second | `reqps` |
| A Unix timestamp | `dateTimeAsIso` |

Because Prometheus conventions use **base units and ratios 0-1**, you almost always want **`percentunit`**, not `percent`. Choosing `percent` for a ratio displays `0.05` as `0.05%` instead of `5%`.

## Dashboard Performance

Every panel is at least one query. A 40-panel dashboard on a 30-day range can overwhelm a Prometheus server.

Fixes, in order of effect:

1. **Recording rules** for expensive repeated aggregations. This is the big one.
2. Fewer panels, split across dashboards.
3. `sum by (...)` instead of hundreds of raw series.
4. `topk()` when many series must be shown.
5. **Instant** queries for Stat, Gauge, Table, and Bar gauge panels.
6. A refresh interval **no faster than the scrape interval**. Faster refreshes show no new data and just add load.

Diagnose with the Query Inspector, then reproduce:

```bash
curl -s -G http://localhost:9090/api/v1/query_range \
  --data-urlencode 'query=<the expression>' \
  --data-urlencode "start=$(date -d '-30 days' +%s)" \
  --data-urlencode "end=$(date +%s)" \
  --data-urlencode 'step=60s' \
  --data-urlencode 'stats=true' | jq '.data.stats'
```

Compare `totalQueryableSamples` before and after introducing a recording rule.

## Annotations

Event markers on the time axis, which can come from a PromQL query:

```text
Query: changes(process_start_time_seconds{job="$job"}[5m]) > 0
Title: {{instance}} restarted
```

Deploy markers make latency graphs interpretable, and this is the Prometheus-native way to get them without an external event source.

## Provisioning

Keep dashboards in version control rather than clicking them together.

```yaml
# provisioning/dashboards/provider.yml
apiVersion: 1
providers:
  - name: 'my-dashboards'
    orgId: 1
    folder: 'Services'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: false
    options:
      path: /etc/grafana/provisioning/dashboards
```

Dashboards go in that directory as JSON. Combined with data source provisioning, the whole Grafana state becomes reproducible.

## Grafana Alerting Versus Prometheus Alerting

| | Prometheus alerting | Grafana alerting |
| --- | --- | --- |
| Evaluated by | Prometheus rule manager | Grafana |
| Configuration | YAML rule files, version controlled | Grafana database or provisioning |
| Routing | Alertmanager | Grafana's built-in Alertmanager, or an external one |
| Survives Grafana being down | **Yes** | No |
| Can alert on multiple data sources | No | Yes |

**The Prometheus-native answer is rule files plus Alertmanager**, because evaluation is independent of the dashboard layer. Grafana alerting is a legitimate alternative, particularly when you need to combine data sources, but it is not the Prometheus way.

## Console Templates

Prometheus's own Go-templated HTML dashboards. Historical, still supported, and examinable because they are Prometheus-native.

```bash
prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries
```

Served at `/consoles/<file>.html`.

```html
{{ template "head" . }}
{{ template "prom_content_head" . }}

<h1>Node Overview</h1>

<h2>Down targets</h2>
<ul>
{{ range query "up == 0" }}
  <li>{{ .Labels.job }} / {{ .Labels.instance }}</li>
{{ else }}
  <li>none</li>
{{ end }}
</ul>

<h2>Request rate</h2>
{{ with query "sum(rate(http_requests_total[5m]))" }}
  <p>{{ . | first | value | humanize }} req/s</p>
{{ end }}

<h2>Error ratio</h2>
{{ with query "sum(rate(http_requests_total{code=~'5..'}[5m])) / sum(rate(http_requests_total[5m]))" }}
  <p>{{ . | first | value | humanizePercentage }}</p>
{{ end }}

<h2>CPU</h2>
<div id="cpuGraph"></div>
<script>
new PromConsole.Graph({
  node: document.querySelector("#cpuGraph"),
  expr: "1 - avg by (instance) (rate(node_cpu_seconds_total{mode='idle'}[5m]))",
  name: "[[ instance ]]",
  yAxis: { labelFormatter: PromConsole.NumberFormatter.humanizeNoSmallPrefix },
  yTitle: "CPU utilisation"
})
</script>

{{ template "prom_content_tail" . }}
{{ template "tail" }}
```

Template functions: `query`, `first`, `value`, `label`, `sortByLabel`, `humanize`, `humanize1024`, `humanizeDuration`, `humanizePercentage`, `humanizeTimestamp`, `printf`, `args`, `match`, `reReplaceAll`, `safeHtml`, `title`, `toUpper`, `toLower`, plus `pathPrefix` and `externalURL`.

These are the **same functions available in alert annotations**, which is the main reason to know them. `humanizePercentage` takes a **ratio 0-1**.

## Traps

| Mistake | Consequence |
| --- | --- |
| `$__interval` inside `rate()` | Blank graphs at short time ranges |
| Not setting `timeInterval` on the data source | `$__rate_interval` is computed from the wrong scrape interval |
| `=` with a multi-value variable | Silently returns nothing; must be `=~` |
| `percent` unit for a ratio 0-1 | Shows `0.05%` instead of `5%` |
| Range queries for Stat panels | Wasted query capacity |
| Refresh faster than the scrape interval | Load with no new data |
| Graphing hundreds of raw series | Unreadable and expensive |
| No recording rules behind a long-range dashboard | Timeouts |
| Using `histogram_quantile()` results in a heatmap | A heatmap needs the **bucket** series |
| Treating Prometheus's `/graph` as a dashboard | It cannot save or arrange anything |

## Memorise

- **Prometheus is not a dashboarding tool. Grafana is the recommended one.** `/graph` is for ad-hoc queries.
- UI pages: **`/targets`** health, **`/service-discovery`** relabeling, **`/tsdb-status`** cardinality, **`/config`** loaded config, **`/rules`** and **`/alerts`**.
- **`$__rate_interval` inside `rate()`.** It equals **`max($__interval + scrape_interval, 4 × scrape_interval)`**.
- Blank rate graph at short ranges = **fewer than two samples** in the window.
- Set the data source **`timeInterval` to your `scrape_interval`**.
- **`$__range`** for whole-window calculations like availability.
- **Heatmap panel + `rate()` of `_bucket` series + `{{le}}` legend** for distributions.
- **Instant** queries for Stat, Gauge, Table, Bar gauge. **Range** for time series.
- Legends use **`{{label}}`**.
- `label_values(metric, label)` for variables; multi-value interpolates as `(a|b|c)`, so use **`=~`**.
- Use **`percentunit`** for ratios 0-1.
- Fix slow dashboards with **recording rules**, fewer panels, `sum by`, and `topk`.
- Do not refresh faster than the scrape interval.
- **Console templates** are enabled with `--web.console.templates` and `--web.console.libraries`; functions include `query`, `first`, `value`, `humanize`, `humanizePercentage`. Historical, not recommended.
- **Prometheus rule files plus Alertmanager keep alerting when Grafana is down.**
