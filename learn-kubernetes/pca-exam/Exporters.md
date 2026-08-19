# Exporters Reference

## What An Exporter Is

A process that translates a third-party system's state into Prometheus exposition format, so Prometheus can **scrape** it. Exporters are never pushed to.

```text
┌─────────────┐  native protocol  ┌──────────────┐   /metrics    ┌────────────┐
│ MySQL       │◄──────────────────│ mysqld_      │◄──────────────│ Prometheus │
│ (no native  │ SHOW GLOBAL STATUS│ exporter     │  exposition   │            │
│  support)   │                   │ :9104        │               │            │
└─────────────┘                   └──────────────┘               └────────────┘
```

Two topologies:

| Topology | Deployment | Examples |
| --- | --- | --- |
| **Local / sidecar** | One exporter per monitored instance | node_exporter, mysqld_exporter, redis_exporter |
| **Multi-target / central** | One exporter serves many targets, selected by a URL parameter | blackbox_exporter, snmp_exporter |

Multi-target exporters always need the `__param_target` relabel pattern.

## Ports

Official:

| Exporter | Port |
| --- | ---: |
| **node_exporter** | **9100** |
| **pushgateway** | **9091** |
| **blackbox_exporter** | **9115** |
| **snmp_exporter** | **9116** |
| **statsd_exporter** | **9102** (9125/udp in) |
| haproxy_exporter | 9101 |
| collectd_exporter | 9103 |
| mysqld_exporter | 9104 |
| cloudwatch_exporter | 9106 |
| consul_exporter | 9107 |
| graphite_exporter | 9108 |
| memcached_exporter | 9150 |
| windows_exporter | 9182 |

Common third-party:

| Exporter | Port |
| --- | ---: |
| nginx-prometheus-exporter | 9113 |
| elasticsearch_exporter | 9114 |
| redis_exporter | 9121 |
| mongodb_exporter | 9216 |
| jmx_exporter | 9404 |
| postgres_exporter | 9187 |
| kafka_exporter | 9308 |
| rabbitmq_exporter | 9419 |
| kube-state-metrics | 8080 (telemetry 8081) |
| cAdvisor (standalone) | 8080 |

Memorise the bold ones plus mysqld 9104, postgres 9187, redis 9121.

## node_exporter

```bash
node_exporter \
  --collector.systemd \
  --collector.processes \
  --collector.textfile.directory=/var/lib/node_exporter/textfile \
  --no-collector.hwmon \
  --web.listen-address=:9100
```

Container:

```bash
docker run -d --name node-exporter \
  --pid=host -v /:/host:ro,rslave -p 9100:9100 \
  prom/node-exporter:v1.9.1 --path.rootfs=/host
```

| Metric | Type | Notes |
| --- | --- | --- |
| `node_cpu_seconds_total{cpu, mode}` | counter | Modes: user, system, idle, iowait, nice, irq, softirq, steal. **Cardinality = cores x modes** |
| `node_memory_MemTotal_bytes`, `node_memory_MemAvailable_bytes` | gauge | **Prefer `MemAvailable` over `MemFree`** |
| `node_filesystem_size_bytes`, `node_filesystem_avail_bytes` | gauge | Labels `device`, `fstype`, `mountpoint`. **Filter `fstype!~"tmpfs\|overlay\|squashfs"`** |
| `node_filesystem_files`, `node_filesystem_files_free` | gauge | Inodes |
| `node_disk_read_bytes_total`, `node_disk_written_bytes_total`, `node_disk_io_time_seconds_total` | counter | Per `device` |
| `node_network_receive_bytes_total`, `node_network_transmit_bytes_total`, `node_network_*_errs_total`, `node_network_*_drop_total` | counter | Per `device`. Exclude `lo` |
| `node_load1`, `node_load5`, `node_load15` | gauge | |
| `node_boot_time_seconds` | gauge | Uptime = `time() - this` |
| `node_time_seconds`, `node_timex_offset_seconds` | gauge | Clock skew |
| `node_systemd_unit_state{name, state}` | gauge | Needs the systemd collector |
| `node_scrape_collector_success{collector}` | gauge | Which collectors are working |
| `node_scrape_collector_duration_seconds` | gauge | Per-collector cost |
| `node_textfile_scrape_error` | gauge | 1 on a parse failure |
| `node_textfile_mtime_seconds{file}` | gauge | File age, for staleness alerts |
| `node_uname_info` | gauge | Info metric with `nodename`, `release`, `machine` |
| `node_vmstat_pgmajfault`, `node_pressure_*` | counter/gauge | Memory pressure |

Standard queries:

```promql
1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m]))
count by (instance) (count by (instance, cpu) (node_cpu_seconds_total))
1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)
1 - (node_filesystem_avail_bytes{fstype!~"tmpfs|overlay|squashfs"}
     / node_filesystem_size_bytes{fstype!~"tmpfs|overlay|squashfs"})
(time() - node_boot_time_seconds) / 86400
sum by (instance) (rate(node_network_receive_bytes_total{device!="lo"}[5m]))
rate(node_disk_io_time_seconds_total[5m])
node_scrape_collector_success == 0
```

## The Textfile Collector

The standard way to get **arbitrary script output** into Prometheus without writing an exporter.

```bash
--collector.textfile.directory=/var/lib/node_exporter/textfile
```

```bash
# ALWAYS write to a temp file and mv, because mv is atomic
TMP=/var/lib/node_exporter/textfile/.backup.prom.$$
cat > "$TMP" <<EOF
# HELP backup_last_success_timestamp_seconds Unix time of the last successful backup.
# TYPE backup_last_success_timestamp_seconds gauge
backup_last_success_timestamp_seconds $(date +%s)
# HELP backup_size_bytes Size of the last backup.
# TYPE backup_size_bytes gauge
backup_size_bytes 4823910
EOF
mv "$TMP" /var/lib/node_exporter/textfile/backup.prom
```

Rules:

- Files must end in **`.prom`**.
- **Re-read on every scrape**, so values persist between script runs.
- **Write to a temp file and `mv`.** A partially written file yields parse errors.
- Health: **`node_textfile_scrape_error`** (1 on failure) and **`node_textfile_mtime_seconds`** (age).

```promql
node_textfile_scrape_error == 1
time() - node_textfile_mtime_seconds > 3600
```

### Textfile collector versus Pushgateway

| | Textfile collector | Pushgateway |
| --- | --- | --- |
| Location | A file on the host | A central service |
| Discovery | Uses the host's existing node_exporter target | A separate scrape job |
| Best for | **Machine-level** cron jobs | **Service-level** batch jobs |
| Staleness signal | `node_textfile_mtime_seconds` | `push_time_seconds` |
| Requires | node_exporter on that host | Network reachability |
| Cleanup | Delete the file | Explicit `DELETE`; no TTL |

## blackbox_exporter

Probes endpoints **from the outside**, with no cooperation from the target.

`blackbox.yml`:

```yaml
modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_status_codes: []                       # empty means 2xx
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      method: GET
      follow_redirects: true
      preferred_ip_protocol: ip4
      fail_if_body_not_matches_regexp: ["healthy"]
      fail_if_header_matches:
        - header: Set-Cookie
          regexp: '.*'
      tls_config:
        insecure_skip_verify: false

  http_post_2xx:
    prober: http
    http:
      method: POST
      body: '{"probe":true}'
      headers:
        Content-Type: application/json

  tcp_connect:
    prober: tcp
    timeout: 5s

  ssh_banner:
    prober: tcp
    tcp:
      query_response:
        - expect: "^SSH-2.0-"

  icmp:
    prober: icmp
    icmp:
      preferred_ip_protocol: ip4

  dns_soa:
    prober: dns
    dns:
      query_name: example.com
      query_type: SOA
      validate_answer_rrs:
        fail_if_not_matches_regexp: [".*"]

  grpc_healthcheck:
    prober: grpc
```

The scrape config, which you must recognise instantly:

```yaml
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
```

Metrics:

| Metric | Meaning |
| --- | --- |
| `probe_success` | **1 if the probe succeeded.** This is what you alert on |
| `probe_duration_seconds` | Total probe time |
| `probe_http_status_code` | Status returned |
| `probe_http_duration_seconds{phase}` | Phases: `resolve`, `connect`, `tls`, `processing`, `transfer` |
| `probe_http_version` | |
| `probe_http_content_length` | |
| `probe_http_redirects` | |
| `probe_ssl_earliest_cert_expiry` | **Unix timestamp** of the earliest cert expiry |
| `probe_ssl_last_chain_expiry_timestamp_seconds` | Chain expiry |
| `probe_http_ssl` | 1 if TLS was used |
| `probe_tls_version_info` | Info metric |
| `probe_dns_lookup_time_seconds` | |
| `probe_ip_protocol` | 4 or 6 |
| `probe_ip_addr_hash` | Detects IP changes |
| `probe_failed_due_to_regex` | 1 if a body regex check failed |

**Two-level health**: `up` says whether Prometheus can reach the **exporter**; `probe_success` says whether the **probed endpoint** is healthy. Alert on `probe_success == 0`, not `up == 0`.

```promql
probe_success == 0
(probe_ssl_earliest_cert_expiry - time()) / 86400 < 14
probe_http_status_code >= 400
probe_duration_seconds > 5
sum by (instance) (probe_http_duration_seconds)
```

Debugging:

```bash
curl -s 'http://localhost:9115/probe?module=http_2xx&target=https://prometheus.io' | grep -v '^#'
curl -s 'http://localhost:9115/probe?module=http_2xx&target=https://prometheus.io&debug=true'
```

The `debug=true` output is the best blackbox troubleshooting tool there is.

## snmp_exporter

Same multi-target pattern:

```yaml
  - job_name: snmp
    metrics_path: /snmp
    params:
      module: [if_mib]
      auth: [public_v2]
    static_configs:
      - targets: ["switch-1", "switch-2"]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter:9116
```

`snmp.yml` is generated from MIBs by the `generator` tool. You will not be asked to write it.

## statsd_exporter and graphite_exporter

**Push-to-pull bridges.** Applications keep pushing StatsD or Graphite; Prometheus scrapes the exporter.

```text
App ──UDP StatsD──► statsd_exporter :9125 ──► /metrics :9102 ◄──scrape── Prometheus
```

```yaml
mappings:
  - match: "myapp.request.*.*"
    name: "myapp_requests_total"
    labels:
      method: "$1"
      status: "$2"
  - match: "myapp\\.latency\\.(.+)"
    match_type: regex
    name: "myapp_latency_seconds"
    labels:
      endpoint: "$1"
```

This is the standard **migration path** off StatsD or Graphite. If a question describes existing push-based instrumentation you cannot change, this is the answer.

## Kubernetes: kube-state-metrics vs cAdvisor vs node_exporter

A constantly confused trio.

| | kube-state-metrics | cAdvisor | node_exporter |
| --- | --- | --- | --- |
| Source | **Kubernetes API server** | **Container runtime / cgroups** | **Host `/proc` and `/sys`** |
| Answers | "What does the cluster **declare**?" | "What are containers **using**?" | "What is the **machine** doing?" |
| Examples | `kube_deployment_spec_replicas`, `kube_pod_status_phase`, `kube_node_status_condition`, `kube_pod_container_status_restarts_total` | `container_cpu_usage_seconds_total`, `container_memory_working_set_bytes`, `container_network_receive_bytes_total` | `node_cpu_seconds_total`, `node_filesystem_avail_bytes` |
| Deployed as | A Deployment, usually one replica | **Built into the kubelet** at `/metrics/cadvisor` | A DaemonSet |
| Nature | Object **state** | Resource **usage** | Host resources |

kube-state-metrics does **not** report resource usage. cAdvisor does **not** know about Deployments or Ingresses. Questions test exactly that boundary.

## Writing Your Own Exporter

Guidelines from the documentation:

1. **Query the backing system when scraped**, from inside a custom collector. Do not poll into a cache on a timer.
2. Expose **`<system>_up`** indicating whether the backend is reachable.
3. Expose scrape health: `<system>_exporter_last_scrape_error`, `<system>_exporter_scrape_duration_seconds`.
4. **Prefix metrics with the exported system's name.**
5. **Do not set your own timestamps.**
6. **Do not expose `job` or `instance` labels.**
7. Convert to base units (seconds, bytes, ratios).
8. Honour the timeout, using `X-Prometheus-Scrape-Timeout-Seconds` if you can.
9. Preserve the source system's naming where it does not conflict with conventions.

## Two-Level Health Monitoring

```promql
up{job="mysql"} == 0                   # Prometheus cannot reach the exporter
mysql_up == 0                          # The exporter cannot reach MySQL
mysql_exporter_last_scrape_error == 1  # The exporter's own last collection failed
probe_success == 0                     # The probed endpoint is unhealthy
node_textfile_scrape_error == 1        # A textfile failed to parse
node_scrape_collector_success == 0     # A node_exporter collector is failing
```

`up == 1` with `mysql_up == 0` means the exporter is fine and the database is not. Recognising which metric answers which question is the point.

## Traps

| Mistake | Consequence |
| --- | --- |
| Alerting on `up == 0` for blackbox probes | `up` covers the exporter, not the probed endpoint. Use `probe_success` |
| Omitting the third relabel rule | Prometheus connects to the probed URL instead of the exporter |
| Expecting kube-state-metrics to report CPU usage | It reports object state only |
| Expecting cAdvisor to know about Deployments | It sees containers only |
| Writing a `.prom` file directly without `mv` | Parse errors from partial writes |
| Using the Pushgateway for a machine-level cron job | Textfile collector is simpler and gives you the right staleness signal |
| An exporter exposing `job`/`instance` | Collides, becomes `exported_*` |
| An exporter polling on a timer | Stale-cache lag; collect on scrape |
| Not filtering `fstype` | Alerts on tmpfs and container overlay filesystems |
| `node_memory_MemFree_bytes` for available memory | Understates it badly on Linux; use `MemAvailable` |

## Memorise

- An exporter **translates** a third-party system and is **scraped**, never pushed to.
- Ports: **node 9100, pushgateway 9091, blackbox 9115, snmp 9116, statsd 9102, mysqld 9104, postgres 9187, redis 9121, kube-state-metrics 8080**.
- **Multi-target exporters** (blackbox, snmp) need: `__address__` → `__param_target`, `__param_target` → `instance`, `__address__` → the exporter.
- **`up` = Prometheus to exporter. `probe_success` / `<system>_up` = exporter to target.**
- `probe_ssl_earliest_cert_expiry` is a **Unix timestamp**; days left = `(x - time()) / 86400`.
- **Textfile collector**: `.prom` files, **re-read every scrape**, temp file plus **`mv`**, health via `node_textfile_scrape_error` and `node_textfile_mtime_seconds`.
- **Textfile collector = machine-level jobs. Pushgateway = service-level jobs.**
- Prefer **`node_memory_MemAvailable_bytes`**; filter **`fstype!~"tmpfs|overlay"`**; exclude `device="lo"`.
- `node_cpu_seconds_total` cardinality = **cores x modes**.
- **statsd_exporter and graphite_exporter are push-to-pull bridges**, the standard migration path.
- **kube-state-metrics = object state from the API. cAdvisor = container usage, served by the kubelet at `/metrics/cadvisor`. node_exporter = host resources.**
- Writing an exporter: **collect on scrape**, expose **`<system>_up`**, prefix with the system name, **no timestamps**, **no `job`/`instance`**, base units.
