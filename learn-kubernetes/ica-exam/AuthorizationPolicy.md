# AuthorizationPolicy Reference

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: httpbin
  namespace: demo
spec:
  selector:
    matchLabels: { app: httpbin }
  action: ALLOW          # ALLOW | DENY | AUDIT | CUSTOM
  rules:
    - from:
        - source:
            principals: ["cluster.local/ns/demo/sa/sleep"]
            requestPrincipals: ["iss/sub"]
            namespaces: ["demo"]
            ipBlocks: ["10.0.0.0/8"]
            notNamespaces: ["evil"]
      to:
        - operation:
            methods: ["GET"]
            paths: ["/get", "/status/*"]
            hosts: ["httpbin.example.com"]
            ports: ["8000"]
            notMethods: ["DELETE"]
      when:
        - key: request.headers[x-token]
          values: ["letmein"]
```

## Evaluation

1. DENY match → 403
2. No ALLOW selecting workload → allow
3. ALLOW exists → allow only on match
4. ALLOW with **no rules** → deny all

OR = multiple rules. AND = fields in one rule.

Inbound on the **server**. Selecting the client does nothing.

`namespaces` / `principals` need mTLS.

Gateway policies: hosts/paths/methods/JWT; no client SPIFFE from the internet.

Ambient L7 fields need a waypoint.

Files: `25.md`, `26.md`.
