# Relabeling

Relabeling is Prometheus's universal label-rewriting mechanism. It appears in four different places, each operating on a different thing.

## The Four Places

| Block | Where | Operates on | Runs |
| --- | --- | --- | --- |
| **`relabel_configs`** | Inside `scrape_configs` | **Targets** (before the scrape) | After service discovery, before the HTTP request |
| **`metric_relabel_configs`** | Inside `scrape_configs` | **Samples** (after the scrape) | After parsing the response, before ingestion |
| **`write_relabel_configs`** | Inside `remote_write` | **Samples** leaving via remote write | Before sending |
| **`alert_relabel_configs`** | Inside `alerting` | **Alerts** going to Alertmanager | Before sending |

```text
service discovery
   │  __address__, __meta_*, __scheme__, __metrics_path__
   ▼
relabel_configs ──────────► can DROP the target, rewrite the URL, set labels
   │
   ▼
HTTP GET the target
   │
   ▼
parse samples
   │
   ▼
metric_relabel_configs ───► can DROP samples, rename metrics, drop labels
   │
   ▼
attach target labels (honor_labels decides collisions)
   │
   ▼
TSDB ──► remote_write ──► write_relabel_configs
   │
   ▼
rules ──► alerts ──► alert_relabel_configs ──► Alertmanager
```

The distinction is examined constantly: **`relabel_configs` cannot filter metrics, and `metric_relabel_configs` cannot drop targets.** Dropping a target with `metric_relabel_configs` is impossible; dropping a metric with `relabel_configs` is impossible.

## The Rule Structure

```yaml
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app, __meta_kubernetes_namespace]
        separator: ;
        regex: (.+);(production|staging)
        modulus: 0
        target_label: app
        replacement: $1
        action: replace
```

| Field | Default | Meaning |
| --- | --- | --- |
| `source_labels` | `[]` | Labels whose values are concatenated with `separator` to form the input string |
| `separator` | `;` | Joins the source label values |
| `regex` | `(.*)` | RE2 regex, **fully anchored**, matched against the concatenated input |
| `modulus` | | For `hashmod`: the divisor |
| `target_label` | | Label to write |
| `replacement` | `$1` | Value to write, with `$1`, `$2` or `${1}` capture references |
| `action` | `replace` | What to do |

Key defaults to remember: **`separator` is `;`**, **`regex` is `(.*)`**, **`replacement` is `$1`**, **`action` is `replace`**.

## The Actions

| Action | Effect |
| --- | --- |
| `replace` | If `regex` matches, set `target_label` to the expanded `replacement`. **If it does not match, the rule is a no-op** |
| `keep` | Keep the target/sample only if `regex` **matches** |
| `drop` | Drop the target/sample if `regex` **matches** |
| `keepequal` | Keep if the concatenated source values **equal** `target_label`'s value |
| `dropequal` | Drop if the concatenated source values **equal** `target_label`'s value |
| `hashmod` | Set `target_label` to `hash(concatenated_sources) mod modulus` |
| `labelmap` | For every **label name** matching `regex`, copy its value to a new label named by `replacement` |
| `labeldrop` | **Remove every label whose name matches `regex`** |
| `labelkeep` | **Remove every label whose name does not match `regex`** |
| `lowercase` / `uppercase` | Set `target_label` to the case-converted source value |

Critical notes:

- `labelmap`, `labeldrop`, and `labelkeep` match against **label names**, not values. All other actions match against **values**.
- A `replace` whose regex does not match does **nothing**. It does not clear the target label.
- Setting `replacement` to an empty string **deletes** the target label.
- `labeldrop` and `labelkeep` must not remove `__name__`; doing so is an error.
- Rules run **in order**, and each sees the result of the previous.

## Special Labels

| Label | Meaning |
| --- | --- |
| `__address__` | `host:port` Prometheus will connect to. **Required** |
| `__scheme__` | `http` or `https`. Default `http` |
| `__metrics_path__` | Path to scrape. Default `/metrics` |
| `__param_<name>` | Becomes URL query parameter `<name>` |
| `__meta_*` | Metadata from service discovery. Read-only inputs |
| `__tmp_*` | Reserved for user temporaries; never ingested |
| `__name__` | The metric name. Only meaningful in `metric_relabel_configs` |
| `__scrape_interval__`, `__scrape_timeout__` | Per-target overrides |

Rules:

- **All labels starting with `__` are discarded after `relabel_configs` completes**, except that they were used to build the request. The exception is `__name__`, which is a real label on every sample.
- If `instance` is not set explicitly, Prometheus sets it to the final `__address__`.
- `job` comes from `job_name` unless relabeling overrides it.

## Canonical Recipes

### Keep only targets with an annotation

```yaml
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        regex: "true"
        action: keep
```

### Drop targets

```yaml
      - source_labels: [__meta_kubernetes_namespace]
        regex: kube-system
        action: drop
```

### Rewrite the metrics path from an annotation

```yaml
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
        regex: (.+)
        target_label: __metrics_path__
        action: replace
```

Note the `regex: (.+)` guard: without it, a missing annotation would set the path to empty. With it, the rule is a no-op when the annotation is absent.

### Rewrite the port from an annotation

```yaml
      - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
```

Read it: take the host from `__address__` (dropping any existing port) and the port from the annotation, and join them.

### Copy Kubernetes labels into metric labels

```yaml
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
```

A pod label `app=frontend` becomes the metric label `app="frontend"`. This is the most common `labelmap` use, and worth recognising instantly.

With a prefix:

```yaml
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
        replacement: node_$1
```

### Standard Kubernetes label promotion

```yaml
      - source_labels: [__meta_kubernetes_namespace]
        target_label: namespace
      - source_labels: [__meta_kubernetes_pod_name]
        target_label: pod
      - source_labels: [__meta_kubernetes_pod_container_name]
        target_label: container
      - source_labels: [__meta_kubernetes_node_name]
        target_label: node
      - source_labels: [__meta_kubernetes_service_name]
        target_label: service
```

### Extract the hostname from `instance`

```yaml
      - source_labels: [__address__]
        regex: '([^:]+):\d+'
        replacement: $1
        target_label: host
```

### Combine labels

```yaml
      - source_labels: [namespace, pod]
        separator: /
        target_label: workload
        replacement: $1
```

Note: with `separator: /` the input is `ns/podname`, and the default `regex: (.*)` captures the whole thing into `$1`.

### Blackbox / multi-target exporter, the three-rule pattern

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

1. The probe URL becomes the `target` query parameter.
2. `instance` becomes the probed URL, so metrics are labelled usefully.
3. `__address__` becomes the **exporter**, which is what Prometheus actually connects to.

Note the third rule has no `source_labels`; it just sets a constant.

### Sharding with `hashmod`

```yaml
      - source_labels: [__address__]
        modulus: 4
        target_label: __tmp_shard
        action: hashmod
      - source_labels: [__tmp_shard]
        regex: 0                       # this server's shard index
        action: keep
```

Each of four servers uses a different `regex` value. Targets are distributed deterministically. Note the `__tmp_` prefix, which guarantees the label is not ingested.

### Drop expensive metrics after the scrape

```yaml
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'go_gc_duration_seconds.*|go_memstats_.*'
        action: drop
```

### Keep only specific metrics

```yaml
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'node_(cpu|memory|filesystem|network)_.*|up'
        action: keep
```

### Drop a high-cardinality label

```yaml
    metric_relabel_configs:
      - regex: 'pod_template_hash|controller_revision_hash|id'
        action: labeldrop
```

### Keep only a fixed label set

```yaml
    metric_relabel_configs:
      - regex: '__name__|job|instance|namespace|pod'
        action: labelkeep
```

Careful: `labelkeep` removes everything else, including labels you need. It is a blunt instrument.

### Drop a single high-cardinality series

```yaml
    metric_relabel_configs:
      - source_labels: [__name__, le]
        regex: 'apiserver_request_duration_seconds_bucket;(0\.15|0\.25|0\.35)'
        action: drop
```

### Rename a metric

```yaml
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'old_metric_name'
        replacement: 'new_metric_name'
        target_label: __name__
```

### Normalise case

```yaml
      - source_labels: [__meta_ec2_tag_Environment]
        target_label: env
        action: lowercase
```

### Drop targets whose two labels disagree

```yaml
      - source_labels: [__meta_consul_service]
        target_label: expected_job
      - source_labels: [job]
        target_label: expected_job
        action: keepequal
```

### Remote write filtering

```yaml
remote_write:
  - url: https://remote.example.com/api/v1/write
    write_relabel_configs:
      # Only send recorded aggregates and up
      - source_labels: [__name__]
        regex: 'job:.*|instance:.*|up'
        action: keep
      # Strip the replica label so HA pairs do not duplicate
      - regex: replica
        action: labeldrop
```

### HA alert deduplication

```yaml
alerting:
  alert_relabel_configs:
    - regex: replica
      action: labeldrop
  alertmanagers:
    - static_configs:
        - targets: ["am1:9093", "am2:9093"]
```

This is **the** standard HA pattern. Both Prometheus servers then emit byte-identical alerts, which Alertmanager collapses into one.

## Regex Details

- **RE2**, **fully anchored**. `regex: web` matches only exactly `web`. Use `.*web.*` for a substring.
- No backreferences, no lookahead, no lookbehind.
- Capture groups are referenced as `$1`, `$2`, or `${1}` when followed by other characters.
- `$` in a replacement that is not a capture reference must be escaped as `$$`.
- The default `regex: (.*)` always matches and captures everything into `$1`.

## Order Of Operations Cheat Sheet

```text
relabel_configs order matters:

1. Filter first (keep/drop) so later rules operate on fewer targets
2. Then rewrite the request (__address__, __metrics_path__, __param_*)
3. Then set business labels (namespace, pod, app)
4. Then labelmap / labeldrop cleanup
```

Within `metric_relabel_configs`:

```text
1. drop expensive metrics first (cheapest win)
2. then labeldrop high-cardinality labels
3. then rename or rewrite
```

## Debugging

The single most useful page is `/service-discovery`, which shows **discovered labels before relabeling** and **target labels after**.

```bash
# What was discovered, and what survived
curl -s http://localhost:9090/api/v1/targets | jq -r '
  .data.activeTargets[] |
  "POOL \(.scrapePool)\n  URL   \(.scrapeUrl)\n  LABELS \(.labels)\n  DISCOVERED \(.discoveredLabels)"'

# Targets that were dropped by relabeling
curl -s 'http://localhost:9090/api/v1/targets?state=dropped' \
  | jq -r '.data.droppedTargets[].discoveredLabels'
```

Note that dropped targets only appear if `keep_dropped_targets` allows it (Prometheus keeps a bounded number).

Cardinality impact:

```promql
scrape_samples_scraped                              # what the target exposed
scrape_samples_post_metric_relabeling               # what survived
scrape_samples_scraped - scrape_samples_post_metric_relabeling   # what you dropped
scrape_series_added                                 # churn
```

That subtraction is the direct measurement of how much `metric_relabel_configs` is saving you.

## Traps

| Mistake | Effect |
| --- | --- |
| Using `relabel_configs` to drop a metric | Impossible. It operates on targets |
| Using `metric_relabel_configs` to drop a target | Impossible. It operates on samples |
| Forgetting the regex is anchored | `regex: web` does not match `web-1` |
| `replace` with a non-matching regex | Silent no-op, not a cleared label |
| `replace` to `__metrics_path__` without a `(.+)` guard | An empty annotation blanks the path |
| Expecting `__meta_*` labels on the resulting metrics | They are discarded. Promote them first |
| `labeldrop` on `__name__` | Error |
| `labelmap` on label **values** | It matches label **names** |
| Filtering after expensive rewrites | Works, but wastes effort. Filter first |
| Not using `__tmp_` for intermediates | The intermediate label gets ingested |
| `labelkeep` without listing `__name__` | Removes the metric name, which is an error |

## Memorise

- **`relabel_configs` = targets, before the scrape. `metric_relabel_configs` = samples, after the scrape.** Plus `write_relabel_configs` for remote write and `alert_relabel_configs` for alerts.
- Defaults: **`separator: ;`**, **`regex: (.*)`**, **`replacement: $1`**, **`action: replace`**.
- Actions: **replace, keep, drop, keepequal, dropequal, hashmod, labelmap, labeldrop, labelkeep, lowercase, uppercase.**
- **`labelmap`, `labeldrop`, `labelkeep` match label NAMES.** Everything else matches **values**.
- A `replace` whose regex does not match is a **no-op**.
- Regexes are **RE2, fully anchored**.
- **All `__`-prefixed labels are dropped after `relabel_configs`**, except `__name__`.
- `__address__`, `__scheme__`, `__metrics_path__`, `__param_<name>` control the HTTP request. `instance` defaults to the final `__address__`.
- The **blackbox three-rule pattern**: `__address__` → `__param_target`, `__param_target` → `instance`, `__address__` → the exporter.
- **`labelmap` with `regex: __meta_kubernetes_pod_label_(.+)`** promotes Kubernetes pod labels.
- **`hashmod` plus `keep`** is how you shard targets across servers. Use a `__tmp_` label.
- **`labeldrop` on `replica` in `alert_relabel_configs`** is the HA deduplication pattern.
- Debug with **`/service-discovery`** and `scrape_samples_scraped` minus `scrape_samples_post_metric_relabeling`.
