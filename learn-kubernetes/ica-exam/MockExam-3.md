# Mock Exam 3

Closest to exam phrasing: terse, no sabotage story. **120 minutes**, 17 tasks. Full objective spread.

Assume Bookinfo, `demo` (httpbin+sleep), and ingress are installed as in `Lab-Setup.md`. Create extra namespaces when named.

---

## Tasks

1. Label namespace `exam3` for sidecar injection and deploy sleep + httpbin from samples there. Pods must be Ready with sidecars.

2. Install or confirm Istio **revision** listing. Create revision tag `stable` pointing at the currently installed revision (or `default`). Label `exam3` to use tag `stable` without breaking injection.

3. Create Gateway + VirtualService so `exam3.example.com` `/status/200` returns 200 via ingress.

4. Shift `reviews` in `bookinfo` to **100% v1**.

5. For `reviews`, send traffic with header `x-canary: true` to **v2**, all other traffic **v1**.

6. Apply a **3s** timeout and **2** retries on `5xx` for `httpbin` in `exam3`.

7. Fault: **delay 2s** for 100% of requests to `httpbin.exam3` path prefix `/delay`. Do not delay `/get`.

8. Register `www.httpbin.org` (or `httpbin.org`) as MESH_EXTERNAL DNS HTTP port 80. From exam3 sleep, curl it successfully.

9. DestinationRule for `httpbin.exam3`: ROUND_ROBIN, `maxConnections: 50`, outlier consecutive5xx 5, interval 10s, base 30s.

10. PeerAuthentication STRICT for namespace `exam3`.

11. AuthorizationPolicy: allow only GET from principal of `exam3` sleep to httpbin paths `/get` and `/status/*`.

12. RequestAuthentication on httpbin in exam3 for issuer `testing@secure.istio.io` (sample jwks). Do **not** require tokens yet. Prove invalid Bearer → 401 and missing token → 200. Then add the AuthorizationPolicy so missing token → 403.

13. Create TLS Secret `exam3-tls` in the gateway namespace and terminate SIMPLE TLS for `exam3.example.com`.

14. `istioctl analyze -A` must not report an error you introduced. Fix any you find.

15. Using `istioctl proxy-status`, confirm exam3 proxies SYNCED. Using `proxy-config endpoint`, show httpbin endpoints from sleep.

16. Enable access logging with a Telemetry resource if logs are empty on `istio-proxy`.

17. Create a Sidecar in `exam3` limiting egress to `./*` and `istio-system/*`. Confirm you can still curl httpbin (in-namespace) and that `proxy-status` stays SYNCED.

---

## Solutions

### 1

```bash
kubectl create ns exam3
kubectl label ns exam3 istio-injection=enabled
kubectl -n exam3 apply -f samples/httpbin/httpbin.yaml
kubectl -n exam3 apply -f samples/sleep/sleep.yaml
```

### 2

```bash
istioctl tag list
istioctl tag set stable --revision default
# or the rev string from: kubectl -n istio-system get po -l app=istiod --show-labels
kubectl label ns exam3 istio.io/rev=stable --overwrite
kubectl label ns exam3 istio-injection-
kubectl -n exam3 rollout restart deploy
```

If tag set fails because revision is empty, use the actual `istio.io/rev` on istiod pods.

### 3

Standard Gateway `selector: istio: ingressgateway` + VS hosts/gateways/destination port 8000.

### 4–5

DestinationRule reviews subsets exist (sample). VS: match header then catch-all v1. Task 4 is the catch-all; task 5 adds the match **first**.

### 6

```yaml
      timeout: 3s
      retries:
        attempts: 2
        retryOn: "5xx,connect-failure"
```

### 7

Two http rules: match `uri.prefix: /delay` with fault delay 2s; catch-all no fault.

### 8

ServiceEntry hosts must be the **same string you curl**.

### 9

DR `loadBalancer.simple: ROUND_ROBIN` + connectionPool + outlierDetection. Do not put this on a subset-only policy unless you intend replace semantics.

### 10

PA default in exam3 STRICT.

### 11

ALLOW with principal `cluster.local/ns/exam3/sa/<sleep-sa>` and operations GET paths. This default-denies POST.

### 12

RA first; test 401 vs 200; then ALLOW requestPrincipals `["*"]`. Combined with T11 you must **merge rules** (JWT and sleep GET) or T11+T12 fight.

**Exam trap:** two ALLOW policies are OR. sleep GET without JWT still matches T11. To require **both** JWT and sleep+GET, put JWT `requestPrincipals` and GET paths **in the same rule** (AND). Final T12 should update T11's rule rather than add a second policy blindly.

Correct combined rule:

```yaml
  rules:
    - from:
        - source:
            principals: ["cluster.local/ns/exam3/sa/sleep"]
            requestPrincipals: ["*"]
      to:
        - operation:
            methods: ["GET"]
            paths: ["/get", "/status/*"]
```

### 13

Secret in `istio-system`. Gateway 443 SIMPLE. Keep port 80 if task 3 still needs HTTP, or redirect.

### 14–17

analyze; ps; pc ep; Telemetry envoy; Sidecar with istiod host.

---

## Grading

17 × 6 = 102. Combined authn/authz on T11+T12 is the pass/fail edge. If you left two ALLOW policies, JWT is optional and T12's "403 without token" **fails**.

## After this exam

If you score **< 70**, redo `25.md` `24.md` `08.md` `11.md` and `35.md` drills 1–5, 18.  
If **70–85**, drill egress (`15.md`) and ambient (`36.md`).  
If **> 85**, run Mock 2 under the clock and stop studying YAML — practise speed and `analyze`.
