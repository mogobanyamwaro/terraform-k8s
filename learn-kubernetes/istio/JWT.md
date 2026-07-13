# JWT Reference

```yaml
apiVersion: security.istio.io/v1
kind: RequestAuthentication
metadata:
  name: httpbin
  namespace: demo
spec:
  selector:
    matchLabels: { app: httpbin }
  jwtRules:
    - issuer: "https://auth.example.com"
      jwksUri: "https://auth.example.com/jwks.json"
      # jwks: '{"keys":[...]}'
      audiences: ["httpbin"]
      fromHeaders:
        - name: Authorization
          prefix: "Bearer "
      fromParams: ["token"]
      forwardOriginalToken: true
      outputPayloadToHeader: x-jwt
```

Require token:

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: httpbin-jwt
  namespace: demo
spec:
  selector: { matchLabels: { app: httpbin } }
  action: ALLOW
  rules:
    - from:
        - source:
            requestPrincipals: ["*"]
    # or when:
    #   - key: request.auth.claims[groups]
    #     values: ["admin"]
```

`requestPrincipals` = `iss/sub`.

Ingress: RequestAuthentication + AuthorizationPolicy **on the gateway selector**, namespace `istio-system`.

File: `24.md`.
