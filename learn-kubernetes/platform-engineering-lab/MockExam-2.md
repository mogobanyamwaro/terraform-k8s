# Mock Exam 2

Harder. **120 minutes**, 17 tasks. Mix GitOps-owned objects (selfHeal will fight live kubectl).

---

### T1 — Quota + NetworkPolicy together

`m2-a`: quota 2 CPU / 2Gi. Deny ingress except from `app=gw` to `app=api` port 8080. DNS egress allowed.

### T2 — StorageClass + PVC + deploy

`m2-vol`: PVC 1Gi RWO WaitForFirstConsumer class (create or reuse). Deploy 1 replica mount `/var/lib/data`.

### T3 — OpenCost labels

Label all of `m2-*` you create with `opencost=true`. Right-size any pod requesting >1 CPU with <10m usage.

### T4 — Flux HelmRelease

If Helm controller present: HelmRelease `m2-podinfo` chart podinfo, values replicaCount=2. Else skip to Kustomization of YAML.

### T5 — Argo Helm parameters

Application `m2-helm` with `helm.parameters` replicaCount=2, dest `m2-helm`.

### T6 — Blue-green

Rollout `m2-api` autoPromotionEnabled false, active/preview Services. Promote once.

### T7 — Tekton git-clone shape

Pipeline params `repo-url`. First task echoes the URL; second echoes `ok`. PipelineRun passes the param.

### T8 — XRD-shaped CRD

CRD `teams.idp.example.com` spec.displayName + spec.quota.cpu. Instance `payments` quota.cpu=2.

### T9 — ApplicationSet list

Two apps `m2-x` `m2-y` guestbook namespaces `m2-x` `m2-y`.

### T10 — Crossplane Claim

If Crossplane present: Claim as in `13.md`. Else create ConfigMap `claim-shop` documenting the YAML you would apply (only if the cluster has no Crossplane — real exam will).

### T11 — OTel env

Deploy `m2-web` with `OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector.observability:4317`.

### T12 — GitOps repair

Break then fix a Kustomization/Application path so `m2-fix` has a Ready deploy.

### T13 — STRICT mTLS **or** NP

If Istio: PeerAuthentication STRICT + AuthorizationPolicy. Else NetworkPolicy default deny + allow listed apps.

### T14 — Controller ClusterRole

SA `m2-ctrl` can patch `teams/status` and create namespaces. Group `idp-users` can only create Teams, not namespaces.

### T15 — Disallow latest

Kyverno deny `*:latest` in `m2-pol`. Enforce.

### T16 — SBOM annotation required

Kyverno require annotation on Deployments in `m2-pol`.

### T17 — PDB during canary

PDB on the Rollout’s pods `minAvailable: 1` so a canary cannot evict everything.

---

## Solutions

T1 `01`+`04` · T2 `02` · T3 `03` · T4–T5 `05`/`06`/`15` · T6 `09` · T7 `07` · T8 `11` · T9 `16` · T10 `13` · T11 `18` · T12 `21` · T13 `22` · T14 `23` · T15–T16 `24`/`25` · T17 `08`+`20`
