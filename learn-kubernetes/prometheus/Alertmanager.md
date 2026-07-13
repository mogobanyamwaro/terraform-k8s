# Alertmanager Reference

## The Pipeline

```text
POST /api/v2/alerts  (from every Prometheus)
   │
   ▼
┌──────────────┐
│ DEDUPLICATION│  identical alerts from HA Prometheus pairs collapse into one
└──────┬───────┘
       ▼
┌──────────────┐
│  INHIBITION  │  suppressed by a more severe alert (static config)
└──────┬───────┘
       ▼
┌──────────────┐
│   SILENCING  │  suppressed by a human-created silence (runtime)
└──────┬───────┘
       ▼
┌──────────────┐
│    ROUTING   │  walk the tree, first matching sibling wins, then descend
└──────┬───────┘
       ▼
┌──────────────┐
│   GROUPING   │  bucket by group_by labels
└──────┬───────┘
       ▼
┌──────────────────────────────────────────┐
│ TIMERS: group_wait / group_interval /    │
│         repeat_interval / mute intervals │
└──────┬───────────────────────────────────┘
       ▼
┌──────────────┐
│   NOTIFY     │  render templates, call the integration
└──────────────┘
```

Deduplication, inhibition, and silencing all happen **before** notification. None of them affect Prometheus.

## The Three Timers

The single most examined part of Alertmanager.

| Timer | Default | Applies to | Meaning |
| --- | ---: | --- | --- |
| `group_wait` | **`30s`** | A **brand-new** group | Wait this long after the first alert arrives, so related alerts join the same notification |
| `group_interval` | **`5m`** | An **existing** group whose contents **changed** | Minimum gap before sending an updated notification |
| `repeat_interval` | **`4h`** | An **existing, unchanged** group | Re-send as a reminder |

```text
t=0        first alert of a NEW group arrives
t=30s      group_wait elapses  ─────────────► NOTIFY #1
t=45s      a second alert joins the group
t=5m30s    group_interval boundary ─────────► NOTIFY #2 (both alerts)
           ... nothing changes for hours ...
t=4h30s    repeat_interval ─────────────────► NOTIFY #3 (reminder, same content)
```

Rules:

- `group_wait` applies **only to new groups**.
- A new alert joining an existing group waits for the next **`group_interval`**, not `group_wait`. This surprises everyone.
- **`repeat_interval` must be greater than `group_interval`**, otherwise Alertmanager warns.
- Typical tuning: `group_wait: 10s` for critical, `30s`-`5m` for warnings.

## Routing

```yaml
route:
  receiver: default            # REQUIRED on the root; the root matches EVERYTHING
  group_by: [alertname, cluster, service]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  routes:
    - receiver: dev-null
      matchers:
        - severity = "none"

    - receiver: pager
      matchers:
        - severity = "critical"
      group_wait: 10s
      repeat_interval: 1h
      routes:                          # children are only reached via the parent
        - receiver: pager-database
          matchers:
            - team = "database"

    - receiver: tickets
      matchers:
        - severity =~ "warning|info"
      group_by: [alertname]

    - receiver: audit
      matchers:
        - alertname =~ ".+"
      continue: true                   # allows evaluation to continue
```

Matching algorithm:

1. Start at the root, which always matches.
2. Walk children **in order**. The **first** child whose matchers all match is selected.
3. Recurse into that child's children the same way.
4. If no child matches, use the current node's `receiver`.
5. `continue: false` (default) stops sibling evaluation after a match. `continue: true` allows later siblings to match too, so an alert can reach **multiple** receivers.

Inheritance: children inherit **`receiver`, `group_by`, `group_wait`, `group_interval`, `repeat_interval`, `mute_time_intervals`, `active_time_intervals`** from the parent. They do **not** inherit `matchers`.

## Matchers

```yaml
      matchers:
        - severity = "critical"
        - team != "database"
        - alertname =~ "High.*"
        - env !~ "dev|staging"
```

| Operator | Meaning |
| --- | --- |
| `=` | Equal |
| `!=` | Not equal |
| `=~` | Regex match, **fully anchored** |
| `!~` | Regex not match, fully anchored |

Deprecated but still valid:

```yaml
      match:
        severity: critical
      match_re:
        alertname: High.*
```

**A missing label is treated as the empty string.** So `severity != "critical"` matches an alert with **no** `severity` label at all. This differs from what most people assume and is examined.

## Grouping

```yaml
  group_by: [alertname, cluster]
```

| Value | Effect |
| --- | --- |
| `[label, ...]` | One group per distinct combination of those label values |
| `['...']` | **Disable grouping.** One notification per alert |
| `[]` | **One group for everything** in that route |

50 instances of `InstanceDown` in cluster `prod` with `group_by: [alertname, cluster]` produce **one** notification listing 50 alerts.

Tuning guidance:

- Group by what an on-call engineer would treat as **one incident**.
- `alertname` plus a scope label (`cluster`, `service`, `namespace`) is the usual choice.
- Grouping by `instance` defeats the purpose.

## Inhibition

```yaml
inhibit_rules:
  # A critical alert suppresses the matching warning
  - source_matchers:
      - severity = "critical"
    target_matchers:
      - severity = "warning"
    equal: [alertname, cluster, service]

  # A node being down suppresses everything about that node
  - source_matchers:
      - alertname = "InstanceDown"
    target_matchers:
      - alertname =~ ".+"
    equal: [instance]

  # A cluster outage suppresses instance-level noise
  - source_matchers:
      - alertname = "ClusterUnreachable"
    target_matchers:
      - alertname =~ ".+"
    equal: [cluster]
```

Rules:

- The **source** alert must be **firing**.
- The `equal` labels must be **present and equal on both** alerts. Missing on **both** counts as equal.
- **Self-inhibition is prevented**: an alert matching both source and target matchers does not inhibit itself.
- **Omitting `equal` inhibits globally**, which is almost always a bug and a classic exam distractor.
- Inhibited alerts show `status.state: "suppressed"` with `inhibitedBy` populated.

## Silences

Created at **runtime by a human**, not in config.

```bash
amtool silence add alertname=InstanceDown --duration=2h --comment="node replacement" --author=me
amtool silence add 'alertname=~"High.*"' instance=node1 --duration=30m --comment="known"
amtool silence query
amtool silence query --expired
amtool silence expire <id>
for s in $(amtool silence query -q); do amtool silence expire "$s"; done
```

```bash
curl -s -XPOST http://localhost:9093/api/v2/silences \
  -H 'Content-Type: application/json' -d '{
  "matchers": [
    {"name":"alertname","value":"InstanceDown","isRegex":false,"isEqual":true},
    {"name":"instance","value":"node.*","isRegex":true,"isEqual":true}
  ],
  "startsAt":"2026-08-18T22:00:00Z",
  "endsAt":"2026-08-19T02:00:00Z",
  "createdBy":"douglas",
  "comment":"planned maintenance"
}'
```

Facts:

- States: **`pending`** (start in the future), **`active`**, **`expired`**.
- Silences are **expired**, never deleted, which preserves the audit trail.
- **All** matchers must match.
- Stored in `--storage.path` and **gossiped across the cluster**, so they survive restarts and apply on every node.
- Silenced alerts show `status.state: "suppressed"` with `silencedBy` populated.

## Time Intervals

```yaml
time_intervals:
  - name: out_of_hours
    time_intervals:
      - weekdays: ['saturday', 'sunday']
      - times:
          - start_time: '00:00'
            end_time: '09:00'
        location: 'Europe/London'
      - months: ['december']
        days_of_month: ['24:26']

route:
  routes:
    - receiver: tickets
      matchers: [severity = "warning"]
      mute_time_intervals: ['out_of_hours']      # do NOT notify during

    - receiver: pager
      matchers: [severity = "critical"]
      active_time_intervals: ['out_of_hours']    # ONLY notify during
```

Fields: `times`, `weekdays`, `days_of_month`, `months`, `years`, `location`.

**Critical debugging fact: a mute time interval does NOT mark the alert as `suppressed`.** The alert looks active in the API and nothing is sent. Only inspecting the matched route reveals it. That makes it the hardest suppression to diagnose.

## Receivers

```yaml
receivers:
  - name: dev-null                        # empty receiver = drop the alerts

  - name: multi
    slack_configs:
      - api_url: https://hooks.slack.com/...
        channel: '#alerts'
        title: '{{ template "custom.title" . }}'
        text: '{{ template "custom.text" . }}'
        send_resolved: true
    email_configs:
      - to: oncall@example.com
        headers:
          Subject: '{{ template "email.subject" . }}'
        html: '{{ template "email.html" . }}'
        send_resolved: false
    pagerduty_configs:
      - routing_key: abc123
        severity: '{{ .CommonLabels.severity }}'
        description: '{{ .CommonAnnotations.summary }}'
    webhook_configs:
      - url: http://audit:8080/alerts
        max_alerts: 0
        send_resolved: true
    opsgenie_configs: [...]
    telegram_configs: [...]
    msteams_configs: [...]
    discord_configs: [...]
    sns_configs: [...]
    victorops_configs: [...]
    pushover_configs: [...]
    wechat_configs: [...]
    webex_configs: [...]
    jira_configs: [...]
    rocketchat_configs: [...]
```

A receiver may have **multiple integrations** and **multiple entries of the same integration**; all of them fire.

`send_resolved` defaults:

| Integration | Default |
| --- | --- |
| `webhook_configs` | **`true`** |
| `pagerduty_configs` | **`true`** |
| `opsgenie_configs` | `true` |
| `slack_configs` | **`false`** |
| `email_configs` | **`false`** |

Remember at minimum: **webhook and PagerDuty true, email and Slack false.**

## Templating

Group-level data:

| Field | Meaning |
| --- | --- |
| `.Status` | `firing` or `resolved` |
| `.Receiver` | Receiver name |
| `.Alerts` | All alerts in the group |
| `.Alerts.Firing` | Firing subset |
| `.Alerts.Resolved` | Resolved subset |
| `.GroupLabels` | The **`group_by`** labels |
| `.CommonLabels` | Labels **identical across all** alerts in the group |
| `.CommonAnnotations` | Annotations identical across all alerts |
| `.ExternalURL` | Alertmanager's external URL |

Per-alert data inside `range .Alerts`:

| Field | Meaning |
| --- | --- |
| `.Status` | `firing` / `resolved` |
| `.Labels` | Alert labels |
| `.Annotations` | Alert annotations |
| `.StartsAt` / `.EndsAt` | Timestamps |
| `.GeneratorURL` | Link to the Prometheus expression |
| `.Fingerprint` | Alert fingerprint |

```
{{ define "custom.title" }}[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] {{ .GroupLabels.alertname }}{{ end }}

{{ define "custom.text" }}
{{ range .Alerts.Firing }}
*{{ .Labels.severity | toUpper }}* {{ .Annotations.summary }}
  instance : {{ .Labels.instance }}
  started  : {{ .StartsAt.Format "2006-01-02 15:04:05 MST" }}
  {{ if .Annotations.runbook_url }}runbook  : {{ .Annotations.runbook_url }}{{ end }}
  graph    : {{ .GeneratorURL }}
{{ end }}
{{ end }}
```

```yaml
templates:
  - /etc/alertmanager/templates/*.tmpl
```

**Alertmanager never receives the metric value.** If you want it in a notification, render it into an **annotation** in the Prometheus rule with `{{ $value }}`. This is a guaranteed exam question.

Functions available: `title`, `toUpper`, `toLower`, `join`, `match`, `reReplaceAll`, `safeHtml`, `stringSlice`, `date`, `tz`, `since`, `humanizeDuration`, plus Go template builtins.

Test with:

```bash
amtool template render --template.glob='/etc/alertmanager/templates/*.tmpl' \
  --template.text='{{ template "custom.text" . }}' --template.data=alerts.json
```

## Webhook Payload

```json
{
  "version": "4",
  "groupKey": "{}:{alertname=\"InstanceDown\", cluster=\"prod\"}",
  "truncatedAlerts": 0,
  "status": "firing",
  "receiver": "pager",
  "groupLabels": {"alertname": "InstanceDown", "cluster": "prod"},
  "commonLabels": {"alertname": "InstanceDown", "severity": "critical"},
  "commonAnnotations": {"summary": "..."},
  "externalURL": "http://alertmanager:9093",
  "alerts": [
    {
      "status": "firing",
      "labels": {"alertname": "InstanceDown", "instance": "node1"},
      "annotations": {"summary": "node1 is down"},
      "startsAt": "2026-08-18T10:00:00Z",
      "endsAt": "0001-01-01T00:00:00Z",
      "generatorURL": "http://prometheus:9090/graph?g0.expr=up+%3D%3D+0",
      "fingerprint": "a1b2c3d4"
    }
  ]
}
```

- `version` is **`"4"`**.
- A **firing** alert has `endsAt` as the **zero time** `0001-01-01T00:00:00Z`.
- `truncatedAlerts` counts alerts omitted because the group exceeded `max_alerts`.

## High Availability

```bash
alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/alertmanager \
  --cluster.listen-address=0.0.0.0:9094 \
  --cluster.peer=am1:9094 \
  --cluster.peer=am2:9094 \
  --cluster.peer-timeout=15s \
  --web.listen-address=:9093
```

How it works:

- **Gossip** (HashiCorp memberlist) on port **9094**.
- Every Prometheus sends **every alert to every Alertmanager**. Do **not** put a load balancer in front for alert delivery.
- The cluster gossips the **notification log (nflog)** and **silences**.
- Deduplication is positional: each node waits `peer_timeout × its index` in the sorted peer list, then checks the nflog before sending. If another node already sent it, this one skips.
- Silences created anywhere propagate everywhere.

```promql
alertmanager_cluster_members
alertmanager_cluster_health_score          # 0 = healthy
alertmanager_cluster_failed_peers
alertmanager_cluster_peers_joined_total
alertmanager_cluster_reconnections_total

# Config divergence across the cluster: > 1 means the members disagree
count by (job) (count by (job, hash) (alertmanager_config_hash))
```

HA failure modes:

| Symptom | Cause |
| --- | --- |
| Duplicate notifications, identical content | **Not clustered.** No shared nflog |
| Duplicate notifications, different content | **Divergent configs.** Check `alertmanager_config_hash` |
| Duplicate **alerts** with different labels | Prometheus HA pair not dropping the `replica` label |
| Silences apply on one node only | Gossip broken. Check `alertmanager_cluster_members` |

## Metrics

```promql
alertmanager_alerts                              # by state: active, suppressed
alertmanager_alerts_received_total               # by status: firing, resolved
alertmanager_alerts_invalid_total
alertmanager_notifications_total                 # by integration
alertmanager_notifications_failed_total          # by integration  <- ALERT ON THIS
alertmanager_notification_latency_seconds
alertmanager_silences                            # by state: active, expired, pending
alertmanager_config_last_reload_successful
alertmanager_config_hash
alertmanager_nflog_gc_duration_seconds
alertmanager_dispatcher_aggregation_groups
alertmanager_dispatcher_alert_processing_duration_seconds
```

Essential alerts on Alertmanager itself:

```yaml
      - alert: AlertmanagerNotificationsFailing
        expr: rate(alertmanager_notifications_failed_total[5m]) > 0
        for: 5m

      - alert: AlertmanagerConfigReloadFailed
        expr: alertmanager_config_last_reload_successful == 0
        for: 5m

      - alert: AlertmanagerClusterUnhealthy
        expr: alertmanager_cluster_health_score > 0
        for: 10m

      - alert: AlertmanagerConfigInconsistent
        expr: count by (job) (count by (job, hash) (alertmanager_config_hash)) > 1
        for: 10m

      - alert: AlertmanagerReceivingInvalidAlerts
        expr: rate(alertmanager_alerts_invalid_total[5m]) > 0
        for: 5m
```

`alertmanager_notifications_failed_total` is the most important. Delivery failure is otherwise completely silent.

## API And amtool

```bash
# API v2
curl -s http://localhost:9093/api/v2/status        | jq '{uptime, cluster, versionInfo}'
curl -s http://localhost:9093/api/v2/alerts        | jq .
curl -s http://localhost:9093/api/v2/alerts/groups | jq .
curl -s http://localhost:9093/api/v2/silences      | jq .
curl -s http://localhost:9093/api/v2/receivers     | jq .
curl -s http://localhost:9093/-/healthy
curl -s http://localhost:9093/-/ready
curl -X POST http://localhost:9093/-/reload

# amtool
amtool --alertmanager.url=http://localhost:9093 alert query
amtool alert query alertname=InstanceDown severity=critical
amtool alert add alertname=Test severity=warning --annotation=summary="test"
amtool silence add / query / expire / import / export
amtool config show
amtool config routes show
amtool config routes test severity=critical team=database
amtool config routes test --verify.receivers=pager severity=critical
amtool check-config /etc/alertmanager/alertmanager.yml
amtool template render ...
amtool cluster show
```

`amtool config routes show` and **`amtool config routes test`** are the two commands to remember. They answer "where would this alert go" without firing anything.

Configure `~/.config/amtool/config.yml` to avoid repeating the URL:

```yaml
alertmanager.url: http://localhost:9093
author: douglas
comment_required: true
output: extended
```

## Traps

| Mistake | Consequence |
| --- | --- |
| Load-balancing Alertmanagers | Breaks fan-out-then-deduplicate |
| Not clustering | Duplicate notifications |
| Divergent configs across the cluster | Duplicates with different content, different routing |
| Root route with `matchers` | Invalid. The root matches everything |
| Broad route placed first | Swallows alerts before specific routes are reached |
| Forgetting `continue: true` | An alert reaches only one receiver |
| `repeat_interval` ≤ `group_interval` | Warned about; repeats race change notifications |
| `group_by: [instance]` | No batching; a notification per instance |
| Inhibition without `equal` | Global suppression |
| Expecting a mute interval to mark the alert `suppressed` | It does not. Only the route reveals it |
| Expecting `$value` in a template | Alertmanager never receives it |
| Assuming a silence is deleted | It is **expired** |
| Assuming `severity != "x"` skips label-less alerts | A missing label matches |

## Memorise

- **Prometheus decides when. Alertmanager decides who and how.**
- Pipeline order: **dedup → inhibit → silence → route → group → timers → notify.**
- **`group_wait` 30s / `group_interval` 5m / `repeat_interval` 4h.** New group, changed group, unchanged group.
- A new alert joining an existing group waits for **`group_interval`**.
- **First matching sibling route wins**, then descend. `continue: true` for multiple receivers.
- Children inherit **receiver, grouping, timers**, not **matchers**. The root matches everything.
- **`group_by: ['...']` disables grouping; `group_by: []` merges everything.**
- Use `matchers:` with `=`, `!=`, `=~`, `!~`. **Fully anchored.** **A missing label is the empty string.**
- **Inhibition needs `equal`.** Source must be firing. **Self-inhibition is prevented.**
- Silences: **runtime, human, `pending`/`active`/`expired`, expired not deleted, persisted and gossiped, all matchers must match.**
- **A mute time interval leaves no `suppressed` marker.**
- **Empty receiver = drop.**
- `send_resolved`: **webhook and PagerDuty true; email and Slack false.**
- **`.GroupLabels` = `group_by` labels. `.CommonLabels` = labels identical across the group.**
- **Alertmanager never sees the metric value.** Use `{{ $value }}` in a Prometheus annotation.
- Webhook payload: `version` **`"4"`**, firing alerts have `endsAt` as the **zero time**, `truncatedAlerts` counts omissions.
- **Ports 9093 (API) and 9094 (gossip).** Gossip carries **nflog and silences**.
- `alertmanager_cluster_health_score` of **0** is healthy. `resolve_timeout` default **5m**.
- **Alert on `alertmanager_notifications_failed_total`.**
- **`amtool config routes test`** and **`amtool check-config`**.
