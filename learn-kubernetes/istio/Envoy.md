# Envoy Reference

Envoy is the sidecar/waypoint proxy. Admin **localhost:15000**.

```bash
kubectl exec -c istio-proxy deploy/sleep -n demo -- curl -s 127.0.0.1:15000/ready
kubectl exec -c istio-proxy deploy/sleep -n demo -- curl -s 127.0.0.1:15000/stats | grep httpbin
kubectl exec -c istio-proxy deploy/sleep -n demo -- curl -s 127.0.0.1:15000/config_dump | jq '.configs[].@type'
istioctl proxy-config log deploy/sleep.demo --level http:debug
istioctl proxy-config log deploy/sleep.demo --level info
```

## Filter chain mental model

```text
Listener (LDS) -> HTTP connection manager -> Route (RDS) -> Cluster (CDS) -> Endpoints (EDS)
```

Inbound listener `0.0.0.0:15006` plus per-port chains. Outbound `15001`.

## Access log columns (text)

Typically: method, path, code, flags, duration, upstream, authority. JSON: `response_code`, `response_flags`, `upstream_cluster`, `path`.

## NACK

Envoy rejects bad xDS (EnvoyFilter). `proxy-status` STALE + istiod logs `NACK`.

Istio hides most Envoy YAML; you still debug with `pc` dumps.

File: `31.md`, `33.md`.
