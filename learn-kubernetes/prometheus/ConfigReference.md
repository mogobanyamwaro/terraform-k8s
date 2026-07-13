# prometheus.yml Reference

Every block you need to recognise, with defaults marked. Defaults are the most examined part of this file.

## Top-Level Structure

```yaml
global:            # defaults for everything else
runtime:           # Go runtime tuning
rule_files:        # recording and alerting rule files
scrape_config_files: # externalised scrape configs
scrape_configs:    # what to scrape
alerting:          # where to send alerts
remote_write:      # stream samples out
remote_read:       # read samples from a remote store
storage:           # TSDB and exemplar options
tracing:           # OTLP tracing for Prometheus itself
```

## global

```yaml
global:
  scrape_interval: 1m           # DEFAULT 1m
  scrape_timeout: 10s           # DEFAULT 10s
  evaluation_interval: 1m       # DEFAULT 1m
  query_log_file: /var/log/prometheus/query.log
  body_size_limit: 0            # 0 = unlimited
  sample_limit: 0               # 0 = unlimited
  target_limit: 0
  label_limit: 0
  label_name_length_limit: 0
  label_value_length_limit: 0
  keep_dropped_targets: 0
  scrape_protocols:
    - OpenMetricsText1.0.0
    - OpenMetricsText0.0.1
    - PrometheusText0.0.4
  external_labels:
    cluster: prod
    replica: A
    region: eu-west-1
```

| Setting | Default | Note |
| --- | --- | --- |
| `scrape_interval` | **`1m`** | Must be **less than 5m** (the lookback delta) |
| `scrape_timeout` | **`10s`** | Must be **≤ `scrape_interval`** |
| `evaluation_interval` | **`1m`** | Rule evaluation frequency |

**`external_labels`** are attached to:

- Every **alert** sent to Alertmanager
- Every sample exposed via **`/federate`**
- Every sample sent via **remote write**

They are **not** attached to locally stored samples, so `up{cluster="prod"}` does not work locally unless you also relabel. They exist to identify the source Prometheus, and are essential for HA (`replica`) and multi-cluster setups (`cluster`).

## scrape_configs

```yaml
scrape_configs:
  - job_name: example                    # REQUIRED, becomes the `job` label
    scrape_interval: 15s                 # overrides global
    scrape_timeout: 10s
    scrape_protocols: [...]
    metrics_path: /metrics               # DEFAULT /metrics
    scheme: http                         # DEFAULT http
    honor_labels: false                  # DEFAULT false
    honor_timestamps: true               # DEFAULT true
    track_timestamps_staleness: false
    follow_redirects: true               # DEFAULT true
    enable_http2: true                   # DEFAULT true
    sample_limit: 0
    target_limit: 0
    label_limit: 0
    body_size_limit: 0
    fallback_scrape_protocol: PrometheusText0.0.4

    params:
      module: [http_2xx]
      format: [prometheus]

    basic_auth:
      username: prom
      password: secret
      # or
      password_file: /etc/prometheus/pw

    authorization:
      type: Bearer                       # DEFAULT Bearer
      credentials: <token>
      # or
      credentials_file: /var/run/secrets/kubernetes.io/serviceaccount/token

    oauth2:
      client_id: ...
      client_secret_file: ...
      token_url: https://auth.example.com/token
      scopes: [metrics]

    tls_config:
      ca_file: /etc/ssl/ca.crt
      cert_file: /etc/ssl/client.crt
      key_file: /etc/ssl/client.key
      server_name: metrics.example.com
      insecure_skip_verify: false        # DEFAULT false
      min_version: TLS12

    proxy_url: http://proxy:3128
    no_proxy: "localhost,127.0.0.1"

    # Service discovery (one or more)
    static_configs: [...]
    file_sd_configs: [...]
    http_sd_configs: [...]
    kubernetes_sd_configs: [...]
    consul_sd_configs: [...]
    dns_sd_configs: [...]
    ec2_sd_configs: [...]

    relabel_configs: [...]               # BEFORE the scrape, on TARGETS
    metric_relabel_configs: [...]        # AFTER the scrape, on SAMPLES
```

### The settings that get examined

| Setting | Default | Meaning |
| --- | --- | --- |
| `metrics_path` | **`/metrics`** | |
| `scheme` | **`http`** | |
| `honor_labels` | **`false`** | `false`: target labels win, collisions become `exported_*`. `true`: scraped labels win. **Required `true` for the Pushgateway and federation** |
| `honor_timestamps` | **`true`** | If `false`, Prometheus ignores timestamps in the exposition and uses the scrape time |
| `sample_limit` | **`0`** (unlimited) | Exceeding it **fails the entire scrape** |
| `target_limit` | `0` | Max targets from SD for this job |
| `label_limit` | `0` | Max labels per sample |
| `follow_redirects` | `true` | |
| `enable_http2` | `true` | |
| `insecure_skip_verify` | `false` | |

`sample_limit` is important: it does not truncate, it **fails the scrape**, giving `up 0`. Detect it with:

```promql
prometheus_target_scrapes_exceeded_sample_limit_total
```

### honor_labels in detail

```text
honor_labels: false (DEFAULT)
  scraped:  job="app" instance="x"
  target:   job="pushgateway" instance="pg:9091"
  result:   job="pushgateway" instance="pg:9091"
            exported_job="app" exported_instance="x"

honor_labels: true
  result:   job="app" instance="x"
            (target labels applied only where absent)
```

Use `honor_labels: true` for the **Pushgateway** and for **federation**. Everywhere else leave it false.

## rule_files

```yaml
rule_files:
  - /etc/prometheus/rules/*.yml
  - /etc/prometheus/rules/alerts/*.yaml
  - /etc/prometheus/single-rule.yml
```

Globs are **re-expanded on every reload**, so adding a matching new file needs only a reload, not a config edit.

## alerting

```yaml
alerting:
  alert_relabel_configs:
    - regex: replica
      action: labeldrop
  alertmanagers:
    - static_configs:
        - targets: ["am1:9093", "am2:9093"]
      # or use SD
      kubernetes_sd_configs:
        - role: endpoints
          namespaces:
            names: [monitoring]
      relabel_configs:
        - source_labels: [__meta_kubernetes_service_name]
          regex: alertmanager
          action: keep
      scheme: http                # DEFAULT http
      path_prefix: /              # DEFAULT /
      timeout: 10s                # DEFAULT 10s
      api_version: v2             # DEFAULT v2
```

Facts:

- Prometheus sends **every alert to every discovered Alertmanager**. Do not load-balance.
- `api_version: v2` is current; `v1` is deprecated.
- `alert_relabel_configs` runs on alerts before sending. The `replica` `labeldrop` is the standard HA pattern.

## remote_write

```yaml
remote_write:
  - url: https://remote.example.com/api/v1/write
    name: central
    remote_timeout: 30s              # DEFAULT 30s
    send_exemplars: false
    send_native_histograms: false
    basic_auth: {...}
    tls_config: {...}
    write_relabel_configs:
      - source_labels: [__name__]
        regex: 'job:.*|up'
        action: keep
      - regex: replica
        action: labeldrop
    queue_config:
      capacity: 10000                # DEFAULT 10000
      max_shards: 200                # DEFAULT 200
      min_shards: 1                  # DEFAULT 1
      max_samples_per_send: 2000     # DEFAULT 2000
      batch_send_deadline: 5s        # DEFAULT 5s
      min_backoff: 30ms
      max_backoff: 5s
      retry_on_http_429: true
    metadata_config:
      send: true
      send_interval: 1m
```

## remote_read

```yaml
remote_read:
  - url: https://remote.example.com/api/v1/read
    name: central
    remote_timeout: 1m
    read_recent: false
    required_matchers:
      cluster: prod
    filter_external_labels: true
```

## storage

```yaml
storage:
  tsdb:
    out_of_order_time_window: 30m
  exemplars:
    max_exemplars: 100000
```

Note that **retention is not here.** It is a command-line flag. Only a small number of storage options are in YAML.

## runtime

```yaml
runtime:
  gogc: 75              # Go GC target percentage; lower means less RAM, more CPU
```

## scrape_config_files

```yaml
scrape_config_files:
  - /etc/prometheus/scrape/*.yml
```

Lets you externalise scrape configs into separate files, useful when many teams contribute jobs.

## Complete Realistic Example

```yaml
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s
  external_labels:
    cluster: production
    replica: A

rule_files:
  - /etc/prometheus/rules/*.yml

alerting:
  alert_relabel_configs:
    - regex: replica
      action: labeldrop
  alertmanagers:
    - static_configs:
        - targets: ["alertmanager-0:9093", "alertmanager-1:9093"]

remote_write:
  - url: https://mimir.example.com/api/v1/push
    write_relabel_configs:
      - source_labels: [__name__]
        regex: 'job:.*|instance:.*|up|node_.*'
        action: keep

scrape_configs:
  # 1. Prometheus itself
  - job_name: prometheus
    static_configs:
      - targets: ["localhost:9090"]

  # 2. Static nodes with extra labels
  - job_name: node
    static_configs:
      - targets: ["node1:9100", "node2:9100"]
        labels:
          env: production
      - targets: ["node3:9100"]
        labels:
          env: staging
    metric_relabel_configs:
      # Drop expensive metrics we never query
      - source_labels: [__name__]
        regex: 'node_scrape_collector_.*|go_memstats_.*'
        action: drop

  # 3. File-based SD, no reload needed on change
  - job_name: apps
    file_sd_configs:
      - files: ["/etc/prometheus/targets/*.json"]
        refresh_interval: 30s

  # 4. Pushgateway: honor_labels is MANDATORY
  - job_name: pushgateway
    honor_labels: true
    static_configs:
      - targets: ["pushgateway:9091"]

  # 5. Blackbox: the three-rule multi-target pattern
  - job_name: blackbox
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets: ["https://example.com", "https://prometheus.io"]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115

  # 6. Kubernetes pods, annotation driven
  - job_name: kubernetes-pods
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        target_label: namespace
      - source_labels: [__meta_kubernetes_pod_name]
        target_label: pod

  # 7. API server with in-cluster credentials
  - job_name: kubernetes-apiservers
    kubernetes_sd_configs:
      - role: endpoints
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    authorization:
      credentials_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - source_labels:
          - __meta_kubernetes_namespace
          - __meta_kubernetes_service_name
          - __meta_kubernetes_endpoint_port_name
        action: keep
        regex: default;kubernetes;https

  # 8. Federation from a lower-level Prometheus
  - job_name: federate
    honor_labels: true
    metrics_path: /federate
    params:
      'match[]':
        - '{__name__=~"job:.*"}'
        - '{__name__="up"}'
    static_configs:
      - targets: ["dc1-prom:9090", "dc2-prom:9090"]

  # 9. A high-cardinality target with a safety limit
  - job_name: chatty-app
    sample_limit: 50000
    static_configs:
      - targets: ["chatty:8080"]
    metric_relabel_configs:
      - regex: 'pod_template_hash|controller_revision_hash|id'
        action: labeldrop
```

## Validation And Reload

```bash
promtool check config /etc/prometheus/prometheus.yml    # also checks referenced rule files
promtool check rules /etc/prometheus/rules/*.yml

kill -HUP $(pidof prometheus)
curl -X POST http://localhost:9090/-/reload             # needs --web.enable-lifecycle

# Confirm it took effect
curl -s http://localhost:9090/api/v1/status/config | jq -r '.data.yaml'
```

```promql
prometheus_config_last_reload_successful           # must be 1
prometheus_config_last_reload_success_timestamp_seconds
```

**A failed reload keeps the previous configuration running.** That metric is your only signal.

## What A Reload Can And Cannot Change

| Reloadable | Requires a restart |
| --- | --- |
| `scrape_configs` | Retention flags |
| `rule_files` and their contents | `--storage.tsdb.path` |
| `alerting` | `--web.listen-address` |
| `remote_write` / `remote_read` | `--enable-feature` flags |
| `external_labels` | `--query.*` flags |
| `global` intervals | Agent mode |

## Alertmanager Configuration Quick Reference

```yaml
global:
  resolve_timeout: 5m               # DEFAULT 5m
  smtp_smarthost: smtp:587
  smtp_from: alerts@example.com
  slack_api_url: https://hooks.slack.com/...

templates:
  - /etc/alertmanager/templates/*.tmpl

route:
  receiver: default                 # REQUIRED on the root
  group_by: [alertname, cluster]
  group_wait: 30s                   # DEFAULT 30s
  group_interval: 5m                # DEFAULT 5m
  repeat_interval: 4h               # DEFAULT 4h
  routes:
    - receiver: pager
      matchers:
        - severity = "critical"
      continue: false               # DEFAULT false
      mute_time_intervals: [out_of_hours]
      routes:
        - receiver: pager-db
          matchers:
            - team = "database"

inhibit_rules:
  - source_matchers: [severity = "critical"]
    target_matchers: [severity = "warning"]
    equal: [alertname, cluster]

time_intervals:
  - name: out_of_hours
    time_intervals:
      - weekdays: [saturday, sunday]
      - times:
          - start_time: '00:00'
            end_time: '09:00'
        location: Europe/London

receivers:
  - name: default
    webhook_configs:
      - url: http://sink:5001/
        send_resolved: true         # webhook DEFAULT true
  - name: pager
    pagerduty_configs:
      - routing_key: abc
  - name: dev-null                  # empty receiver = drop
```

```bash
amtool check-config /etc/alertmanager/alertmanager.yml
amtool config routes show
amtool config routes test severity=critical team=database
curl -X POST http://localhost:9093/-/reload
```

## Defaults Table (Memorise This)

| Setting | Default |
| --- | --- |
| `scrape_interval` | `1m` |
| `scrape_timeout` | `10s` |
| `evaluation_interval` | `1m` |
| `metrics_path` | `/metrics` |
| `scheme` | `http` |
| `honor_labels` | `false` |
| `honor_timestamps` | `true` |
| `sample_limit` | `0` (unlimited) |
| `follow_redirects` | `true` |
| `insecure_skip_verify` | `false` |
| Alertmanager `api_version` | `v2` |
| Alertmanager `timeout` | `10s` |
| `remote_timeout` | `30s` |
| `queue_config.capacity` | `10000` |
| `queue_config.max_shards` | `200` |
| `queue_config.max_samples_per_send` | `2000` |
| TSDB retention time (flag) | `15d` |
| TSDB retention size (flag) | `0` (off) |
| Block range | `2h` |
| Lookback delta | `5m` |
| Query max samples | 50,000,000 |
| Query timeout | `2m` |
| AM `resolve_timeout` | `5m` |
| AM `group_wait` | `30s` |
| AM `group_interval` | `5m` |
| AM `repeat_interval` | `4h` |
| Prometheus port | `9090` |
| Alertmanager port | `9093` |
| Alertmanager cluster port | `9094` |
| Pushgateway port | `9091` |

## Traps

| Mistake | Consequence |
| --- | --- |
| Retention in YAML | Ignored. It is a flag |
| `scrape_timeout` > `scrape_interval` | Config error |
| `scrape_interval` > 5m | Gaps, because it exceeds the lookback delta |
| Pushgateway job without `honor_labels: true` | `job="pushgateway"` plus `exported_job` |
| Federation without `honor_labels: true` | Source labels destroyed |
| Expecting `external_labels` on local samples | They are only added on egress (alerts, federation, remote write) |
| Forgetting `alert_relabel_configs` `labeldrop` of `replica` in HA | Duplicate alerts |
| Load-balancing Alertmanagers | Breaks the fan-out-then-deduplicate design |
| Assuming a failed reload is visible | Only `prometheus_config_last_reload_successful` shows it |
| `sample_limit` truncating | It **fails the whole scrape** instead |
