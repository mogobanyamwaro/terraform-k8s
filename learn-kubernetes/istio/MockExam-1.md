# Mock Exam 1

Timed **120 minutes**. 17 tasks. Work in one sitting. Do not peek at solutions.

Use your lab from `Lab-Setup.md`. Create namespaces the tasks name. If a namespace already has leftover policy, delete it first so scoring is fair.

**Rules (same as ICA):** docs on istio.io and kubernetes.io only. `istioctl analyze` is your friend. Partial credit is real — a working subset of the YAML still beats nothing.

**Suggested pacing:** ~6–7 minutes per task. Flag anything past 10 minutes.

---

## Tasks

### T1 — Install check and injection (install 20%)

Namespace `ica1` exists or you create it. Enrol it in **sidecar** mode so new pods get a proxy. Deploy `samples/httpbin/httpbin.yaml` and `samples/sleep/sleep.yaml` into `ica1`. Both must show **2/2**.

### T2 — Enable egress gateway (install)

Ensure an **egress gateway** is running in `istio-system` (the `default` profile does not). Do not break the existing ingress gateway.

### T3 — Ingress HTTP (traffic)

Expose `httpbin` in `ica1` on the mesh ingress Gateway so `Host: ica1.example.com` path `/get` returns 200. Bind a VirtualService correctly.

### T4 — Subsets and 80/20 (traffic)

In `bookinfo`, send **80%** of `reviews` traffic to subset `v1` and **20%** to `v2`. Subsets must be valid. Mesh-internal only is fine (no gateway required).

### T5 — Header match (traffic)

In `bookinfo`, user `end-user: jason` must go to `reviews` **v2**. Everyone else stays on the 80/20 split from T4 (or 100% v1 if you did not do T4).

### T6 — Timeout (traffic)

All mesh calls to `httpbin.ica1` must **timeout at 2s**. `curl http://httpbin:8000/delay/5` from sleep must fail with a gateway timeout.

### T7 — External service (traffic)

From `ica1/sleep`, `http://httpbin.org/get` must be a registered mesh service (ServiceEntry, DNS, MESH_EXTERNAL) with a **3s** timeout VirtualService.

### T8 — Circuit breaker (traffic)

DestinationRule on `httpbin.ica1`: `maxConnections: 1`, `http1MaxPendingRequests: 1`. Parallel delayed requests should produce at least one **503**.

### T9 — Fault abort (traffic)

Abort **100%** of `ratings.bookinfo` with HTTP **500**. productpage stars should error.

### T10 — STRICT mTLS (security)

Namespace `ica1` must **require** mTLS. A client **without** a sidecar must fail. `ica1/sleep` must still succeed.

### T11 — Authorization (security)

Only ServiceAccount of `sleep` in `ica1` may call `httpbin` (any method). Other meshed clients in `ica1` (if any) get 403. Do not use `namespaces: ["*"]`.

### T12 — JWT (security)

Validate JWTs on `httpbin` in `ica1` with issuer `testing@secure.istio.io` and the Istio sample `jwksUri`. **Require** a valid token. No token → not 200. Invalid token → 401.

### T13 — Edge TLS (security)

Terminate HTTPS for `ica1.example.com` on the ingress gateway using a Secret `ica1-tls` in the correct namespace. HTTP may redirect. TLS can be a self-signed cert.

### T14 — Analyze a broken VS (troubleshoot)

Someone applied a VirtualService in `bookinfo` named `broken-reviews` routing to subset `nope`. Find it, explain the failure mode, delete or repair it so `istioctl analyze -n bookinfo` is clean of that error.

### T15 — proxy-config (troubleshoot)

From `ica1/sleep`, show the outbound cluster name for `httpbin.ica1.svc.cluster.local` and confirm endpoints are non-empty. Save the cluster name in a comment on the task paper (lab: write it in `/tmp/t15.txt`).

### T16 — Access logs (troubleshoot)

Ensure Envoy **access logs** are enabled mesh-wide via Telemetry. Generate one request and show a log line on the sleep or httpbin proxy.

### T17 — Sidecar scope (install/traffic)

In `ica1`, a Sidecar named `default` must limit egress to `ica1/*` and `istio-system/*`. `proxy-status` for httpbin and sleep must remain healthy.

---

## Solutions and grading

Score **6 points** per task (102). Pass simulation **70+**.

### T1

```bash
kubectl create ns ica1
kubectl label ns ica1 istio-injection=enabled --overwrite
kubectl -n ica1 apply -f samples/httpbin/httpbin.yaml
kubectl -n ica1 apply -f samples/sleep/sleep.yaml
kubectl -n ica1 wait --for=condition=ready pod --all --timeout=180s
kubectl -n ica1 get po   # 2/2
```

**Grading:** ns labelled, pods 2/2. 3 pts if labelled but old pods not restarted.

### T2

```bash
istioctl install -y --set spec.components.egressGateways[0].name=istio-egressgateway \
  --set spec.components.egressGateways[0].enabled=true
kubectl -n istio-system get deploy istio-egressgateway
```

**Grading:** egress Deployment Ready, ingress still Ready.

### T3

Gateway selector `istio: ingressgateway`, hosts `ica1.example.com`, VS `gateways` + matching hosts, destination `httpbin:8000`.

```bash
curl -sS -o /dev/null -w "%{http_code}\n" -H "Host: ica1.example.com" http://$GATEWAY_URL/get
```

**Grading:** 200 through ingress. 0 if only ClusterIP works.

### T4–T5

DestinationRule subsets v1/v2 (Bookinfo sample DR). VS weights 80/20, jason match **above** the weighted route.

### T6

VS `hosts: [httpbin]` in `ica1`, `timeout: 2s`. Verify `/delay/5` → 504.

### T7

ServiceEntry `httpbin.org` port 80 HTTP DNS MESH_EXTERNAL + VS timeout 3s.

### T8

DR connectionPool as specified. Two `/delay/3` in parallel → one 503 UO.

### T9

VS ratings fault abort 100% httpStatus 500, still include `route.destination`.

### T10

PeerAuthentication `default` in `ica1`, `STRICT`. Test nomesh vs ica1 sleep.

### T11

ALLOW AuthorizationPolicy selector httpbin, `principals: ["cluster.local/ns/ica1/sa/<sleep-sa>"]`. Confirm SA with kubectl.

### T12

RequestAuthentication jwtRules issuer + jwksUri. AuthorizationPolicy ALLOW `requestPrincipals: ["*"]`.

jwks: `https://raw.githubusercontent.com/istio/istio/release-1.26/security/tools/jwt/samples/jwks.json`

### T13

`kubectl -n istio-system create secret tls ica1-tls --cert=... --key=...`  
Gateway port 443 SIMPLE `credentialName: ica1-tls`. VS http route same host.

### T14

```bash
istioctl analyze -n bookinfo
kubectl -n bookinfo delete vs broken-reviews
# or add subset nope (wrong) / retarget v1
```

### T15

```bash
istioctl pc c deploy/sleep.ica1 --fqdn httpbin.ica1.svc.cluster.local
istioctl pc ep deploy/sleep.ica1 --cluster "outbound|8000||httpbin.ica1.svc.cluster.local"
```

### T16

Telemetry in `istio-system` `accessLogging.providers.name: envoy`. `kubectl logs -c istio-proxy`.

### T17

Sidecar `default` in `ica1` with those hosts. `istioctl ps | grep ica1` SYNCED.

---

## Review

| Missed | Study |
| --- | --- |
| T1 T2 T17 | `02.md` `04.md` `16.md` |
| T3 T13 | `08.md` `27.md` |
| T4 T5 T9 | `12.md` `10.md` `20.md` |
| T6 T8 | `18.md` `19.md` |
| T7 | `14.md` |
| T10–T12 | `23.md` `24.md` `25.md` |
| T14–T16 | `29.md` `31.md` `34.md` |
