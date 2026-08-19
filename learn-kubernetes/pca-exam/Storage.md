# Storage: TSDB, Retention, Remote Write

## On-Disk Layout

```text
/var/lib/prometheus/
├── wal/                         write-ahead log for the head block
│   ├── 00000000                 128MB segments
│   ├── 00000001
│   └── checkpoint.00000002/     compacted WAL prefix
├── chunks_head/                 memory-mapped head chunks
│   ├── 000001
│   └── 000002
├── 01HXYZ.../                   an immutable BLOCK (ULID-named)
│   ├── chunks/
│   │   └── 000001               up to 512MB each
│   ├── index                    inverted index: label pairs -> series
│   ├── meta.json                time range, series count, compaction level
│   └── tombstones               deletion markers
├── 01HABC.../                   another block
├── lock                         prevents two Prometheus processes sharing the dir
└── queries.active               currently running queries
```

## The Write Path

```text
scrape ──► WAL (append, fsync'd periodically)
             │
             └──► head block (in memory + chunks_head mmap)
                     │
                     │  every 2 hours
                     ▼
                  compact to an immutable on-disk BLOCK
                     │
                     │  background compaction merges blocks
                     ▼
                  bigger blocks (up to 10% of retention time)
```

| Concept | Detail |
| --- | --- |
| **WAL** | Append-only durability log. Replayed on startup to rebuild the head block. Segments are **128 MB** |
| **Checkpoint** | Periodic WAL compaction that drops series no longer in the head |
| **Head block** | The current, in-memory, writable block. Covers roughly the last **2 hours** |
| **Block** | Immutable, ULID-named directory covering a fixed time range. Default range **2h** |
| **Chunk** | Compressed run of samples for one series, **120 samples maximum**, or closed after the block range |
| **Index** | Inverted index mapping label name/value pairs to series IDs |
| **Compaction** | Merges adjacent blocks into larger ones to reduce index overhead and file count |
| **Tombstone** | Deletion marker. Actual removal happens on the next compaction |

Numbers:

- **Head block / initial block range: 2 hours.**
- **Chunk: 120 samples max**, so at a 15s scrape interval a chunk covers 30 minutes.
- **Compressed sample size: roughly 1 to 2 bytes** thanks to delta-of-delta timestamp encoding and XOR value encoding (the Gorilla algorithm).
- Maximum block duration defaults to **10% of the retention time**.

That 1-2 bytes per sample figure is the basis of every capacity calculation.

## Compression

Prometheus uses the Facebook Gorilla scheme:

- **Timestamps: delta-of-delta encoding.** Regular scrape intervals compress to almost nothing.
- **Values: XOR encoding.** Values that change little compress extremely well.

Consequence: **regular scrape intervals and slowly-changing values compress far better than irregular or noisy ones.** A gauge that jitters randomly costs much more than one that is flat.

## Capacity Planning

```text
disk = retention_seconds × samples_per_second × bytes_per_sample

samples_per_second = active_series / scrape_interval_seconds
bytes_per_sample   ≈ 1.5 (range 1 to 2)
```

Worked example:

```text
1,000,000 active series
15 second scrape interval
15 day retention

samples/sec = 1,000,000 / 15            = 66,667
seconds     = 15 × 86,400               = 1,296,000
samples     = 66,667 × 1,296,000        = 86.4 billion
disk        = 86.4e9 × 1.5 bytes        ≈ 130 GB
```

RAM is dominated by the head block and the index:

```text
RAM ≈ active_series × 1 to 3 KB, plus query working set
```

So a million series is roughly 2-3 GB of head plus whatever queries need. Plan for headroom; a single expensive query can multiply the working set.

Levers to reduce cost, in order of effectiveness:

1. **Reduce cardinality.** Drop labels and metrics you do not use. This dominates everything else.
2. **Lengthen the scrape interval.** Doubling it halves the sample count.
3. **Shorten retention.**
4. **Use recording rules plus remote write** so long-term data is aggregated, not raw.

## Retention

**Retention is configured with command-line flags, not in `prometheus.yml`.** This is a favourite exam question.

```bash
--storage.tsdb.retention.time=15d     # default 15d
--storage.tsdb.retention.size=0       # default 0 = disabled, e.g. 100GB, 500MB
--storage.tsdb.path=/var/lib/prometheus
--storage.tsdb.min-block-duration=2h
--storage.tsdb.max-block-duration=<10% of retention>
--storage.tsdb.no-lockfile
--storage.tsdb.wal-compression         # on by default in recent versions
```

Rules:

- If **both** time and size retention are set, **whichever triggers first** removes data.
- `--storage.tsdb.retention` (without a suffix) is the deprecated older flag.
- Retention operates at **block granularity**. A block is deleted only when its **entire** time range is outside the window, so actual on-disk retention slightly exceeds the configured value.
- Size retention counts blocks, the WAL, and `chunks_head`.

## Deleting Data

Requires `--web.enable-admin-api`.

```bash
# Mark series for deletion (creates tombstones)
curl -X POST -g 'http://localhost:9090/api/v1/admin/tsdb/delete_series?match[]=up{job="old"}'
curl -X POST -g 'http://localhost:9090/api/v1/admin/tsdb/delete_series?match[]={__name__=~"test_.*"}&start=...&end=...'

# Actually reclaim the disk space
curl -X POST http://localhost:9090/api/v1/admin/tsdb/clean_tombstones

# Snapshot for backup (hard links, so it is fast and space-efficient)
curl -X POST http://localhost:9090/api/v1/admin/tsdb/snapshot
# -> data/snapshots/<timestamp>-<hash>/
```

Deletion creates **tombstones**; the space is not reclaimed until `clean_tombstones` or the next compaction.

## Backup And Restore

```bash
# Snapshot (preferred: consistent, uses hard links)
curl -X POST http://localhost:9090/api/v1/admin/tsdb/snapshot
tar czf prom-backup.tar.gz -C /var/lib/prometheus/snapshots <snapshot-dir>

# Restore: stop Prometheus, replace the data directory, start
systemctl stop prometheus
rm -rf /var/lib/prometheus/*
tar xzf prom-backup.tar.gz -C /var/lib/prometheus --strip-components=1
systemctl start prometheus
```

Do **not** copy the data directory of a running Prometheus without a snapshot; you will get a torn WAL.

## promtool TSDB Commands

```bash
# Cardinality analysis: the most useful diagnostic in the toolkit
promtool tsdb analyze /var/lib/prometheus
promtool tsdb analyze /var/lib/prometheus --limit=20
promtool tsdb analyze /var/lib/prometheus <block-ulid>

# List blocks
promtool tsdb list /var/lib/prometheus
promtool tsdb list --human-readable /var/lib/prometheus

# Dump raw samples
promtool tsdb dump /var/lib/prometheus --match='{__name__="up"}'
promtool tsdb dump-openmetrics /var/lib/prometheus

# Backfill from OpenMetrics text
promtool tsdb create-blocks-from openmetrics data.txt /var/lib/prometheus

# Backfill recording rules over historical data
promtool tsdb create-blocks-from rules \
  --start 2026-08-01T00:00:00Z \
  --end 2026-08-10T00:00:00Z \
  --url http://localhost:9090 \
  --output-dir ./backfill \
  rules/slo.yml
```

`promtool tsdb analyze` output tells you:

- Number of series and label pairs
- **Label names with the highest cardinality**
- **Label pairs with the most series**
- **Metric names with the most series**
- Series with the highest churn

That is the fastest way to find out why your Prometheus is using too much memory.

## Remote Write

Streams samples to an external system as they are ingested.

```yaml
remote_write:
  - url: https://remote.example.com/api/v1/write
    name: central
    remote_timeout: 30s

    basic_auth:
      username: prom
      password_file: /etc/prometheus/rw_password

    # Filter what leaves
    write_relabel_configs:
      - source_labels: [__name__]
        regex: 'job:.*|instance:.*|up'
        action: keep
      - regex: replica
        action: labeldrop

    queue_config:
      capacity: 10000              # samples buffered per shard
      max_shards: 200              # max parallel senders
      min_shards: 1
      max_samples_per_send: 2000
      batch_send_deadline: 5s
      min_backoff: 30ms
      max_backoff: 5s
      retry_on_http_429: true

    metadata_config:
      send: true
      send_interval: 1m

    # Send native histograms / created timestamps
    send_native_histograms: false
```

How it works:

- Samples are read from the **WAL** and sent, so remote write survives restarts and brief outages.
- **Sharding is automatic**: Prometheus adds shards when the queue backs up, up to `max_shards`.
- Protocol: **Snappy-compressed Protobuf over HTTP POST**. Remote Write 2.0 adds metadata and native histogram support.
- Data is written **locally as well**, unless you use agent mode.

Monitor it:

```promql
prometheus_remote_storage_samples_in_total
prometheus_remote_storage_samples_pending
prometheus_remote_storage_samples_failed_total
prometheus_remote_storage_samples_dropped_total
prometheus_remote_storage_samples_retried_total
prometheus_remote_storage_shards
prometheus_remote_storage_shards_max
prometheus_remote_storage_shards_desired
prometheus_remote_storage_highest_timestamp_in_seconds
prometheus_remote_storage_queue_highest_sent_timestamp_seconds

# The key health signal: how far behind is remote write?
prometheus_remote_storage_highest_timestamp_in_seconds
  - ignoring(remote_name, url) group_right
prometheus_remote_storage_queue_highest_sent_timestamp_seconds
```

That last expression is **remote write lag in seconds**, and it is the metric to alert on.

## Remote Read

```yaml
remote_read:
  - url: https://remote.example.com/api/v1/read
    read_recent: false
    required_matchers:
      cluster: prod
```

- Queries are fanned out to the remote store and merged with local data.
- `read_recent: false` (default behaviour in practice) avoids re-reading data Prometheus already has locally.
- `required_matchers` restricts which queries are sent remotely.
- **Remote read does not support pushdown of aggregations** in the basic protocol, so large queries transfer a lot of data. It is generally less used than remote write.

## Long-Term Storage Options

| System | Approach |
| --- | --- |
| **Thanos** | Sidecar uploads blocks to object storage; Querier fans out; Compactor downsamples; Store Gateway serves history |
| **Cortex / Mimir** | Horizontally scalable, multi-tenant, receives via remote write |
| **VictoriaMetrics** | Remote write target, PromQL-compatible (MetricsQL) |
| **M3DB** | Uber's distributed store |
| **Grafana Cloud / AMP** | Hosted remote write endpoints |

Note **Thanos provides downsampling**, which plain Prometheus does not. If a question mentions needing lower-resolution long-term data, that is a Thanos/Mimir answer.

## Staleness

Prometheus writes an explicit **stale marker** when a series stops being reported.

Written when:

- A target is removed from service discovery.
- A previously-present series is absent from an otherwise successful scrape.
- A rule stops producing a series.

Effect: the series is **immediately absent** from instant queries, rather than lingering for the 5-minute lookback delta.

Without a stale marker (for example if the whole scrape fails), the last value remains visible for up to **`--query.lookback-delta` (5m)**, then disappears.

Consequences:

- A `scrape_interval` **longer than 5 minutes** produces gaps in graphs. Never do it.
- `up == 0` cannot detect a target that vanished from SD; the series is stale-marked and gone. Use `absent()`.

## Out-Of-Order Samples

Historically Prometheus rejected any sample older than the newest one for a series.

```yaml
storage:
  tsdb:
    out_of_order_time_window: 30m
```

With that set, samples up to 30 minutes late are accepted into a separate out-of-order head. Without it, late samples are rejected:

```promql
prometheus_target_scrapes_sample_out_of_order_total
prometheus_target_scrapes_sample_duplicate_timestamp_total
prometheus_tsdb_out_of_order_samples_appended_total
```

## Health Metrics To Know

```promql
# Head
prometheus_tsdb_head_series
prometheus_tsdb_head_chunks
prometheus_tsdb_head_samples_appended_total
prometheus_tsdb_head_max_time_seconds
prometheus_tsdb_head_min_time_seconds

# Blocks and compaction
prometheus_tsdb_blocks_loaded
prometheus_tsdb_compactions_total
prometheus_tsdb_compactions_failed_total
prometheus_tsdb_compaction_duration_seconds
prometheus_tsdb_lowest_timestamp_seconds

# WAL
prometheus_tsdb_wal_truncations_total
prometheus_tsdb_wal_truncations_failed_total
prometheus_tsdb_wal_corruptions_total
prometheus_tsdb_wal_fsync_duration_seconds

# Reloads and errors
prometheus_tsdb_reloads_total
prometheus_tsdb_reloads_failures_total
prometheus_tsdb_size_retentions_total
prometheus_tsdb_time_retentions_total

# Startup
prometheus_tsdb_data_replay_duration_seconds
```

`prometheus_tsdb_data_replay_duration_seconds` explains slow starts: a large WAL takes minutes to replay, during which `/-/ready` fails while `/-/healthy` succeeds.

## Traps

| Mistake | Consequence |
| --- | --- |
| Setting retention in `prometheus.yml` | Ignored. It is a **flag** |
| Expecting a reload to change retention | Flags need a **restart** |
| Two Prometheus processes on one data directory | Prevented by `lock`, and would corrupt data |
| Copying a live data directory as a backup | Torn WAL. Use the snapshot API |
| Expecting `delete_series` to free space immediately | Tombstones only. Run `clean_tombstones` |
| `scrape_interval` above 5 minutes | Exceeds the lookback delta, producing gaps |
| Assuming Prometheus downsamples | It does not. Use Thanos or Mimir |
| Relying on local storage for durability | Not replicated. Use remote write |
| Ignoring remote write lag | Silent data loss at the remote end |
| Forgetting `write_relabel_configs` | You ship every raw series to the remote store |

## Memorise

- Layout: **`wal/`, `chunks_head/`, block directories (ULID) with `chunks/`, `index`, `meta.json`, `tombstones`, plus `lock` and `queries.active`**.
- **Head block / block range: 2 hours.** WAL segments: **128 MB**. Chunk: **120 samples max**. Block chunk files: up to **512 MB**.
- **Roughly 1-2 bytes per compressed sample.** Gorilla: delta-of-delta timestamps, XOR values.
- `disk = retention_seconds × (series / scrape_interval) × ~1.5 bytes`.
- **RAM ≈ 1-3 KB per active series.**
- **Retention is a command-line flag.** `--storage.tsdb.retention.time` default **15d**, `--storage.tsdb.retention.size` default **0** (off). Whichever triggers first wins. Retention is applied at **block granularity**.
- Admin endpoints need **`--web.enable-admin-api`**: `delete_series`, `clean_tombstones`, `snapshot`.
- **Deletion creates tombstones**; space returns on `clean_tombstones` or compaction.
- Back up with the **snapshot API**, which uses hard links.
- **`promtool tsdb analyze`** is the cardinality diagnostic. `promtool tsdb list`, `dump`, `create-blocks-from rules|openmetrics`.
- **Remote write reads from the WAL**, shards automatically, and sends **Snappy-compressed Protobuf over HTTP**.
- **Remote write lag** = `highest_timestamp_in_seconds - queue_highest_sent_timestamp_seconds`. Alert on it.
- Use **`write_relabel_configs`** to send only aggregates and to drop the `replica` label.
- **Prometheus does not downsample.** Thanos and Mimir do.
- **Stale markers** make a vanished series immediately absent. Otherwise the lookback delta is **5m**.
- **Never set `scrape_interval` above 5 minutes.**
- Out-of-order ingestion needs **`out_of_order_time_window`**.
