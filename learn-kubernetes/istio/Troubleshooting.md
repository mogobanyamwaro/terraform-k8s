# Troubleshooting Reference

## Order

```text
1. Context and namespace
2. istioctl analyze -A
3. istioctl proxy-status
4. kubectl -n istio-system get po
5. istioctl pc route/cluster/endpoint on SOURCE
6. Access log FLAGS on source and dest
7. PeerAuthentication / AuthorizationPolicy / JWT
8. Actual curl through the path the task named
```

## Flags → fix

| Flag | Look at |
| --- | --- |
| NR | VS bind, hosts, catch-all, subset cluster |
| UH | Endpoints, subset labels, outlier |
| UO | connectionPool |
| UT | timeout vs delay vs slow app |
| UF | mTLS mismatch, port, pod death |

## Control vs data

| Control | Data |
| --- | --- |
| No injection, webhook errors, all STALE, CA | 503 with SYNCED proxies, wrong route, authz 403 |

## Injection

Label then **restart**. Conflict: `istio-injection` + wrong `istio.io/rev`.

## Ambient

L7 ignored without waypoint. `pc` on app pod fails. Use ztunnel-config.

Files: `29.md`–`36.md`, `Envoy.md`.
