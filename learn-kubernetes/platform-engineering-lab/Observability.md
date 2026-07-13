# Observability (Exam)

## Prometheus Operator

`ServiceMonitor` + `PrometheusRule`. **Labels must match** Prometheus CR selectors (`release: kube-prometheus-stack` is common).

Port name on Service = `endpoints.port`.

## Grafana

Datasource already there. Task may ask a ConfigMap dashboard or a screenshot-less “create a dashboard JSON” ConfigMap. Don’t waste time pixel-clicking unless required.

## OTel / Jaeger

Env `OTEL_EXPORTER_OTLP_ENDPOINT` + Collector ConfigMap. Confirm Collector pod is Ready.

## Incidents

`describe` / events / GitOps status. Fix the **source of truth**.
