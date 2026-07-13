# Service Discovery

## Why It Exists

Prometheus pulls, so it must know **what to pull from**. In a dynamic environment, maintaining that list by hand is impossible. Service discovery keeps the target list current automatically.

```text
SD mechanism ──► list of targets with __address__ and __meta_* labels
                                    │
                                    ▼
                            relabel_configs
                                    │
                                    ▼
                            final target list
```

Every SD mechanism produces `__address__` plus a set of `__meta_*` metadata labels. Relabeling then filters and shapes them.

## The Mechanisms

| Config block | Discovers |
| --- | --- |
| `static_configs` | A hard-coded list |
| `file_sd_configs` | Targets from JSON or YAML files, **watched for changes** |
| `http_sd_configs` | Targets from an HTTP endpoint returning JSON, polled |
| `kubernetes_sd_configs` | Kubernetes API: node, service, pod, endpoints, endpointslice, ingress |
| `consul_sd_configs` | Consul services |
| `dns_sd_configs` | DNS SRV, A, AAAA, MX, NS records |
| `ec2_sd_configs` | AWS EC2 instances |
| `azure_sd_configs` | Azure VMs |
| `gce_sd_configs` | Google Compute Engine |
| `digitalocean_sd_configs`, `hetzner_sd_configs`, `linode_sd_configs`, `scaleway_sd_configs`, `openstack_sd_configs`, `ovhcloud_sd_configs`, `vultr_sd_configs` | Other clouds |
| `docker_sd_configs`, `dockerswarm_sd_configs` | Docker containers and Swarm |
| `marathon_sd_configs`, `nomad_sd_configs`, `serverset_sd_configs`, `triton_sd_configs`, `eureka_sd_configs`, `puppetdb_sd_configs`, `uyuni_sd_configs`, `ionos_sd_configs`, `kuma_sd_configs` | Various orchestrators and inventories |

For the exam, know **static, file, http, kubernetes, consul, dns, and ec2** properly. The rest just need to be recognisable as SD mechanisms.

## static_configs

```yaml
  - job_name: node
    static_configs:
      - targets:
          - "node1:9100"
          - "node2:9100"
        labels:
          env: production
          datacenter: dc1
      - targets:
          - "node3:9100"
        labels:
          env: staging
```

The `labels` block attaches labels to every target in that group. Simple, and still the right answer for a handful of fixed targets.

## file_sd_configs

```yaml
  - job_name: file
    file_sd_configs:
      - files:
          - /etc/prometheus/targets/*.json
          - /etc/prometheus/targets/*.yml
        refresh_interval: 5m
```

`targets/apps.json`:

```json
[
  {
    "targets": ["app1:8080", "app2:8080"],
    "labels": {"env": "production", "team": "payments"}
  },
  {
    "targets": ["app3:8080"],
    "labels": {"env": "staging", "team": "payments"}
  }
]
```

Or YAML:

```yaml
- targets: ["app1:8080", "app2:8080"]
  labels:
    env: production
```

| `__meta_*` label | Value |
| --- | --- |
| `__meta_filepath` | The file the target came from |

Key facts:

- Files are **watched via inotify** and picked up on change. `refresh_interval` (default `5m`) is a fallback poll.
- **No Prometheus reload is needed** when the file contents change. That is the whole point.
- Adding a **new file** that matches an existing glob also works without a reload.
- This is the standard integration point for any custom inventory: have a script write the JSON.

## http_sd_configs

```yaml
  - job_name: http_sd
    http_sd_configs:
      - url: https://inventory.example.com/prometheus/targets
        refresh_interval: 1m
        basic_auth:
          username: prom
          password_file: /etc/prometheus/sd_password
```

The endpoint must return the **same JSON shape as file SD**, with `Content-Type: application/json`.

| `__meta_*` label | Value |
| --- | --- |
| `__meta_url` | The SD endpoint URL |

Use it when your inventory lives behind an API. It is a poll, not a watch, so `refresh_interval` matters.

## dns_sd_configs

```yaml
  - job_name: dns_srv
    dns_sd_configs:
      - names:
          - _prometheus._tcp.example.com
        type: SRV
        refresh_interval: 30s

  - job_name: dns_a
    dns_sd_configs:
      - names:
          - app.example.com
        type: A
        port: 9100            # REQUIRED for A/AAAA, since there is no port in the record
```

| `__meta_*` label | Value |
| --- | --- |
| `__meta_dns_name` | The queried record name |
| `__meta_dns_srv_record_target` | SRV target |
| `__meta_dns_srv_record_port` | SRV port |
| `__meta_dns_mx_record_target` | MX target |
| `__meta_dns_ns_record_target` | NS target |

Key fact: **`port` is required for `A` and `AAAA` types** because those records carry no port. SRV records include the port, so `port` is not needed.

## consul_sd_configs

```yaml
  - job_name: consul
    consul_sd_configs:
      - server: consul.example.com:8500
        token: <acl-token>
        datacenter: dc1
        services: []           # empty means ALL services
        tags: ["prometheus"]
        scheme: http
    relabel_configs:
      - source_labels: [__meta_consul_tags]
        regex: '.*,prometheus,.*'
        action: keep
      - source_labels: [__meta_consul_service]
        target_label: job
```

| `__meta_*` label | Value |
| --- | --- |
| `__meta_consul_address` | Node address |
| `__meta_consul_dc` | Datacenter |
| `__meta_consul_health` | Health status |
| `__meta_consul_node` | Node name |
| `__meta_consul_service` | Service name |
| `__meta_consul_service_address` | Service address |
| `__meta_consul_service_id` | Service ID |
| `__meta_consul_service_port` | Service port |
| `__meta_consul_tags` | Tags, joined and surrounded by the tag separator (default `,`) |
| `__meta_consul_metadata_<key>` | Node metadata |
| `__meta_consul_service_metadata_<key>` | Service metadata |

Note the tag matching idiom: because tags are joined **and surrounded** by the separator, the regex is `.*,prometheus,.*`. That leading and trailing separator is why the pattern looks odd.

## ec2_sd_configs

```yaml
  - job_name: ec2
    ec2_sd_configs:
      - region: eu-west-1
        access_key: ...
        secret_key: ...
        port: 9100
        filters:
          - name: tag:Environment
            values: ["production"]
    relabel_configs:
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance_name
      - source_labels: [__meta_ec2_private_ip]
        replacement: "$1:9100"
        target_label: __address__
```

| `__meta_*` label | Value |
| --- | --- |
| `__meta_ec2_instance_id` | Instance ID |
| `__meta_ec2_instance_type` | Type |
| `__meta_ec2_instance_state` | State |
| `__meta_ec2_availability_zone` | AZ |
| `__meta_ec2_private_ip` / `__meta_ec2_public_ip` | Addresses |
| `__meta_ec2_private_dns_name` / `__meta_ec2_public_dns_name` | DNS names |
| `__meta_ec2_vpc_id`, `__meta_ec2_subnet_id` | Network |
| `__meta_ec2_tag_<Key>` | EC2 tags. Non-alphanumeric characters in the key become `_` |
| `__meta_ec2_ami` | AMI ID |

The `__meta_ec2_tag_<Key>` pattern generalises: every cloud SD exposes tags or labels this way, with unsupported characters replaced by underscores.

## kubernetes_sd_configs

The most important one. Six **roles**, each discovering a different object type.

```yaml
  - job_name: k8s
    kubernetes_sd_configs:
      - role: pod
        api_server: https://kubernetes.default.svc
        namespaces:
          names: ["production", "staging"]
        selectors:
          - role: pod
            label: "app=frontend"
```

| Role | Discovers | One target per |
| --- | --- | --- |
| `node` | Cluster nodes | Node, addressed at the kubelet |
| `service` | Services | Service port. **For blackbox probing, not for scraping pods** |
| `pod` | Pods | Declared container port (or the pod itself if none) |
| `endpoints` | Service endpoints | Endpoint address and port. **The usual choice for scraping backing pods** |
| `endpointslice` | EndpointSlices | Endpoint address and port. The modern replacement for `endpoints` |
| `ingress` | Ingresses | Ingress path. For blackbox probing |

The `service` versus `endpoints` distinction is examined: `service` gives you one target per **service**, which load-balances and is therefore only useful for probing. `endpoints` / `endpointslice` gives you one target per **backing pod**, which is what you want for real metrics.

### Common `__meta_kubernetes_*` labels

Role `node`:

```text
__meta_kubernetes_node_name
__meta_kubernetes_node_provider_id
__meta_kubernetes_node_label_<name>
__meta_kubernetes_node_labelpresent_<name>
__meta_kubernetes_node_annotation_<name>
__meta_kubernetes_node_address_<type>      # InternalIP, Hostname, ...
```

Role `pod`:

```text
__meta_kubernetes_namespace
__meta_kubernetes_pod_name
__meta_kubernetes_pod_ip
__meta_kubernetes_pod_label_<name>
__meta_kubernetes_pod_labelpresent_<name>
__meta_kubernetes_pod_annotation_<name>
__meta_kubernetes_pod_annotationpresent_<name>
__meta_kubernetes_pod_container_name
__meta_kubernetes_pod_container_port_name
__meta_kubernetes_pod_container_port_number
__meta_kubernetes_pod_container_port_protocol
__meta_kubernetes_pod_container_init
__meta_kubernetes_pod_ready                # true / false
__meta_kubernetes_pod_phase                # Pending, Running, Succeeded, Failed, Unknown
__meta_kubernetes_pod_node_name
__meta_kubernetes_pod_host_ip
__meta_kubernetes_pod_uid
__meta_kubernetes_pod_controller_kind
__meta_kubernetes_pod_controller_name
```

Role `service`:

```text
__meta_kubernetes_service_name
__meta_kubernetes_service_label_<name>
__meta_kubernetes_service_annotation_<name>
__meta_kubernetes_service_port_name
__meta_kubernetes_service_port_number
__meta_kubernetes_service_port_protocol
__meta_kubernetes_service_cluster_ip
__meta_kubernetes_service_external_name
__meta_kubernetes_service_type
```

Role `endpoints` (gets service **and** pod metadata for the backing pod):

```text
__meta_kubernetes_endpoints_name
__meta_kubernetes_endpoint_address_target_kind
__meta_kubernetes_endpoint_address_target_name
__meta_kubernetes_endpoint_node_name
__meta_kubernetes_endpoint_port_name
__meta_kubernetes_endpoint_port_protocol
__meta_kubernetes_endpoint_ready           # true / false
+ all __meta_kubernetes_service_* labels
+ all __meta_kubernetes_pod_* labels
```

That last point is why `endpoints` is so useful: you get service-level annotations **and** pod-level identity in one target.

Role `ingress`:

```text
__meta_kubernetes_ingress_name
__meta_kubernetes_ingress_label_<name>
__meta_kubernetes_ingress_annotation_<name>
__meta_kubernetes_ingress_scheme
__meta_kubernetes_ingress_path
__meta_kubernetes_ingress_class_name
```

Naming rules: annotation and label keys have non-alphanumeric characters replaced by `_`, so `prometheus.io/scrape` becomes `__meta_kubernetes_service_annotation_prometheus_io_scrape`. The `*_labelpresent_*` and `*_annotationpresent_*` variants are `true` when the key exists, which lets you test presence separately from value.

### The classic annotation-driven pod scrape config

Memorise the shape of this. It appears constantly.

```yaml
  - job_name: kubernetes-pods
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      # Only pods with prometheus.io/scrape: "true"
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true

      # Optional path override
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)

      # Optional port override
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__

      # Optional scheme override
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scheme]
        action: replace
        target_label: __scheme__
        regex: (https?)

      # Promote pod labels
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)

      # Standard identity labels
      - source_labels: [__meta_kubernetes_namespace]
        target_label: namespace
      - source_labels: [__meta_kubernetes_pod_name]
        target_label: pod
      - source_labels: [__meta_kubernetes_pod_container_name]
        target_label: container
      - source_labels: [__meta_kubernetes_pod_node_name]
        target_label: node
```

### Scraping the Kubernetes control plane

```yaml
  # API server, via the endpoints of the default/kubernetes service
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

  # Kubelet /metrics
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

  # cAdvisor, served BY the kubelet at a different path
  - job_name: kubernetes-cadvisor
    kubernetes_sd_configs:
      - role: node
    scheme: https
    metrics_path: /metrics/cadvisor
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    authorization:
      credentials_file: /var/run/secrets/kubernetes.io/serviceaccount/token
```

Note that **cAdvisor is not a separate process**; it is served by the kubelet at `/metrics/cadvisor`. Same `role: node`, different `metrics_path`.

### Kubernetes RBAC for SD

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
  - apiGroups: [""]
    resources: ["nodes", "nodes/metrics", "services", "endpoints", "pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["discovery.k8s.io"]
    resources: ["endpointslices"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["get", "list", "watch"]
  - nonResourceURLs: ["/metrics", "/metrics/cadvisor"]
    verbs: ["get"]
```

If SD returns nothing in Kubernetes, **RBAC is the first thing to check**.

## Debugging Service Discovery

The order of checks:

```text
1. /service-discovery  -> were targets discovered at all?
                          shows discovered __meta_* labels AND the post-relabel result
2. /targets            -> are they being scraped, and what is lastError?
3. prometheus_sd_discovered_targets -> count per config
4. relabel_configs     -> did a keep/drop remove them?
```

```bash
curl -s http://localhost:9090/api/v1/targets | jq -r '
  .data.activeTargets[] | "\(.scrapePool)  \(.scrapeUrl)  \(.health)  \(.lastError)"'

curl -s 'http://localhost:9090/api/v1/targets?state=dropped' \
  | jq -r '.data.droppedTargets[].discoveredLabels'
```

```promql
prometheus_sd_discovered_targets
prometheus_sd_kubernetes_events_total
prometheus_sd_failed_configs
prometheus_sd_file_read_errors_total
prometheus_sd_http_failures_total
prometheus_sd_consul_rpc_failures_total
prometheus_sd_dns_lookup_failures_total
up == 0
count by (job) (up)
```

| Symptom | Cause |
| --- | --- |
| No targets in `/service-discovery` | SD itself is failing: credentials, RBAC, network, DNS |
| Targets in `/service-discovery` but not `/targets` | A `keep`/`drop` relabel rule removed them |
| Targets present but `up == 0` | Wrong port, wrong path, TLS failure, or the app is genuinely down |
| Targets appear then vanish repeatedly | Underlying inventory churn, or a flapping health check |
| `__meta_*` labels missing on metrics | Expected. They are dropped. Promote them with relabeling |

## Push Versus Pull, One More Time

Since SD only makes sense in a pull world, this is where the exam usually pairs the two topics.

| Pull advantages | Push advantages |
| --- | --- |
| Prometheus controls the rate, so no client can overwhelm it | Works through NAT and firewalls without inbound access |
| Target liveness is intrinsic: `up` is free | No SD needed |
| Easy to run a second Prometheus, or a test one | Better for very short-lived jobs |
| You can `curl /metrics` by hand to debug | Lower latency for event-like data |
| No central bottleneck for ingestion | |
| Service discovery gives you the intended target list, so you can detect **missing** targets | |

That last point is the strongest pull argument: with push, a target that never checks in is invisible. With pull, SD says it should exist and `up == 0` or `absent()` tells you it does not.

## Memorise

- SD produces **`__address__`** plus **`__meta_*`** labels; **relabeling filters and shapes** them.
- **All `__meta_*` labels are discarded** after `relabel_configs`. Promote what you need.
- Know: **static, file, http, kubernetes, consul, dns, ec2**.
- **file_sd is watched via inotify. No reload needed** when contents change. `refresh_interval` default `5m`.
- **http_sd returns the same JSON shape as file_sd** and is polled.
- **`dns_sd` with type `A`/`AAAA` requires `port`.** SRV records carry their own port.
- Consul tags are joined **and surrounded** by the separator, hence `regex: '.*,prometheus,.*'`.
- Cloud tags become **`__meta_<provider>_tag_<Key>`** with non-alphanumerics replaced by `_`.
- Kubernetes roles: **node, service, pod, endpoints, endpointslice, ingress**.
- **`endpoints`/`endpointslice` for scraping backing pods; `service` and `ingress` for blackbox probing.**
- `endpoints` targets carry **both service and pod** metadata.
- Annotation keys are sanitised: `prometheus.io/scrape` → `__meta_kubernetes_pod_annotation_prometheus_io_scrape`.
- **cAdvisor is served by the kubelet at `/metrics/cadvisor`**, using `role: node`.
- Kubernetes SD failing usually means **RBAC**.
- Debug order: **`/service-discovery` → `/targets` → `prometheus_sd_*` metrics → relabel rules**.
- Pull's decisive advantage is that **SD tells you which targets should exist**, so missing targets are detectable.
