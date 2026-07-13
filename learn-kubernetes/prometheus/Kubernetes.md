# Monitoring Kubernetes With Prometheus

Prometheus and Kubernetes grew up together. PCA is a CNCF-adjacent exam, so cloud-native context questions appear even though Kubernetes is not a listed domain.

## What Exposes What

```text
┌──────────────────────────────────────────────────────────────────────────┐
│ CONTROL PLANE                                                            │
│   kube-apiserver      :6443  /metrics   apiserver_request_total, ...      │
│   kube-controller-manager :10257 /metrics                                │
│   kube-scheduler      :10259 /metrics   scheduler_*                       │
│   etcd                :2379  /metrics   etcd_*                           │
│   coredns             :9153  /metrics   coredns_*                         │
├──────────────────────────────────────────────────────────────────────────┤
│ EVERY NODE                                                               │
│   kubelet             :10250 /metrics          kubelet_*                  │
│                              /metrics/cadvisor container_*  (cAdvisor)    │
│                              /metrics/probes   prober_*                   │
│                              /metrics/resource                            │
│   node_exporter       :9100  /metrics   node_*     (DaemonSet)            │
├──────────────────────────────────────────────────────────────────────────┤
│ CLUSTER-WIDE ADD-ON                                                      │
│   kube-state-metrics  :8080  /metrics   kube_*      (Deployment)          │
├──────────────────────────────────────────────────────────────────────────┤
│ YOUR WORKLOADS                                                           │
│   instrumented pods   :<port> /metrics                                    │
└──────────────────────────────────────────────────────────────────────────┘
```

**cAdvisor is not a separate deployment.** It is built into the kubelet and served at `/metrics/cadvisor`. That is examined.

## The Confused Trio

| | kube-state-metrics | cAdvisor | node_exporter |
| --- | --- | --- | --- |
| Data source | **Kubernetes API server** | **cgroups via the kubelet** | **Host `/proc` and `/sys`** |
| Question answered | "What does the cluster **declare**?" | "What are containers **using**?" | "What is the **machine** doing?" |
| Metric prefix | `kube_*` | `container_*` | `node_*` |
| Deployed as | Deployment (one replica) | Built into the kubelet | DaemonSet |
| Examples | `kube_deployment_spec_replicas`, `kube_pod_status_phase`, `kube_node_status_condition`, `kube_pod_container_status_restarts_total` | `container_cpu_usage_seconds_total`, `container_memory_working_set_bytes` | `node_cpu_seconds_total`, `node_filesystem_avail_bytes` |
| Nature | Object **state** | Resource **usage** | Host resources |

kube-state-metrics reports **no resource usage**. cAdvisor knows **nothing** about Deployments, Services, or Ingresses. Questions test exactly that boundary.

## Service Discovery Roles

| Role | Discovers | One target per | Use for |
| --- | --- | --- | --- |
| `node` | Nodes | Node, at the kubelet address | Kubelet, cAdvisor, node-level scraping |
| `pod` | Pods | Declared container port | Annotation-driven pod scraping |
| `endpoints` | Service endpoints | Backing pod address and port | **Scraping the pods behind a service** |
| `endpointslice` | EndpointSlices | Endpoint address and port | Modern replacement for `endpoints` |
| `service` | Services | Service port | **Blackbox probing only** |
| `ingress` | Ingresses | Ingress path | **Blackbox probing only** |

`service` gives one target per service, which load-balances across pods, so consecutive scrapes hit different pods and the counters look like they reset. That is why it is only for probing. Use **`endpoints`** or **`endpointslice`** to scrape real metrics.

Targets from `role: endpoints` carry **both** `__meta_kubernetes_service_*` and `__meta_kubernetes_pod_*` labels, which is why it is the most useful role.

## Scrape Configs You Should Recognise

```yaml
scrape_configs:
  # ---------- API server ----------
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

  # ---------- Kubelet ----------
  - job_name: kubernetes-nodes
    kubernetes_sd_configs:
      - role: node
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    authorization:
      credentials_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)

  # ---------- cAdvisor: SAME role, different path ----------
  - job_name: kubernetes-cadvisor
    kubernetes_sd_configs:
      - role: node
    scheme: https
    metrics_path: /metrics/cadvisor
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    authorization:
      credentials_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)

  # ---------- Annotation-driven pods ----------
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
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scheme]
        action: replace
        target_label: __scheme__
        regex: (https?)
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        target_label: namespace
      - source_labels: [__meta_kubernetes_pod_name]
        target_label: pod
      - source_labels: [__meta_kubernetes_pod_container_name]
        target_label: container
      - source_labels: [__meta_kubernetes_pod_node_name]
        target_label: node

  # ---------- Annotation-driven service endpoints ----------
  - job_name: kubernetes-service-endpoints
    kubernetes_sd_configs:
      - role: endpoints
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        target_label: namespace
      - source_labels: [__meta_kubernetes_service_name]
        target_label: service

  # ---------- Ingress blackbox probing ----------
  - job_name: kubernetes-ingresses
    metrics_path: /probe
    params:
      module: [http_2xx]
    kubernetes_sd_configs:
      - role: ingress
    relabel_configs:
      - source_labels:
          - __meta_kubernetes_ingress_scheme
          - __address__
          - __meta_kubernetes_ingress_path
        regex: (.+);(.+);(.+)
        replacement: ${1}://${2}${3}
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115
```

## RBAC

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
  - apiGroups: [""]
    resources: ["nodes", "nodes/metrics", "nodes/proxy", "services", "endpoints", "pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["discovery.k8s.io"]
    resources: ["endpointslices"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["extensions"]
    resources: ["ingresses"]
    verbs: ["get", "list", "watch"]
  - nonResourceURLs: ["/metrics", "/metrics/cadvisor"]
    verbs: ["get"]
```

**If Kubernetes SD returns nothing, RBAC is the first thing to check.** `nodes/metrics` is needed for the kubelet, and the `nonResourceURLs` entry is needed for the raw `/metrics` paths.

## The Prometheus Operator

The Operator replaces hand-written scrape configs with CRDs.

| CRD | Purpose |
| --- | --- |
| **Prometheus** | Declares a Prometheus deployment |
| **PrometheusAgent** | Agent-mode deployment |
| **Alertmanager** | Declares an Alertmanager cluster |
| **ServiceMonitor** | "Scrape the pods behind these Services" |
| **PodMonitor** | "Scrape these Pods directly" |
| **Probe** | "Blackbox-probe these targets" |
| **PrometheusRule** | Recording and alerting rules |
| **ScrapeConfig** | Raw scrape config for anything outside the cluster |
| **ThanosRuler** | Thanos rule evaluation |

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp
  namespace: production
  labels:
    release: kube-prometheus-stack     # must match the Prometheus serviceMonitorSelector
spec:
  selector:
    matchLabels:
      app: myapp                       # selects the SERVICE, not the pods
  namespaceSelector:
    matchNames: ["production"]
  endpoints:
    - port: metrics                    # the Service PORT NAME, not a number
      path: /metrics
      interval: 15s
      scrapeTimeout: 10s
      scheme: http
      honorLabels: false
      relabelings:
        - sourceLabels: [__meta_kubernetes_pod_node_name]
          targetLabel: node
      metricRelabelings:
        - sourceLabels: [__name__]
          regex: 'go_gc_.*'
          action: drop
```

Notes on the CRD schema, which differs from raw config in ways that get tested:

- Field names are **camelCase**: `sourceLabels`, `targetLabel`, `relabelings`, `metricRelabelings`, `honorLabels`.
- `relabelings` maps to `relabel_configs`; `metricRelabelings` maps to `metric_relabel_configs`.
- `spec.selector` selects the **Service**, and Prometheus then scrapes its **endpoints**.
- `endpoints[].port` is the **port name** from the Service, not a number. `targetPort` is available for the numeric case.
- The ServiceMonitor must carry labels matching the Prometheus resource's `serviceMonitorSelector`, or it is silently ignored.

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: myapp-rules
  labels:
    release: kube-prometheus-stack
spec:
  groups:
    - name: myapp
      interval: 30s
      rules:
        - record: job:myapp_requests:rate5m
          expr: sum by (job) (rate(myapp_requests_total[5m]))
        - alert: MyAppHighErrorRate
          expr: |
            sum by (job) (rate(myapp_requests_total{code=~"5.."}[5m]))
              / sum by (job) (rate(myapp_requests_total[5m])) > 0.05
          for: 10m
          labels:
            severity: critical
          annotations:
            summary: "{{ $labels.job }} error ratio {{ $value | humanizePercentage }}"
```

The single most common Operator problem: **a ServiceMonitor exists but nothing is scraped.** Causes, in order of likelihood:

1. Its labels do not match the Prometheus `serviceMonitorSelector`.
2. `namespaceSelector` excludes the namespace.
3. `endpoints[].port` does not match a **named** port on the Service.
4. The Service's `selector` matches no pods.
5. RBAC.

**kube-prometheus-stack** is the Helm chart bundling the Operator, Prometheus, Alertmanager, node_exporter, kube-state-metrics, Grafana, and a large default rule set.

## Essential Kubernetes Queries

### Pods and workloads (kube-state-metrics)

```promql
# Pods not running
kube_pod_status_phase{phase!="Running"} == 1
sum by (namespace, phase) (kube_pod_status_phase)

# Crash looping
increase(kube_pod_container_status_restarts_total[1h]) > 3
rate(kube_pod_container_status_restarts_total[15m]) > 0

# Containers waiting, with the reason
kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff"} == 1
kube_pod_container_status_waiting_reason{reason="ImagePullBackOff"} == 1

# Terminated by OOM
kube_pod_container_status_last_terminated_reason{reason="OOMKilled"} == 1

# Deployment not fully available
kube_deployment_spec_replicas - kube_deployment_status_replicas_available > 0

# Deployment mismatch, generation not observed
kube_deployment_status_observed_generation != kube_deployment_metadata_generation

# StatefulSet and DaemonSet health
kube_statefulset_status_replicas_ready < kube_statefulset_replicas
kube_daemonset_status_number_unavailable > 0

# Jobs
kube_job_status_failed > 0
kube_job_status_succeeded == 0 and kube_job_spec_completions > 0

# PVCs
kube_persistentvolumeclaim_status_phase{phase="Pending"} == 1

# Node conditions
kube_node_status_condition{condition="Ready", status="true"} == 0
kube_node_spec_unschedulable == 1
kube_node_status_condition{condition="MemoryPressure", status="true"} == 1
kube_node_status_condition{condition="DiskPressure", status="true"} == 1
```

### Container resource usage (cAdvisor)

```promql
# CPU per pod
sum by (namespace, pod) (rate(container_cpu_usage_seconds_total{container!="", container!="POD"}[5m]))

# Memory per pod: working set is the number that matters for OOM
sum by (namespace, pod) (container_memory_working_set_bytes{container!="", container!="POD"})

# CPU throttling: the ratio that matters
sum by (namespace, pod) (rate(container_cpu_cfs_throttled_periods_total[5m]))
  / sum by (namespace, pod) (rate(container_cpu_cfs_periods_total[5m]))

# Network
sum by (namespace, pod) (rate(container_network_receive_bytes_total[5m]))
sum by (namespace, pod) (rate(container_network_transmit_bytes_total[5m]))

# Filesystem
container_fs_usage_bytes / container_fs_limit_bytes
```

Always filter `container!=""` (which excludes the pod-level aggregate) and `container!="POD"` (the pause container), or you double-count.

### Usage versus requests and limits: joining the two sources

This pattern is the payoff of understanding the trio, because it needs cAdvisor **and** kube-state-metrics.

```promql
# CPU usage as a fraction of the request
sum by (namespace, pod) (rate(container_cpu_usage_seconds_total{container!=""}[5m]))
  / sum by (namespace, pod) (kube_pod_container_resource_requests{resource="cpu"})

# Memory usage as a fraction of the limit: the OOM predictor
sum by (namespace, pod) (container_memory_working_set_bytes{container!=""})
  / sum by (namespace, pod) (kube_pod_container_resource_limits{resource="memory"})

# Cluster CPU overcommit
sum(kube_pod_container_resource_requests{resource="cpu"})
  / sum(kube_node_status_allocatable{resource="cpu"})

# Pods with no resource requests set at all
kube_pod_container_info
  unless on (namespace, pod, container)
kube_pod_container_resource_requests{resource="cpu"}
```

That last query uses `unless` as set difference, which is the idiomatic way to find "objects lacking a property".

### Control plane

```promql
# API server request rate and errors
sum by (verb, resource) (rate(apiserver_request_total[5m]))
sum(rate(apiserver_request_total{code=~"5.."}[5m])) / sum(rate(apiserver_request_total[5m]))

# API server latency
histogram_quantile(0.99,
  sum by (le, verb, resource) (rate(apiserver_request_duration_seconds_bucket[5m])))

# etcd
etcd_server_has_leader == 0
increase(etcd_server_leader_changes_seen_total[1h]) > 3
histogram_quantile(0.99, rate(etcd_disk_wal_fsync_duration_seconds_bucket[5m])) > 0.01
histogram_quantile(0.99, rate(etcd_disk_backend_commit_duration_seconds_bucket[5m])) > 0.025
etcd_mvcc_db_total_size_in_bytes / etcd_server_quota_backend_bytes

# Scheduler
rate(scheduler_schedule_attempts_total{result="unschedulable"}[5m]) > 0
histogram_quantile(0.99, rate(scheduler_scheduling_attempt_duration_seconds_bucket[5m]))

# CoreDNS
sum(rate(coredns_dns_responses_total{rcode="SERVFAIL"}[5m]))
histogram_quantile(0.99, rate(coredns_dns_request_duration_seconds_bucket[5m]))

# Kubelet
kubelet_running_pods
kubelet_volume_stats_available_bytes / kubelet_volume_stats_capacity_bytes
histogram_quantile(0.99, rate(kubelet_pod_start_duration_seconds_bucket[5m]))
```

## Alerts Worth Having

```yaml
      - alert: KubePodCrashLooping
        expr: increase(kube_pod_container_status_restarts_total[1h]) > 5
        for: 10m
        labels: {severity: warning}
        annotations:
          summary: "{{ $labels.namespace }}/{{ $labels.pod }} restarted {{ $value }} times in an hour"

      - alert: KubePodNotReady
        expr: |
          sum by (namespace, pod) (
            max by (namespace, pod) (kube_pod_status_phase{phase=~"Pending|Unknown"})
            * on (namespace, pod) group_left (owner_kind)
            max by (namespace, pod, owner_kind) (kube_pod_owner{owner_kind!="Job"})
          ) > 0
        for: 15m
        labels: {severity: warning}

      - alert: KubeDeploymentReplicasMismatch
        expr: |
          kube_deployment_spec_replicas != kube_deployment_status_replicas_available
        for: 15m
        labels: {severity: warning}

      - alert: KubeContainerOOMKilled
        expr: |
          increase(kube_pod_container_status_restarts_total[10m]) > 0
            and on (namespace, pod, container)
          kube_pod_container_status_last_terminated_reason{reason="OOMKilled"} == 1
        labels: {severity: warning}

      - alert: KubeNodeNotReady
        expr: kube_node_status_condition{condition="Ready", status="true"} == 0
        for: 15m
        labels: {severity: critical}

      - alert: KubeCPUThrottlingHigh
        expr: |
          sum by (namespace, pod) (rate(container_cpu_cfs_throttled_periods_total[5m]))
            / sum by (namespace, pod) (rate(container_cpu_cfs_periods_total[5m])) > 0.25
        for: 15m
        labels: {severity: warning}

      - alert: KubeMemoryNearLimit
        expr: |
          sum by (namespace, pod) (container_memory_working_set_bytes{container!=""})
            / sum by (namespace, pod) (kube_pod_container_resource_limits{resource="memory"}) > 0.9
        for: 15m
        labels: {severity: warning}

      - alert: KubePersistentVolumeFillingUp
        expr: |
          kubelet_volume_stats_available_bytes / kubelet_volume_stats_capacity_bytes < 0.10
            and
          predict_linear(kubelet_volume_stats_available_bytes[6h], 4*24*3600) < 0
        for: 1h
        labels: {severity: warning}

      - alert: KubeAPIErrorRateHigh
        expr: |
          sum(rate(apiserver_request_total{code=~"5.."}[5m]))
            / sum(rate(apiserver_request_total[5m])) > 0.05
        for: 10m
        labels: {severity: critical}

      - alert: EtcdNoLeader
        expr: etcd_server_has_leader == 0
        for: 1m
        labels: {severity: critical}
```

## Cardinality In Kubernetes

Kubernetes is the classic cardinality trap, because every pod restart creates a new pod name and therefore a whole new set of series.

Labels that cause trouble:

```text
pod                       new value on every restart
pod_template_hash         new value on every deploy
controller_revision_hash  new value on every deploy
id                        cgroup path, one per container
uid                       one per object instance
image_id / container_id   digests
```

Mitigation:

```yaml
    metric_relabel_configs:
      - regex: 'pod_template_hash|controller_revision_hash|id|uid|image_id|container_id'
        action: labeldrop

      # apiserver histograms are enormous; drop unneeded buckets
      - source_labels: [__name__]
        regex: 'apiserver_request_duration_seconds_bucket'
        action: drop
```

Find it:

```promql
topk(10, count by (__name__) ({__name__=~".+"}))
topk(10, count by (namespace) ({__name__=~"container_.*"}))
count(count by (pod) (kube_pod_info))
scrape_series_added{job="kubernetes-cadvisor"}
```

```bash
curl -s http://localhost:9090/api/v1/status/tsdb \
  | jq '.data.labelValueCountByLabelName[:10], .data.seriesCountByMetricName[:10]'
```

The general principle: **aggregate away `pod` as early as possible.** Deployment-level series are stable; pod-level series churn constantly.

## Traps

| Mistake | Consequence |
| --- | --- |
| Using `role: service` to scrape pods | Load-balances across pods; counters look like they reset |
| Expecting cAdvisor as a separate deployment | It is in the kubelet at `/metrics/cadvisor` |
| Expecting kube-state-metrics to report usage | It reports declared object state |
| Expecting cAdvisor to know about Deployments | It only sees containers |
| Not filtering `container!=""` on cAdvisor metrics | Double counting with the pod-level aggregate |
| Missing RBAC | SD silently returns nothing |
| ServiceMonitor labels not matching `serviceMonitorSelector` | Silently ignored |
| `endpoints[].port` as a number instead of a name | Nothing scraped |
| Keeping `pod_template_hash` and friends | Cardinality explosion on every deploy |
| Alerting on any pod restart | Noise. Alert on repeated restarts |
| Using `container_memory_usage_bytes` for OOM prediction | Includes cache. Use `container_memory_working_set_bytes` |

## Memorise

- **cAdvisor is built into the kubelet at `/metrics/cadvisor`.** Discover it with `role: node` and a different `metrics_path`.
- **kube-state-metrics = declared object state from the API (`kube_*`). cAdvisor = container resource usage (`container_*`). node_exporter = host resources (`node_*`).**
- SD roles: **node, pod, endpoints, endpointslice, service, ingress**. **`endpoints`/`endpointslice` for scraping, `service`/`ingress` for probing.**
- `role: endpoints` targets carry **both service and pod** metadata.
- Annotation labels are sanitised: `prometheus.io/scrape` → `__meta_kubernetes_pod_annotation_prometheus_io_scrape`.
- **`labelmap` with `__meta_kubernetes_pod_label_(.+)`** promotes pod labels.
- **RBAC is the first thing to check** when Kubernetes SD finds nothing. Needs `nodes/metrics` and the `nonResourceURLs` entry.
- Operator CRDs: **Prometheus, Alertmanager, ServiceMonitor, PodMonitor, Probe, PrometheusRule, ScrapeConfig**. Fields are **camelCase**; `relabelings` and `metricRelabelings`.
- A ServiceMonitor selects the **Service** and uses the **port name**; it must match `serviceMonitorSelector` labels or it is ignored.
- **kube-prometheus-stack** is the standard bundle.
- Filter **`container!=""`** on cAdvisor metrics.
- Use **`container_memory_working_set_bytes`** for memory pressure, not `container_memory_usage_bytes`.
- CPU throttling ratio = **`rate(container_cpu_cfs_throttled_periods_total) / rate(container_cpu_cfs_periods_total)`**.
- Join usage to requests and limits with **`kube_pod_container_resource_requests` / `_limits`**.
- Drop **`pod_template_hash`, `controller_revision_hash`, `id`, `uid`** to control cardinality, and aggregate away `pod` early.
- Prometheus was the **second CNCF project** after Kubernetes and **graduated in 2018**.
