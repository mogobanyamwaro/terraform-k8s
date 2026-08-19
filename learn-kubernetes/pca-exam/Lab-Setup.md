# PCA Lab Setup

You need a working stack before anything else in this folder is useful. Three options below. Pick one.

Everything in this folder assumes:

- Prometheus at `http://localhost:9090`
- Alertmanager at `http://localhost:9093`
- Pushgateway at `http://localhost:9091`
- node_exporter at `http://localhost:9100/metrics`
- Grafana at `http://localhost:3000`

---

## Option A: Docker Compose (fastest, recommended)

Create a working directory:

```bash
mkdir -p ~/pca-lab/{prometheus,alertmanager,rules}
cd ~/pca-lab
```

`docker-compose.yml`:

```yaml
services:
  prometheus:
    image: prom/prometheus:v3.5.0
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./rules:/etc/prometheus/rules:ro
      - prom-data:/prometheus
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --storage.tsdb.path=/prometheus
      - --storage.tsdb.retention.time=15d
      - --web.enable-lifecycle
      - --web.enable-admin-api

  alertmanager:
    image: prom/alertmanager:v0.28.1
    container_name: alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
    command:
      - --config.file=/etc/alertmanager/alertmanager.yml

  node-exporter:
    image: prom/node-exporter:v1.9.1
    container_name: node-exporter
    ports:
      - "9100:9100"
    pid: host
    volumes:
      - /:/host:ro,rslave
    command:
      - --path.rootfs=/host

  pushgateway:
    image: prom/pushgateway:v1.11.1
    container_name: pushgateway
    ports:
      - "9091:9091"

  blackbox-exporter:
    image: prom/blackbox-exporter:v0.27.0
    container_name: blackbox-exporter
    ports:
      - "9115:9115"

  grafana:
    image: grafana/grafana:11.6.0
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_AUTH_ANONYMOUS_ENABLED=true
      - GF_AUTH_ANONYMOUS_ORG_ROLE=Admin
    volumes:
      - grafana-data:/var/lib/grafana

  # A demo app that exposes realistic metrics for PromQL practice
  demo-a:
    image: julius/prometheus-demo-service:latest
    container_name: demo-a
    ports:
      - "8080:8080"

  demo-b:
    image: julius/prometheus-demo-service:latest
    container_name: demo-b
    ports:
      - "8081:8080"

  demo-c:
    image: julius/prometheus-demo-service:latest
    container_name: demo-c
    ports:
      - "8082:8080"

volumes:
  prom-data:
  grafana-data:
```

`prometheus/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s
  external_labels:
    cluster: pca-lab
    replica: A

rule_files:
  - /etc/prometheus/rules/*.yml

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: node
    static_configs:
      - targets: ["node-exporter:9100"]

  - job_name: demo
    scrape_interval: 5s
    static_configs:
      - targets:
          - "demo-a:8080"
          - "demo-b:8080"
          - "demo-c:8080"
        labels:
          env: production

  - job_name: pushgateway
    honor_labels: true
    static_configs:
      - targets: ["pushgateway:9091"]

  - job_name: blackbox
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - https://prometheus.io
          - https://kubernetes.io
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115
```

`alertmanager/alertmanager.yml`:

```yaml
global:
  resolve_timeout: 5m

route:
  receiver: default
  group_by: [alertname, cluster]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  routes:
    - receiver: critical
      matchers:
        - severity = "critical"
      group_wait: 10s
      continue: false

    - receiver: dev-null
      matchers:
        - severity = "info"

inhibit_rules:
  - source_matchers:
      - severity = "critical"
    target_matchers:
      - severity = "warning"
    equal: [alertname, instance]

receivers:
  - name: default
    webhook_configs:
      - url: http://127.0.0.1:5001/
        send_resolved: true

  - name: critical
    webhook_configs:
      - url: http://127.0.0.1:5001/critical
        send_resolved: true

  - name: dev-null
```

`rules/lab.yml`:

```yaml
groups:
  - name: recording
    interval: 15s
    rules:
      - record: job:http_requests:rate5m
        expr: sum by (job) (rate(demo_api_request_duration_seconds_count[5m]))

      - record: instance:node_cpu_utilisation:rate5m
        expr: 1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m]))

  - name: alerts
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "{{ $labels.instance }} of job {{ $labels.job }} is down"
          description: "{{ $labels.instance }} has been unreachable for more than 1 minute."

      - alert: HighErrorRate
        expr: |
          sum by (job) (rate(demo_api_request_duration_seconds_count{status=~"5.."}[5m]))
            /
          sum by (job) (rate(demo_api_request_duration_seconds_count[5m]))
            > 0.05
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Error rate on {{ $labels.job }} is {{ $value | humanizePercentage }}"
```

Start it:

```bash
docker compose up -d
docker compose ps
```

Open:

- Prometheus targets: <http://localhost:9090/targets>
- Prometheus graph: <http://localhost:9090/graph>
- Prometheus rules: <http://localhost:9090/rules>
- Prometheus alerts: <http://localhost:9090/alerts>
- Prometheus config: <http://localhost:9090/config>
- Prometheus TSDB stats: <http://localhost:9090/tsdb-status>
- Alertmanager: <http://localhost:9093>
- Grafana: <http://localhost:3000>

---

## Option B: Binaries on Linux (closest to the exam material)

```bash
mkdir -p ~/pca-bin && cd ~/pca-bin

# Prometheus
PROM_VER=3.5.0
curl -sLO https://github.com/prometheus/prometheus/releases/download/v${PROM_VER}/prometheus-${PROM_VER}.linux-amd64.tar.gz
tar xzf prometheus-${PROM_VER}.linux-amd64.tar.gz

# node_exporter
NE_VER=1.9.1
curl -sLO https://github.com/prometheus/node_exporter/releases/download/v${NE_VER}/node_exporter-${NE_VER}.linux-amd64.tar.gz
tar xzf node_exporter-${NE_VER}.linux-amd64.tar.gz

# Alertmanager
AM_VER=0.28.1
curl -sLO https://github.com/prometheus/alertmanager/releases/download/v${AM_VER}/alertmanager-${AM_VER}.linux-amd64.tar.gz
tar xzf alertmanager-${AM_VER}.linux-amd64.tar.gz

# Pushgateway
PG_VER=1.11.1
curl -sLO https://github.com/prometheus/pushgateway/releases/download/v${PG_VER}/pushgateway-${PG_VER}.linux-amd64.tar.gz
tar xzf pushgateway-${PG_VER}.linux-amd64.tar.gz
```

Run each in its own terminal:

```bash
./node_exporter-1.9.1.linux-amd64/node_exporter
./alertmanager-0.28.1.linux-amd64/alertmanager --config.file=alertmanager.yml
./pushgateway-1.11.1.linux-amd64/pushgateway
./prometheus-3.5.0.linux-amd64/prometheus --config.file=prometheus.yml --web.enable-lifecycle
```

Add to PATH so `promtool` is available everywhere:

```bash
export PATH="$HOME/pca-bin/prometheus-3.5.0.linux-amd64:$PATH"
promtool --version
```

---

## Option C: Kubernetes with kube-prometheus-stack

Useful for the cloud native flavour questions. See `Kubernetes.md` for the detail.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

helm install kps prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.retention=7d \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

kubectl -n monitoring get pods
kubectl -n monitoring port-forward svc/kps-kube-prometheus-stack-prometheus 9090:9090
kubectl -n monitoring port-forward svc/kps-kube-prometheus-stack-alertmanager 9093:9093
kubectl -n monitoring port-forward svc/kps-grafana 3000:80
```

Grafana admin password:

```bash
kubectl -n monitoring get secret kps-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo
```

---

## Essential Commands You Will Reuse

Validate config and rules:

```bash
promtool check config prometheus.yml
promtool check rules rules/lab.yml
promtool check metrics < metrics.txt
promtool check service-discovery prometheus.yml demo
```

Reload without restart:

```bash
# Needs --web.enable-lifecycle
curl -X POST http://localhost:9090/-/reload

# Or
kill -HUP $(pidof prometheus)

# Alertmanager
curl -X POST http://localhost:9093/-/reload
```

Query from the CLI:

```bash
promtool query instant http://localhost:9090 'up'
promtool query range http://localhost:9090 'rate(node_cpu_seconds_total[5m])' --start=$(date -d '-10 min' +%s) --end=$(date +%s) --step=1m
promtool query labels http://localhost:9090 job
promtool query series http://localhost:9090 --match='up'
```

Raw HTTP API:

```bash
curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=up' | jq
curl -sG http://localhost:9090/api/v1/query_range \
  --data-urlencode 'query=rate(node_cpu_seconds_total[5m])' \
  --data-urlencode "start=$(date -d '-1 hour' +%s)" \
  --data-urlencode "end=$(date +%s)" \
  --data-urlencode 'step=60' | jq '.data.result | length'

curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].labels'
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[].name'
curl -s http://localhost:9090/api/v1/alerts | jq
curl -s http://localhost:9090/api/v1/status/tsdb | jq
curl -s http://localhost:9090/api/v1/label/job/values | jq
```

Push a batch job metric:

```bash
echo "batch_job_last_success_timestamp_seconds $(date +%s)" \
  | curl --data-binary @- http://localhost:9091/metrics/job/nightly_backup/instance/db01

# Inspect
curl -s http://localhost:9091/metrics | grep batch_job

# Delete the group
curl -X DELETE http://localhost:9091/metrics/job/nightly_backup/instance/db01
```

Read a raw exposition endpoint:

```bash
curl -s http://localhost:9100/metrics | head -40
curl -s -H 'Accept: application/openmetrics-text; version=1.0.0' http://localhost:9100/metrics | tail -5
```

Silence an alert from the CLI:

```bash
amtool --alertmanager.url=http://localhost:9093 alert
amtool --alertmanager.url=http://localhost:9093 silence add alertname=InstanceDown --duration=1h --comment="maintenance"
amtool --alertmanager.url=http://localhost:9093 silence query
amtool --alertmanager.url=http://localhost:9093 config routes test severity=critical
```

## Break Things On Purpose

The best PCA practice is causing failures and watching the metrics.

```bash
# Kill a target and watch up == 0, then the InstanceDown alert
docker stop demo-b

# Burn CPU and watch node_cpu_seconds_total
docker exec -it node-exporter sh -c 'yes > /dev/null' &

# Restart a target and watch a counter reset
docker restart demo-a
```

Then query:

```promql
up
changes(up[1h])
resets(demo_api_request_duration_seconds_count[1h])
ALERTS
```

## Teardown

```bash
cd ~/pca-lab && docker compose down -v
```
