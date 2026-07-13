# Mock Exam 2

Harder. 17 tasks, **120 minutes**. Several objects are **pre-broken**. If your lab is clean, apply the sabotage block first.

## Sabotage (run once)

```bash
kubectl create ns ica2
kubectl label ns ica2 istio-injection=enabled --overwrite
kubectl -n ica2 apply -f samples/httpbin/httpbin.yaml
kubectl -n ica2 apply -f samples/sleep/sleep.yaml

# Broken gateway selector
kubectl apply -f - <<'EOF'
apiVersion: networking.istio.io/v1
kind: Gateway
metadata: { name: ica2-gw, namespace: ica2 }
spec:
  selector: { istio: ingress }
  servers:
    - port: { number: 80, name: http, protocol: HTTP }
      hosts: ["ica2.example.com"]
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata: { name: ica2-httpbin, namespace: ica2 }
spec:
  hosts: ["www.ica2.example.com"]
  gateways: [ica2-gw]
  http:
    - route:
        - destination: { host: httpbin, subset: v9, port: { number: 8000 } }
EOF
```

---

## Tasks

### T1 — Fix ingress 404 (troubleshoot)

`curl -H "Host: ica2.example.com" http://$GATEWAY_URL/get` must return **200**. Repair Gateway and VirtualService. Do not install a second ingress Deployment.

### T2 — Missing subset (troubleshoot)

Whatever caused 503 NR on httpbin must be gone. Either define subsets properly or stop referencing them.

### T3 — Canary 90/10 (traffic)

Two versions of httpbin in `ica2` (`version=v1` and `version=v2`). 90% v1 / 10% v2 for all mesh traffic to `httpbin`.

### T4 — Mirror 50% (traffic)

Keep primary on v1. **Mirror 50%** to v2. Client responses must still come from v1.

### T5 — REGISTRY_ONLY + whitelist (traffic)

Make `ica2` `REGISTRY_ONLY` via Sidecar. Allow `httpbin.org:80` only among external HTTP hosts. `curl http://example.com` from sleep must fail. `http://httpbin.org/get` must work.

### T6 — Retries on 5xx (traffic)

VirtualService to httpbin: `attempts: 3`, `retryOn` includes `5xx`, `perTryTimeout: 2s`, overall `timeout: 10s`.

### T7 — Outlier detection (traffic)

Eject httpbin endpoints after **1** consecutive 5xx, interval **1s**, base **15s**, **100%** of pool may be ejected, `minHealthPercent: 0`.

### T8 — Locality (traffic)

If nodes have zone labels, enable locality LB on httpbin with outlier detection present. If your cluster is single-zone, still write a valid DestinationRule with `localityLbSetting.enabled: true` and a distribute or failover stanza plus outlierDetection.

### T9 — Deny path (security)

sleep may call httpbin except path `/delete` (or `/delete*`) which must be **403** even for sleep.

### T10 — Ingress JWT (security)

At the **ingress gateway**, require a valid JWT (same sample issuer as Mock 1) for host `ica2.example.com` only. Other hosts on the gateway must keep working (Bookinfo). This is the easy-to-brick task — do not default-deny the whole gateway without a second ALLOW rule for other hosts.

### T11 — MUTUAL optional skip

Configure **SIMPLE** TLS for `secure.ica2.example.com` (self-signed) on ingress. Document in comments why you did not use PASSTHROUGH.

### T12 — PeerAuthentication port exception

httpbin STRICT mTLS, but container port used by the Service (often 80 or 8000 — **check**) DISABLE so you can demonstrate portLevelMtls. If that would undo T9 testing from sleep (meshed), keep STRICT on that port and DISABLE an unused port instead — graders (you) should see the field present.

### T13 — Control plane (troubleshoot)

Show `istioctl version`, that istiod is Ready, and `verify-install` does not error on the components you care about. If verify-install complains about egress and you need it, enable egress.

### T14 — Response flags (troubleshoot)

Generate a UO 503 with a tiny connection pool (temporary). Capture a log line containing `UO`. Then restore pool limits so the app is usable.

### T15 — Ambient theory on sidecar cluster (install)

You cannot rebuild the cluster in 6 minutes. Write (in `/tmp/t15-ambient.txt`) the namespace label for ambient, the GatewayClass for a waypoint, and why a timeout VS would no-op without one. (On exam this would be a live ambient namespace.)

### T16 — Authorization default deny probes

ALLOW only GET `/get` on httpbin. Then **fix** readiness if the pod goes NotReady (allow probe paths or restore a broader rule). End state: pod Ready AND `/get` allowed AND `POST /post` 403.

### T17 — Cleanup analyze

`istioctl analyze -n ica2 -n bookinfo -n istio-system` should have no **errors** from your work (warnings OK).

---

## Solutions (short)

**T1:** selector `istio: ingressgateway`. VS hosts `ica2.example.com` (must intersect). Destination **without** bogus subset or with a real DR.

**T2:** part of T1.

**T3:** clone deploy with `version=v2`, Service selector `app=httpbin`, DR subsets, VS weights.

**T4:** `mirror` + `mirrorPercentage.value: 50`.

**T5:** Sidecar `outboundTrafficPolicy.mode: REGISTRY_ONLY` hosts `./*`, `istio-system/*` + ServiceEntry httpbin.org.

**T6–T8:** VS retries; DR outlier; DR localityLbSetting + outlier.

**T9:** ALLOW sleep principal + DENY paths `/delete*`.

**T10:** RequestAuthentication + AuthorizationPolicy on `istio: ingressgateway` with **two rules**: JWT for `ica2.example.com`, and a second ALLOW for other hosts (e.g. `notHosts` or explicit productpage host). This is the scoring trap.

**T11:** Gateway HTTPS SIMPLE credentialName in istio-system.

**T12:** `portLevelMtls` map keyed by **pod** port.

**T13:** inspection commands.

**T14:** DR maxConnections 1, parallel curl, logs, revert.

**T15:** `istio.io/dataplane-mode=ambient`, `istio-waypoint`, L4 ztunnel cannot enforce HTTP timeout.

**T16:** ALLOW GET `/get` plus ALLOW `/healthz` `/ready` or whatever probe path httpbin uses (`/status/200` etc.). httpbin sample probes `/` sometimes — `kubectl describe po`.

**T17:** analyze.

---

Grading: 6 pts each. T10 and T16 are the differentiators. If Bookinfo ingress died, T10 is incomplete even if ica2 JWT works.
