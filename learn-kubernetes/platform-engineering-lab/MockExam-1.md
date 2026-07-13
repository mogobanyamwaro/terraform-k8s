# Mock Exam 1

Timed **120 minutes**. 17 tasks. One sitting. Docs: kubernetes.io + imagine Quick Reference for Argo/Flux/Kyverno/Tekton.

Pass simulation: **64%**. Partial credit. ~7 minutes each. Flag at 8.

Use namespaces the tasks name. Solutions at the end.

---

### T1 — Tenancy (architecture)

Namespace `m1-tenant`: ResourceQuota requests.cpu=1 requests.memory=1Gi pods=10. LimitRange default request 50m/64Mi. PSS enforce restricted.

### T2 — NetworkPolicy

In `m1-net`: default deny both directions; allow `app=web` → `app=cache` TCP 6379; allow DNS.

### T3 — Right-size

Deployment `m1-waste` in `m1-cost` requests cpu=4. Set requests 100m/128Mi, limits 200m/256Mi. Annotate namespace `cost-center=platform`.

### T4 — Flux

GitRepository + Kustomization for podinfo into `m1-flux` (see `05.md`). prune true.

### T5 — Argo CD

Application `m1-gb` guestbook, dest `m1-argo`, auto prune+selfHeal, CreateNamespace.

### T6 — Tekton

Pipeline two echo tasks sequential. PipelineRun Succeeded in `m1-ci`.

### T7 — Canary

Rollout `m1-shop` in `m1-canary`, setWeight 10 then pause 15s then 100%. Two Services.

### T8 — CRD

CRD `widgets.platform.example.com` kind Widget, spec.color string required. Create `red` in `m1-api`.

### T9 — Self-service

Namespace `ws-red` + admin RoleBinding for user `dev@example.com` (simulate controller).

### T10 — cert-manager

Issuer selfSigned + Certificate secret `m1-tls` in `m1-op`.

### T11 — ServiceMonitor

ServiceMonitor for `app=api` port name `http`, matching Prometheus labels, ns `m1-obs`.

### T12 — Alert

PrometheusRule `M1HighRestarts` on `increase(kube_pod_container_status_restarts_total[5m]) > 3`.

### T13 — Incident

Fix ImagePullBackOff on `m1-fix/deploy/web` (set nginx:1.27). If GitOps selfHeal, fix the Application source instead.

### T14 — Kyverno

Enforce runAsNonRoot on Pods in `m1-pol`.

### T15 — RBAC

Group `devs` can create Widgets in `m1-api` only. No cluster-admin.

### T16 — Pipeline scan

Tekton Task that runs `trivy` or `false` with comment if no scanner — wire `runAfter` build.

### T17 — HPA + PDB

On `m1-cost/m1-waste` after T3: HPA CPU 70% min 1 max 4. PDB minAvailable 1.

---

## Solutions (peek after)

T1 `04.md` · T2 `01.md` · T3 `03.md` · T4 `05.md` · T5 `06.md` · T6 `07.md` · T7 `08.md` · T8 `11.md` · T9 `12.md` · T10 `14.md` · T11–T12 `17.md` · T13 `19.md` · T14 `25.md` · T15 `23.md` · T16 `26.md` · T17 `02.md`/`20.md`
