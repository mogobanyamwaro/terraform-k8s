# VirtualService Reference

**Where** traffic goes. Ordered HTTP rules, first match wins.

```yaml
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: reviews
  namespace: bookinfo
spec:
  hosts: [reviews]
  gateways: [mesh]
  exportTo: ["."]
  http:
    - name: jason-to-v2
      match:
        - headers:
            end-user: { exact: jason }
      route:
        - destination: { host: reviews, subset: v2 }
      timeout: 3s
      retries: { attempts: 2, perTryTimeout: 1s, retryOn: 5xx }
      rewrite: { uri: / }
      fault:
        delay: { percentage: { value: 100.0 }, fixedDelay: 2s }
      mirror: { host: reviews, subset: v3 }
      mirrorPercentage: { value: 10.0 }
      corsPolicy: {}
      headers:
        request:
          set: { x-foo: bar }
    - route:
        - destination: { host: reviews, subset: v1, port: { number: 9080 } }
          weight: 80
        - destination: { host: reviews, subset: v2 }
          weight: 20
  tcp: []
  tls: []
```

## hosts vs destination.host

`spec.hosts` = when to apply. `destination.host` = where to send. They can differ (redirect to another service).

Short names resolve in the **VS namespace**. Cross-ns: FQDN.

## match

OR across list entries, AND inside one. URI `exact` | `prefix` | `regex`. Also method, headers, queryParams, sourceLabels, sourceNamespace, port, gateways, withoutHeaders, authority, scheme.

A rule with **no match** is catch-all — **last**.

## Things that live here (not on DR)

timeout, retries, fault, mirror, rewrite, redirect, cors, header manip, weights, matches.

## tls / tcp

PASSTHROUGH uses `tls.match.sniHosts`. TCP uses `tcp.match.port`.

## exportTo

`"."` this ns, `"*"` all (default). Destination must still be visible.

Files: `09.md`, `10.md`, `12.md`, `13.md`, `18.md`, `20.md`.
