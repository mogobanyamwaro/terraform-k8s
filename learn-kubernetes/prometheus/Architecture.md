# Prometheus Architecture

## The Full Picture

```text
                        ┌───────────────────────────────────────────────┐
   ┌──────────────┐     │              PROMETHEUS SERVER                │
   │ Jobs /       │     │                                               │
   │ Exporters    │◄────┤  ┌─────────────────┐                          │
   │ /metrics     │pull │  │ Retrieval       │ service discovery        │
   └──────────────┘     │  │ (scrape manager)│◄──── Kubernetes, Consul, │
                        │  └────────┬────────┘      DNS, EC2, file, ... │
   ┌──────────────┐     │           │                                   │
   │ Short-lived  │push │           ▼                                   │
   │ jobs ───────►│     │  ┌─────────────────┐   ┌──────────────────┐   │
   │ Pushgateway  │◄────┤  │ TSDB Storage    │──►│ Remote write     │──►│ Long-term
   └──────────────┘pull │  │ (WAL + blocks)  │◄──│ Remote read      │◄──│ storage
                        │  └────────┬────────┘   └──────────────────┘   │
                        │           │                                   │
                        │           ▼                                   │
                        │  ┌─────────────────┐                          │
                        │  │ PromQL engine   │                          │
                        │  └────┬───────┬────┘                          │
                        │       │       │                               │
                        │       ▼       ▼                               │
                        │  ┌────────┐ ┌──────────────┐                  │
                        │  │ Rule   │ │ HTTP API     │◄──── Grafana     │
                        │  │ manager│ │ + Web UI     │◄──── API clients │
                        │  └───┬────┘ └──────────────┘◄──── /federate   │
                        └──────┼────────────────────────────────────────┘
                               │ firing alerts (HTTP POST)
                               ▼
                        ┌──────────────────────────────────────┐
                        │  ALERTMANAGER (gossip cluster :9094) │
                        │  dedup → inhibit → silence → route   │
                        │  → group → notify                    │
                        └──────┬───────────────────────────────┘
                               ▼
                    PagerDuty, Slack, email, webhook, ...
```

## Components Inside The Server

| Component | Responsibility |
| --- | --- |
| **Service discovery** | Finds targets from Kubernetes, Consul, DNS, EC2, files, static config, HTTP |
| **Retrieval / scrape manager** | Scrapes targets over HTTP, applies `relabel_configs` before and `metric_relabel_configs` after |
| **TSDB** | Appends samples to the WAL, builds in-memory head blocks, compacts to on-disk blocks |
| **PromQL engine** | Parses and evaluates queries against the TSDB |
| **Rule manager** | Evaluates recording and alerting rules on `evaluation_interval` |
| **Notifier** | Queues and sends firing alerts to every configured Alertmanager |
| **HTTP API and web UI** | Serves queries, metadata, and the built-in UI |
| **Remote write / read** | Streams samples out, and optionally reads from remote stores |

## The Scrape Lifecycle

```text
1. Service discovery produces a target with __address__ and __meta_* labels
2. relabel_configs run
      - can rewrite __address__, __scheme__, __metrics_path__, __param_*
      - can drop the target entirely (keep/drop)
      - __meta_* and other __ labels are discarded afterwards, except __name__
3. Remaining labels become the target's labels; job and instance are set
      - instance defaults to __address__ if not set explicitly
4. HTTP GET <scheme>://<address><metrics_path>?<params>
      - Accept header advertises the supported exposition formats
      - X-Prometheus-Scrape-Timeout-Seconds header is sent
5. Response parsed; each sample gets the scrape timestamp
6. metric_relabel_configs run on every sample
      - can drop samples, rename metrics, drop labels
7. Target labels are attached
      - honor_labels: false (default) -> target labels win, collisions become exported_*
      - honor_labels: true            -> scraped labels win
8. sample_limit / label_limit checks; exceeding them fails the whole scrape
9. Samples appended to the WAL and the head block
10. Synthetic samples added: up, scrape_duration_seconds, scrape_samples_scraped,
    scrape_samples_post_metric_relabeling, scrape_series_added, scrape_body_size_bytes
```

Key point: **a failed scrape produces `up 0` and no other metrics from that target**, but the previous samples remain queryable until they go stale.

## Synthetic Metrics Prometheus Adds Per Scrape

| Metric | Meaning |
| --- | --- |
| `up` | 1 if the scrape succeeded, 0 if it failed |
| `scrape_duration_seconds` | How long the scrape took |
| `scrape_samples_scraped` | Samples exposed by the target |
| `scrape_samples_post_metric_relabeling` | Samples remaining after `metric_relabel_configs` |
| `scrape_series_added` | New series introduced by this scrape (churn signal) |
| `scrape_body_size_bytes` | Response size |
| `scrape_timeout_seconds` | The configured timeout (with `extra-scrape-metrics`) |

`scrape_series_added` consistently high means **series churn**, which is a cardinality warning sign.

## Ports

| Component | Port |
| --- | --- |
| Prometheus | **9090** |
| Pushgateway | **9091** |
| Alertmanager | **9093** |
| Alertmanager cluster gossip | **9094** |
| node_exporter | **9100** |
| blackbox_exporter | **9115** |
| snmp_exporter | **9116** |
| statsd_exporter | **9102** (9125/udp in) |
| Grafana | **3000** |
| mysqld_exporter | 9104 |
| postgres_exporter | 9187 |
| redis_exporter | 9121 |
| kube-state-metrics | 8080 |
| cAdvisor (via kubelet) | 10250 `/metrics/cadvisor` |

The official port allocation registry lives in the Prometheus wiki. The exam cares about the first eight.

## Endpoints On The Prometheus Server

| Path | Purpose |
| --- | --- |
| `/metrics` | Prometheus's own metrics |
| `/graph` | Expression browser |
| `/targets` | Target health, last scrape, last error |
| `/service-discovery` | Discovered targets with `__meta_*` labels, before and after relabeling |
| `/alerts` | Alerting rules and their states |
| `/rules` | All rules with health and evaluation time |
| `/config` | Loaded configuration |
| `/status` | Build, runtime, and storage info |
| `/tsdb-status` | Cardinality statistics |
| `/flags` | Command-line flags |
| `/-/healthy` | Liveness. Is the process alive? |
| `/-/ready` | Readiness. Can it serve queries? |
| `/-/reload` | `POST` to reload config. Needs `--web.enable-lifecycle` |
| `/-/quit` | `POST` to shut down. Needs `--web.enable-lifecycle` |
| `/federate` | Federation endpoint |
| `/api/v1/*` | The HTTP API |
| `/consoles/*` | Console templates, if configured |

`/-/healthy` versus `/-/ready`: healthy means the process is running; ready means it has replayed the WAL and can answer queries. On startup a large WAL replay keeps `/-/ready` failing for minutes while `/-/healthy` already succeeds. Use `/-/ready` for load balancers.

## Reloading Configuration

```bash
kill -HUP $(pidof prometheus)
curl -X POST http://localhost:9090/-/reload          # needs --web.enable-lifecycle
```

What a reload **can** change: scrape configs, rule files, alerting config, remote write/read, external labels.

What a reload **cannot** change: command-line flags. Retention, storage path, and enabled features require a restart.

A **failed** reload leaves the previous configuration running. `prometheus_config_last_reload_successful` is the only indication.

## Key Command-Line Flags

```bash
prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --storage.tsdb.retention.time=15d \
  --storage.tsdb.retention.size=0 \
  --web.listen-address=0.0.0.0:9090 \
  --web.external-url=https://prometheus.example.com \
  --web.enable-lifecycle \
  --web.enable-admin-api \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --query.lookback-delta=5m \
  --query.max-samples=50000000 \
  --query.timeout=2m \
  --query.max-concurrency=20 \
  --rules.alert.for-outage-tolerance=1h \
  --rules.alert.for-grace-period=10m \
  --log.level=info \
  --enable-feature=native-histograms,exemplar-storage
```

| Flag | Default | Note |
| --- | --- | --- |
| `--storage.tsdb.retention.time` | `15d` | Time-based retention |
| `--storage.tsdb.retention.size` | `0` (off) | Size-based retention. Whichever triggers first wins |
| `--query.lookback-delta` | `5m` | Instant selector lookback |
| `--query.max-samples` | 50,000,000 | Per-query sample limit |
| `--query.timeout` | `2m` | |
| `--web.enable-lifecycle` | off | Required for `/-/reload` and `/-/quit` |
| `--web.enable-admin-api` | off | Required for delete series, snapshot, clean tombstones |
| `--rules.alert.for-outage-tolerance` | `1h` | Pending state restoration window after restart |
| `--rules.alert.for-grace-period` | `10m` | Minimum pending time after restart |

**Retention is a flag, not YAML.** That is a favourite exam question.

## High Availability

Prometheus has **no built-in clustering**. HA means running two or more identical servers.

```text
┌──────────────┐        ┌──────────────┐
│ Prometheus A │        │ Prometheus B │   identical config
│ replica=A    │        │ replica=B    │   both scrape everything
└──────┬───────┘        └──────┬───────┘
       │  alerts               │  alerts       (replica label dropped)
       └───────┬───────────────┘
               ▼
    ┌────────────────────────────┐
    │ Alertmanager gossip cluster│  deduplicates
    └────────────────────────────┘
```

Rules:

- Both servers scrape the **same targets independently**. Their data will differ slightly because scrape timestamps differ. This is expected.
- Both send **every alert to every Alertmanager**. Alertmanager deduplicates.
- Give each server a distinct `replica` external label, then **drop it in `alert_relabel_configs`** so alerts from both are byte-identical:

```yaml
global:
  external_labels:
    cluster: prod
    replica: A

alerting:
  alert_relabel_configs:
    - regex: replica
      action: labeldrop
  alertmanagers:
    - static_configs:
        - targets: ["am-1:9093", "am-2:9093"]
```

- For a **single query view** across replicas, put something in front (Thanos Querier, Promxy) or use remote write into a single store.
- **Do not** load-balance Prometheus behind a single VIP for querying; the two replicas have different data and you will get flapping graphs.

## Scaling Patterns

| Pattern | How | Use when |
| --- | --- | --- |
| **Vertical** | Bigger machine, more RAM | The default answer. One Prometheus goes a very long way |
| **Functional sharding** | Split by concern: one server for nodes, one for apps | Clear boundaries exist |
| **Hashmod sharding** | `hashmod` on `__address__` plus `keep` on the shard index | Too many targets for one server |
| **Hierarchical federation** | Global server federates aggregates from datacenter servers | Cross-datacenter global view |
| **Remote write** | Ship everything to a central long-term store | Long retention, global queries, downsampling |
| **Agent mode** | Scrape and remote write only, no local storage or rules | Edge collection into a hub |

Hashmod sharding:

```yaml
    relabel_configs:
      - source_labels: [__address__]
        modulus: 4
        target_label: __tmp_shard
        action: hashmod
      - source_labels: [__tmp_shard]
        regex: 0            # shard index, unique per server
        action: keep
```

Hierarchical federation:

```yaml
  - job_name: federate
    honor_labels: true
    metrics_path: /federate
    params:
      'match[]':
        - '{__name__=~"job:.*"}'      # only recorded aggregates
        - '{__name__="up"}'
    static_configs:
      - targets: ["dc1-prom:9090", "dc2-prom:9090"]
```

Federation rules: **`honor_labels: true` is required**, and you should federate only **recorded aggregates**, never raw series. Federating everything does not scale and is an explicit anti-pattern.

## Agent Mode

```bash
prometheus --agent \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.agent.path=/var/lib/prometheus-agent
```

| Enabled | Disabled |
| --- | --- |
| Service discovery | Querying (`/api/v1/query`) |
| Scraping | Alerting rules |
| Relabeling | Recording rules |
| Remote write | Local block storage |
| WAL only | The expression browser |

Use it for spoke sites that forward to a hub. It is **still pull-based**; it is not a Pushgateway replacement.

## Prometheus Limitations

Straight from the documentation, and reliably examined:

| Limitation | Detail |
| --- | --- |
| **Not 100% accurate** | Scrape-based sampling means it is unsuitable for billing or per-request accounting |
| **Not for event logging** | It stores numeric samples, not individual events or log lines |
| **Local storage is not durable or clustered** | No replication. Node loss means data loss. Use remote write for durability |
| **Single-node scaling** | Vertical first; there is no built-in clustering |
| **High cardinality is the main failure mode** | Every unique label combination is a separate series in memory |
| **No downsampling** | Blocks keep full resolution for their whole retention |
| **No long-term storage** | 15 days by default. Long retention needs an external system |
| **No built-in global view** | Requires federation, remote write, or a query proxy |
| **No authentication, authorisation, or encryption by default** | Basic auth and TLS exist for the web endpoint, but there is no multi-tenancy. Put a reverse proxy in front |
| **Not a general-purpose push system** | Pushgateway is a narrow exception for batch jobs |
| **Cannot re-aggregate summary quantiles** | A data-model consequence, not a bug |

The framing to remember: **Prometheus trades perfect accuracy for reliability and simplicity.** When a question asks "which of these is Prometheus a poor fit for", the answer is per-event accounting, billing, log storage, or durable long-term storage on its own.

## Prometheus's Own Metrics Worth Knowing

```promql
# Ingestion
rate(prometheus_tsdb_head_samples_appended_total[5m])
prometheus_tsdb_head_series
prometheus_tsdb_head_chunks

# Storage
prometheus_tsdb_blocks_loaded
rate(prometheus_tsdb_compactions_total[1h])
prometheus_tsdb_compaction_duration_seconds
rate(prometheus_tsdb_wal_truncations_total[1h])
rate(prometheus_tsdb_head_truncations_total[1h])
prometheus_tsdb_reloads_failures_total
prometheus_tsdb_lowest_timestamp

# Scraping
prometheus_target_interval_length_seconds
prometheus_target_scrapes_exceeded_sample_limit_total
prometheus_target_scrapes_sample_duplicate_timestamp_total
prometheus_target_scrapes_sample_out_of_order_total
prometheus_sd_discovered_targets

# Rules
prometheus_rule_group_last_duration_seconds
prometheus_rule_group_interval_seconds
prometheus_rule_evaluation_failures_total
prometheus_rule_group_iterations_missed_total

# Notifications
prometheus_notifications_alertmanagers_discovered
prometheus_notifications_sent_total
prometheus_notifications_errors_total
prometheus_notifications_dropped_total
prometheus_notifications_queue_length

# Queries
prometheus_engine_query_duration_seconds
prometheus_engine_queries_concurrent_max

# Config
prometheus_config_last_reload_successful
prometheus_config_last_reload_success_timestamp_seconds

# Remote write
prometheus_remote_storage_samples_pending
prometheus_remote_storage_samples_failed_total
prometheus_remote_storage_samples_dropped_total
prometheus_remote_storage_highest_timestamp_in_seconds
```

## The Ecosystem

| Project | Role |
| --- | --- |
| **Prometheus** | Scrape, store, query, alert-evaluate |
| **Alertmanager** | Route, group, deduplicate, silence, inhibit notifications |
| **Pushgateway** | Cache for batch job metrics |
| **Exporters** | Translate third-party systems into exposition format |
| **Client libraries** | Direct instrumentation |
| **Grafana** | Dashboarding |
| **Thanos / Cortex / Mimir** | Long-term storage, global query, downsampling, multi-tenancy |
| **OpenMetrics** | The standardised exposition format |
| **Prometheus Operator** | Kubernetes CRDs: Prometheus, ServiceMonitor, PodMonitor, PrometheusRule, Alertmanager |
| **kube-prometheus-stack** | The packaged Kubernetes monitoring bundle |

CNCF status: **Prometheus was the second project to join CNCF (after Kubernetes) and graduated in 2018.** OpenMetrics is also a CNCF project, derived from the Prometheus exposition format.

## Memorise

- **Prometheus pulls.** The Pushgateway is a narrow exception, and it is also pulled by Prometheus.
- Components: **service discovery, retrieval, TSDB, PromQL engine, rule manager, notifier, HTTP API**.
- **Ports 9090 / 9091 / 9093 / 9094 / 9100 / 9115 / 3000.**
- Synthetic per-scrape metrics: **`up`, `scrape_duration_seconds`, `scrape_samples_scraped`, `scrape_samples_post_metric_relabeling`, `scrape_series_added`, `scrape_body_size_bytes`**.
- **`relabel_configs` before the scrape** (targets), **`metric_relabel_configs` after** (samples).
- `/-/healthy` = alive. `/-/ready` = can serve queries (WAL replayed).
- Reload with **SIGHUP** or **`POST /-/reload`** with `--web.enable-lifecycle`. Flags need a restart.
- **Retention is a command-line flag**, not YAML. Default **15d**, size retention default **0**.
- **HA = two identical servers.** Distinct `replica` external label, **dropped** in `alert_relabel_configs`. Alertmanager deduplicates.
- **Prometheus sends every alert to every Alertmanager.** Do not load-balance.
- Federation requires **`honor_labels: true`** and should carry **aggregates only**.
- **Agent mode**: scrape plus remote write, WAL only, no queries, alerts, or rules.
- Limitations: **not accurate enough for billing, not for event logging, local storage not durable or clustered, no downsampling, no built-in global view or multi-tenancy, single-node scaling, high cardinality is the killer.**
