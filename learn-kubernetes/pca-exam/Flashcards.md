# Flashcards

Rapid recall. Cover the right column, work down, and mark anything you hesitate on. Do a full pass the night before and the morning of the exam.

## Numbers And Defaults

| Prompt | Answer |
| --- | --- |
| Default `scrape_interval` | **1m** (almost every real config overrides it to 15s) |
| Default `evaluation_interval` | **1m** |
| Default `scrape_timeout` | **10s**, and it must be `<=` the scrape interval |
| Default `metrics_path` | `/metrics` |
| Default `scheme` | `http` |
| Default retention time | **15d** |
| Default retention size | **0**, meaning unlimited |
| How retention is configured | **Command-line flags**, not YAML |
| Default block duration (head block) | **2h** |
| Maximum block duration | **10%** of retention time |
| Default lookback delta | **5m** |
| Bytes per compressed sample | **1 to 2** |
| Default `query.max-samples` | 50,000,000 |
| Default `query.timeout` | 2m |
| Default `query.max-concurrency` | 20 |
| Alertmanager `group_wait` | **30s** |
| Alertmanager `group_interval` | **5m** |
| Alertmanager `repeat_interval` | **4h** |
| Alertmanager `resolve_timeout` | **5m** |
| Default relabel `action` | **`replace`** |
| Default relabel `separator` | **`;`** |
| Default relabel `regex` | `(.*)` |
| Default relabel `replacement` | `$1` |
| WAL truncation interval | 2h, aligned with block cutting |
| Minimum samples for `rate()` | **2** |

## Ports

| Component | Port |
| --- | --- |
| Prometheus | **9090** |
| Pushgateway | **9091** |
| Alertmanager | **9093** (cluster gossip **9094**) |
| node_exporter | **9100** |
| blackbox_exporter | **9115** |
| snmp_exporter | 9116 |
| statsd_exporter | 9102 (statsd ingest 9125) |
| Grafana | 3000 |
| kube-state-metrics | 8080 (self-metrics 8081) |
| cAdvisor standalone | 8080 |
| kubelet | 10250 |
| etcd | 2379 |
| CoreDNS metrics | 9153 |

## Data Model

| Prompt | Answer |
| --- | --- |
| What identifies a series | Metric name **plus the complete label set** |
| Label holding the metric name | **`__name__`** |
| Sample size in memory | float64 value + int64 timestamp |
| Timestamp precision | Milliseconds |
| Valid metric name regex | `[a-zA-Z_:][a-zA-Z0-9_:]*` |
| Valid label name regex | `[a-zA-Z_][a-zA-Z0-9_]*` |
| Colons in metric names | Reserved for **recording rules** |
| `__` label prefix | Reserved internal labels, dropped after relabeling |
| Empty label value | Equivalent to the label not existing |
| Two labels every scraped series gets | `job` and `instance` |

## Metric Types

| Prompt | Answer |
| --- | --- |
| Counter | Monotonically increasing, resets to 0 on restart. Never query the raw value |
| Gauge | Goes up and down. Query the value directly |
| Histogram | Cumulative buckets + `_sum` + `_count`. Quantiles at query time |
| Summary | Pre-computed quantiles + `_sum` + `_count`. **Not aggregatable** |
| Counter suffix | `_total` |
| Histogram series produced | `_bucket` per boundary (incl. `+Inf`) + `_sum` + `_count` |
| Series for N boundaries | **N + 3** (N buckets, `+Inf`, `_sum`, `_count`) |
| Cumulative meaning of `le` | "less than or equal to", each bucket includes all lower ones |
| Mandatory bucket | **`le="+Inf"`**, and it must equal `_count` |
| OpenMetrics-only types | **GaugeHistogram**, **StateSet**, **Info**, **Unknown** |
| Info metric convention | `_info` suffix, value always 1, metadata in labels |

## Exposition

| Prompt | Answer |
| --- | --- |
| Content type header (Prometheus text) | `text/plain; version=0.0.4` |
| Content type (OpenMetrics) | `application/openmetrics-text; version=1.0.0` |
| OpenMetrics terminator | **`# EOF`** (mandatory) |
| OpenMetrics counter naming | The `_total` suffix is required in the TYPE declaration |
| OpenMetrics extras | UNIT metadata, `_created`, exemplars, `# EOF` |
| Escaping in label values | `\\`, `\"`, `\n` |
| Comment lines | Begin `#`, but `# HELP` and `# TYPE` are metadata |
| Special float values | `+Inf`, `-Inf`, `NaN` |
| Validate exposition | `promtool check metrics < metrics.txt` |

## Architecture

| Prompt | Answer |
| --- | --- |
| Pull or push | **Pull**, over HTTP |
| Storage model | Local TSDB, per-node, **no clustering** |
| What `up` means | The last **scrape** succeeded |
| Synthetic metrics | `up`, `scrape_duration_seconds`, `scrape_samples_scraped`, `scrape_samples_post_metric_relabeling`, `scrape_series_added`, `scrape_body_size_bytes` |
| Reload config | **SIGHUP** or `POST /-/reload` with `--web.enable-lifecycle` |
| Failed reload behaviour | Previous config keeps running |
| Reload success metric | `prometheus_config_last_reload_successful` |
| Agent mode | Scrape + remote write only. **No querying, alerting, or rules** |
| Federation path | `/federate` with `match[]` params |
| Where `external_labels` apply | **Remote write, federation, alerts**. Not local storage |
| HA pattern | Two identical Prometheus servers, one Alertmanager cluster deduplicating |
| Long-term storage | Thanos, Cortex/Mimir, VictoriaMetrics via remote write |
| CNCF status | **Second project after Kubernetes; graduated 2018** |
| Original author / origin | Matt Proud and Julius Volz at SoundCloud, 2012, inspired by Borgmon |

## Relabeling

| Prompt | Answer |
| --- | --- |
| Four relabeling stages | `relabel_configs`, `metric_relabel_configs`, `write_relabel_configs`, `alert_relabel_configs` |
| Operates on targets, pre-scrape | **`relabel_configs`** |
| Operates on samples, post-scrape | **`metric_relabel_configs`** |
| `keep` | Discard targets/samples **not** matching |
| `drop` | Discard targets/samples matching |
| `replace` | Write `replacement` into `target_label` if the regex matches |
| `labelmap` | Copy labels whose **names** match, using regex capture groups |
| `labeldrop` / `labelkeep` | Remove/retain labels by **name** |
| `hashmod` | `target_label = hash(source) % modulus`, for sharding |
| `lowercase` / `uppercase` | Case-fold the joined source labels |
| `keepequal` / `dropequal` | Compare `source_labels` to `target_label` |
| Address label | **`__address__`** → becomes `instance` if not set |
| Path label | `__metrics_path__` |
| Scheme label | `__scheme__` |
| Parameter labels | `__param_<name>` |
| Non-matching regex on `replace` | The rule is a **no-op** |
| Setting a label to empty | Deletes it |
| Regex anchoring in relabeling | **Fully anchored** |
| Debug page | **`/service-discovery`**, showing labels before and after |

## Service Discovery

| Prompt | Answer |
| --- | --- |
| Metadata label prefix | **`__meta_*`** |
| Kubernetes roles | node, pod, endpoints, endpointslice, service, ingress |
| Role for scraping pods behind a Service | **`endpoints`** or `endpointslice` |
| Roles for blackbox probing only | **`service`**, **`ingress`** |
| Why not `role: service` for metrics | It load-balances, so scrapes hit different pods |
| Role carrying both service and pod metadata | `endpoints` |
| file_sd formats | JSON or YAML, reloaded on change, no restart |
| http_sd | Prometheus GETs a JSON target list |
| Annotation sanitisation | `prometheus.io/scrape` → `__meta_kubernetes_pod_annotation_prometheus_io_scrape` |
| First check when Kubernetes SD is empty | **RBAC** |

## PromQL Types

| Prompt | Answer |
| --- | --- |
| Four data types | **Instant vector, range vector, scalar, string** |
| Instant vector | One sample per series at one timestamp |
| Range vector | A range of samples per series |
| Range vector syntax | `metric[5m]` |
| What can be graphed | Only instant vectors and scalars |
| Regex engine | **RE2, fully anchored** |
| Matchers | `=`, `!=`, `=~`, `!~` |
| Offset | `metric offset 5m`, after the selector |
| `@` modifier | Evaluate at an absolute timestamp; `@ start()`, `@ end()` |
| Subquery syntax | `expr[range:resolution]` |

## PromQL Functions

| Prompt | Answer |
| --- | --- |
| Per-second counter rate | `rate(x[5m])` |
| Instantaneous rate | `irate(x[5m])`, last two samples, **graphing only** |
| Total increase | `increase(x[5m])` = `rate() * seconds` |
| Gauge difference | `delta(x[5m])` |
| Counter resets | `resets(x[5m])` |
| Value changes | `changes(x[5m])` |
| Forecast | `predict_linear(x[1h], 4*3600)` |
| Trend slope | `deriv(x[1h])` |
| Quantile from histogram | `histogram_quantile(0.95, sum by (le) (rate(x_bucket[5m])))` |
| Average from histogram | `rate(x_sum[5m]) / rate(x_count[5m])` |
| Series missing now | `absent(x)` → 1 |
| Series missing over a range | `absent_over_time(x[10m])` → 1 |
| `_over_time` family | `avg`, `min`, `max`, `sum`, `count`, `stddev`, `stdvar`, `quantile`, `last`, `present`, `absent` |
| Label rewrite | `label_replace(v, dst, repl, src, regex)` |
| Label join | `label_join(v, dst, sep, src...)` |
| Time functions | `time()`, `timestamp()`, `day_of_week()`, `hour()`, `month()`, `year()`, `days_in_month()` |
| Rounding | `ceil`, `floor`, `round`, `abs`, `clamp`, `clamp_min`, `clamp_max` |
| Sorting | `sort()`, `sort_desc()`, `sort_by_label()` |
| Drop the metric name | `label_replace` or any binary operation, or the `bool` modifier |

## PromQL Aggregation

| Prompt | Answer |
| --- | --- |
| Operators | `sum, min, max, avg, group, stddev, stdvar, count, count_values, bottomk, topk, quantile, limitk, limit_ratio` |
| `by` | Keep only these labels |
| `without` | Keep all labels **except** these |
| Take a parameter | `topk`, `bottomk`, `quantile`, `count_values`, `limitk`, `limit_ratio` |
| `count()` vs `count_values()` | Counts series vs counts occurrences of a **sample value** |
| Distinct label values | `count(count by (label) (metric))` |
| Correct order with counters | **`sum(rate(x[5m]))`** — never `rate(sum(...))` |
| Why | Reset detection is per series |

## PromQL Operators And Matching

| Prompt | Answer |
| --- | --- |
| Arithmetic | `+ - * / % ^` |
| Comparison | `== != > < >= <=` |
| Logical / set | `and`, `or`, `unless` |
| Default comparison behaviour | **Filters** series |
| `bool` modifier | Returns 0/1 for every series and drops the metric name |
| Default vector matching | **One-to-one on identical label sets** |
| `on (labels)` | Match on only these labels |
| `ignoring (labels)` | Match on all labels except these |
| `group_left` | **Left side is the "many" side** |
| `group_right` | Right side is the "many" side |
| Labels in `group_left(x)` | Copied from the **right** (the "one") side |
| Set operators and label lists | `and`, `or`, `unless` require identical labels unless `on`/`ignoring` is used |
| Highest precedence | `^`, then `* / % atan2`, then `+ -`, then comparisons, then `and`/`unless`, then `or` |
| `^` associativity | **Right**-associative |

## Histograms

| Prompt | Answer |
| --- | --- |
| Why histograms beat summaries | Buckets aggregate across instances; quantiles chosen at query time |
| Legitimate summary use | A single instance where an exact quantile is required and no aggregation is needed |
| `histogram_quantile()` interpolation | **Linear within the matched bucket** |
| Returns `+Inf` | The quantile falls in the `+Inf` bucket; highest finite boundary too low |
| Returns `NaN` | Fewer than two buckets or no observations |
| Must keep `le` | Yes, `sum by (le)` |
| Bucket count guidance | About 10 to 15, geometrically spaced around the SLO threshold |
| Native histograms | Sparse exponential buckets, one series, `protobuf`, experimental flag |
| Native histogram flag | `--enable-feature=native-histograms` |
| Native histogram functions | `histogram_count`, `histogram_sum`, `histogram_fraction`, `histogram_avg`, `histogram_stddev` |

## Instrumentation

| Prompt | Answer |
| --- | --- |
| Base units | **seconds** and **bytes**, never ms or KB |
| Ratios | 0 to 1, not 0 to 100 |
| Counter naming | `<namespace>_<name>_<unit>_total` |
| Never label with | User ID, email, request ID, full URL, timestamp, unbounded IDs |
| Cardinality of a metric | Product of the distinct values of all its labels |
| In-flight requests | Gauge, incremented on entry, decremented in `finally` |
| Failure counting | A separate failure counter alongside the total, so the ratio is computable |
| Batch job success | `job_last_success_timestamp_seconds` gauge |
| On collection error | **Fail the scrape** so `up` goes to 0 |
| RED | Rate, Errors, Duration, for services |
| USE | Utilisation, Saturation, Errors, for resources |
| Golden signals | Latency, Traffic, Errors, Saturation |
| Python multiprocess | `PROMETHEUS_MULTIPROC_DIR` + `MultiProcessCollector` |
| Free built-in metrics | `process_*`, `go_*`, `python_*`, plus `promhttp_*` |

## Exporters

| Prompt | Answer |
| --- | --- |
| Definition | A translator exposing third-party system metrics in Prometheus format |
| Local topology | Alongside the thing it monitors, one target per instance |
| Multi-target topology | One exporter, many probed targets via `__param_*` (blackbox, snmp) |
| Blackbox health metric | **`probe_success`**, not `up` |
| Blackbox cert expiry | `probe_ssl_earliest_cert_expiry`, a **Unix timestamp** |
| Blackbox modules | `http_2xx`, `tcp_connect`, `icmp`, `dns`, `grpc` |
| Textfile collector | `--collector.textfile.directory`, `*.prom` files, atomic rename |
| Textfile staleness metric | `node_textfile_mtime_seconds` |
| Textfile vs Pushgateway | Textfile for **machine-level** cron output; Pushgateway for **service-level** batch jobs |
| Pushgateway required setting | **`honor_labels: true`** |
| Pushgateway retention | **Forever**, until deleted via the API |
| Pushgateway anti-pattern | Using it as a general push proxy for long-running services |
| kube-state-metrics | **`kube_*`**, declared object state from the API |
| cAdvisor | **`container_*`**, container resource usage, **inside the kubelet** at `/metrics/cadvisor` |
| node_exporter | **`node_*`**, host resources |

## Rules

| Prompt | Answer |
| --- | --- |
| Recording rule naming | **`level:metric:operations`** |
| Within a group | Rules evaluate **sequentially, in order** |
| Across groups | Groups evaluate **in parallel** |
| Group `interval` default | Falls back to `evaluation_interval` |
| Validate rules | `promtool check rules rules.yml` |
| Unit test rules | `promtool test rules tests.yml` |
| Series notation in tests | `1+1x10` means start at 1, add 1, eleven samples total; `_` is a gap |
| Backfill recording rules | `promtool tsdb create-blocks-from rules` |
| Rule health metrics | `prometheus_rule_evaluation_failures_total`, `prometheus_rule_group_last_duration_seconds`, `prometheus_rule_group_iterations_missed_total` |
| Alert rule fields | `alert`, `expr`, `for`, `keep_firing_for`, `labels`, `annotations` |
| Alert states | **inactive → pending → firing** |
| `for` semantics | Must be **continuously** true; any gap resets the timer |
| `for: 0` or omitted | Fires on the first true evaluation |
| `keep_firing_for` | Keeps an alert firing after the expression stops matching, to prevent flapping |
| Built-in alert metric | **`ALERTS{alertstate="pending"\|"firing"}`**, value 1 |
| `ALERTS_FOR_STATE` | Timestamp when the alert became active, used to restore state on restart |
| In annotations | `{{ $value }}`, `{{ $labels.x }}`, `humanize`, `humanizePercentage`, `humanizeDuration` |
| Labels vs annotations | **Labels route and identify; annotations describe** |

## Alertmanager

| Prompt | Answer |
| --- | --- |
| Pipeline order | **Inhibition → Silencing → Routing → Grouping → Timers → Notify** (with dedup on receipt) |
| Who decides an alert fires | **Prometheus** |
| Who decides who gets notified | **Alertmanager** |
| `group_wait` | Wait before the **first** notification for a **new** group. 30s |
| `group_interval` | Minimum wait before notifying about **changes** to an existing group. 5m |
| `repeat_interval` | Re-notify when **nothing changed**. 4h |
| Routing match behaviour | **First match wins**, unless `continue: true` |
| `group_by: []` | **All alerts in one group** |
| `group_by: [...]` | Group by all labels, disabling aggregation |
| Silence | Human-created at runtime, matcher-based, has a time window |
| Inhibition | One firing alert suppresses others; needs `source_matchers`, `target_matchers`, `equal` |
| Mute time interval | Configured schedule suppressing notifications |
| Silence created via | UI, `amtool silence add`, or the API. **Not** the config file |
| `send_resolved` default | **`true`** for most integrations, **`false`** for PagerDuty and OpsGenie |
| HA mechanism | **Gossip mesh on 9094**, sharing silences and the notification log |
| HA flags | `--cluster.listen-address`, `--cluster.peer` |
| Key failure metric | `alertmanager_notifications_failed_total` |
| CLI | `amtool` — `alert query`, `silence add/query/expire`, `config routes test` |
| Test a routing tree | `amtool config routes test --config.file=... severity=critical` |

## Storage

| Prompt | Answer |
| --- | --- |
| Write path | Sample → head block in memory + **WAL** → 2h block on disk → compaction |
| WAL purpose | Crash recovery for in-memory head data |
| Block contents | `chunks/`, `index`, `meta.json`, `tombstones` |
| Samples per chunk | Up to **120** |
| Compression | Gorilla-style: delta-of-delta timestamps, XOR values |
| Disk sizing formula | `retention_seconds × ingested_samples_per_second × bytes_per_sample` |
| Snapshot API | `POST /api/v1/admin/tsdb/snapshot` with `--web.enable-admin-api` |
| Delete series | `POST /api/v1/admin/tsdb/delete_series`, then `clean_tombstones` |
| Inspect cardinality (CLI) | `promtool tsdb analyze /path` |
| Inspect cardinality (API) | `/api/v1/status/tsdb`, or the `/tsdb-status` page |
| Staleness marker | Written when a series disappears, so it stops being returned |
| Remote write lag metric | `prometheus_remote_storage_highest_timestamp_in_seconds` minus `..._queue_highest_sent_timestamp_seconds` |
| Remote write tuning | `queue_config`: `max_shards`, `capacity`, `max_samples_per_send` |

## Grafana

| Prompt | Answer |
| --- | --- |
| Inside `rate()` | **`$__rate_interval`** |
| `$__rate_interval` formula | `max($__interval + scrape_interval, 4 × scrape_interval)` |
| Blank rate graph at short ranges | Fewer than two samples in the window |
| Data source setting that matters most | `timeInterval` = your `scrape_interval` |
| Whole picker range | `$__range` |
| Distribution over time | **Heatmap** panel, `sum by (le) (rate(x_bucket[$__rate_interval]))`, legend `{{le}}` |
| Panel for a single current number | Stat, with an **Instant** query |
| Unit for a 0-1 ratio | **`percentunit`** |
| Variable query for label values | `label_values(metric, label)` |
| Multi-value variable matcher | **`=~`**, because it interpolates as `(a\|b\|c)` |
| Legend interpolation | `{{label}}` |
| Fix a slow dashboard | **Recording rules**, fewer panels, `sum by`, `topk`, Instant queries |
| Console templates flags | `--web.console.templates`, `--web.console.libraries` |

## SLOs

| Prompt | Answer |
| --- | --- |
| SLI | A **measurement** of service quality |
| SLO | An **internal target** |
| SLA | An **external contract with penalties** |
| Required relationship | **SLO stricter than SLA** |
| SLI form | `good events / valid events` |
| Error budget | **`1 - SLO`** |
| 99.9% over 30 days | **~43 minutes** |
| 99.99% over 30 days | **~4.3 minutes** |
| Burn rate | `observed error ratio / (1 - SLO)` |
| Threshold from burn rate | **burn rate × error budget ratio** |
| 14.4x on a 99.9% SLO | **0.0144** |
| Page-level windows | **1h/5m at 14.4x**, and **6h/30m at 6x** |
| Ticket-level windows | 1d/2h at 3x, 3d/6h at 1x |
| Short window purpose | Confirm the burn is ongoing; make the alert resolve promptly |
| Long-window rates in alerts | Precompute with **recording rules** |
| Latency SLO technique | A **bucket boundary at the threshold**, then a ratio |
| Makes an SLO real | An **error budget policy** |

## promtool

| Prompt | Answer |
| --- | --- |
| Check config | `promtool check config prometheus.yml` |
| Check rules | `promtool check rules rules.yml` |
| Unit test rules | `promtool test rules tests.yml` |
| Check exposition | `promtool check metrics < metrics.txt` |
| Check service discovery | `promtool check service-discovery prometheus.yml <job>` |
| Query instant | `promtool query instant http://localhost:9090 'up'` |
| Query range | `promtool query range http://localhost:9090 'up' --start=... --end=...` |
| Query series | `promtool query series --match='up' http://localhost:9090` |
| Query labels | `promtool query labels http://localhost:9090 job` |
| Analyse a TSDB | `promtool tsdb analyze /var/lib/prometheus` |
| List blocks | `promtool tsdb list /var/lib/prometheus` |
| Dump samples | `promtool tsdb dump /var/lib/prometheus` |
| Backfill from rules | `promtool tsdb create-blocks-from rules` |
| Backfill OpenMetrics | `promtool tsdb create-blocks-from openmetrics` |

## API Endpoints

| Prompt | Answer |
| --- | --- |
| Instant query | `GET/POST /api/v1/query?query=...&time=...` |
| Range query | `GET/POST /api/v1/query_range?query=...&start=...&end=...&step=...` |
| Series | `/api/v1/series?match[]=...` |
| Label names | `/api/v1/labels` |
| Label values | `/api/v1/label/<name>/values` |
| Targets | `/api/v1/targets` |
| Rules | `/api/v1/rules` |
| Alerts | `/api/v1/alerts` |
| Alertmanagers | `/api/v1/alertmanagers` |
| Config | `/api/v1/status/config` |
| Flags | `/api/v1/status/flags` |
| TSDB stats | `/api/v1/status/tsdb` |
| Runtime info | `/api/v1/status/runtimeinfo` |
| Reload | `POST /-/reload` |
| Quit | `POST /-/quit` |
| Health / readiness | `/-/healthy`, `/-/ready` |
| Federation | `/federate?match[]=...` |
| Pushgateway push | `POST/PUT /metrics/job/<job>/<label>/<value>` |

## Fast Diagnosis

| Symptom | First thing to check |
| --- | --- |
| Target missing entirely | `/service-discovery`, then SD config and RBAC |
| Target down | `/targets` `lastError`, then curl the endpoint yourself |
| `up == 1` but no metrics | `metric_relabel_configs` dropping everything; compare `scrape_samples_scraped` to `..._post_metric_relabeling` |
| `exported_job` appearing | Target exposes `job`; consider `honor_labels` |
| Query returns nothing | Anchored regex, label mismatch, or a window shorter than 2 scrape intervals |
| Binary operation empty | Label sets differ; use `on`/`ignoring`, and aggregate both sides identically |
| `rate()` empty | Window under 2 scrape intervals |
| Counter looks like it resets | `sum()` applied before `rate()`, or `role: service` load-balancing |
| `histogram_quantile` = `+Inf` | Highest finite bucket too low |
| `histogram_quantile` = `NaN` | Too few buckets or no observations |
| Memory growth | Cardinality. `/tsdb-status`, `scrape_series_added` |
| Alert not firing | Expression in `/graph`, `for` continuity, `/rules` health |
| Alert firing but no page | Alertmanager reachability, then silence, inhibition, mute interval, routing, timers, `..._notifications_failed_total` |
| Notifications delayed | `group_wait`, `group_interval`, `repeat_interval` |
| Duplicate notifications | Alertmanager cluster not gossiping; check `--cluster.peer` and `alertmanager_cluster_members` |
| Blank Grafana rate panel | `$__interval` instead of `$__rate_interval` |
| Ratio shown as 0.05% | `percent` unit instead of `percentunit` |
