# ICA Pitfalls

These look successful (`kubectl apply` OK) and still score zero.

1. **Undefined subset** — VS `subset: v2`, no DR. 503 NR. Analyze catches it; apply does not.
2. **VS not bound to Gateway** — default `mesh`. Ingress 404.
3. **Host mismatch** — Gateway `shop.example.com`, VS `www.shop.example.com`. No attach.
4. **Gateway selector** — `istio: ingress` vs `ingressgateway`. Listeners never appear.
5. **Secret in wrong ns** — `credentialName` must exist where **ingress pods** run.
6. **PASSTHROUGH with `http:`** — need `tls:` + `sniHosts`.
7. **`httpsRedirect` on 443** — belongs on the HTTP server.
8. **Port name `web`** — HTTP routing/authz paths silently skip. Use `http`.
9. **Short host wrong ns** — `host: reviews` in `default` is not `reviews.bookinfo`.
10. **Subset trafficPolicy replace** — loses parent connectionPool.
11. **Weights without both subsets** — 20% 503.
12. **Mirror vs shift** — users still hit primary; logs on shadow only.
13. **timeout < delay fault** — 504, no upstream.
14. **Default retries ≠ 5xx** — must set `retryOn: 5xx`.
15. **`attempts: 3` = 3 retries** (4 tries).
16. **Pool `maxEjectionPercent: 10`** on 2 pods — never ejects. Use 100.
17. **Failover without outlierDetection** — no-op.
18. **ALLOW_ANY hides missing ServiceEntry** — task wanted REGISTRY_ONLY.
19. **Egress recipe missing hop** — empty egress logs.
20. **Sidecar without `istio-system/*`** — STALE, dying certs.
21. **Sidecar name not `default` and no selector** — ignored.
22. **PERMISSIVE "enables mTLS"** — plaintext still works. Need STRICT.
23. **DR tls vs PA mismatch** — 503 UF.
24. **JWT RA only** — missing token still 200.
25. **Invalid JWT vs missing** — 401 vs 403.
26. **ALLOW on client** — authz is inbound on the server.
27. **First ALLOW default deny** — probes 403, pod not Ready.
28. **Policy in istio-system without selector** — bricks gateway.
29. **`principals` without mTLS** — never matches.
30. **Injection not restarted** — 1/1 pods.
31. **`istio-injection` + stale `istio.io/rev`** — no sidecar.
32. **In-place vs canary** — canary must restart workloads to move data plane.
33. **Ambient VS timeout** — no waypoint, no effect.
34. **`pc` on ambient app pod** — no Envoy. Use ztunnel/waypoint.
35. **Wrong context / namespace** — perfect YAML, zero points.
36. **Protocol HTTPS + app already TLS + SIMPLE** — double TLS.
37. **exportTo `.`** — other ns cannot use the VS/SE.
38. **`percentage: 100` old field** — use `percentage.value`.
39. **Authorization path `/api*` vs `/api/*`**.
40. **Forgetting `istioctl analyze`** after a pile of YAML.

Pre-submit:

```bash
istioctl analyze -A
istioctl proxy-status | grep -v SYNCED || true
```
