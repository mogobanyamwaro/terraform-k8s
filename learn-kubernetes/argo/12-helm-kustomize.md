# 12. Helm and Kustomize

**Domain:** Argo CD (34%) — Configure Argo CD with Helm and Kustomize

## Concept Refresher

Repo-server detects (or you declare) a **config management tool**.

**Directory** of YAML: `path:` only.

**Kustomize:** `path:` to a kustomization. Optional:

```yaml
source:
  path: overlays/prod
  kustomize:
    images:
    - ghcr.io/org/app=ghcr.io/org/app:1.2.3
```

**Helm:**

```yaml
source:
  repoURL: https://github.com/org/charts   # or Helm repo URL
  chart: myapp          # when using Helm repo
  targetRevision: 1.2.3 # chart version or Git ref
  helm:
    valueFiles:
    - values-prod.yaml
    parameters:
    - name: image.tag
      value: "1.2.3"
    values: |
      replicaCount: 3
    releaseName: myapp
```

Git repo containing a chart: `path:` to chart dir, `helm.valueFiles`.

Pin **chart version** and **image tag/digest**. `:latest` is a GitOps smell (CGOA overlap, still asked).

**Helm + Kustomize:** Helm inflator in kustomization, or multiple sources.

Jsonnet and **config management plugins** exist; know they are extra renderers on repo-server.

`helm template` vs live Helm: Argo CD typically **renders and applies** (it is not `helm install` as a long-lived Helm release unless you use the Helm renderer that way — exam: Argo CD **manages the objects**, Git is source).

## Question

**Q1.** Kustomize in an Application is usually:

- A. An EventBus
- B. A `path` to a directory with `kustomization.yaml`
- C. A Rollout pause
- D. A CronWorkflow

**Q2.** Helm `targetRevision: 1.4.0` with `chart:`:

- A. A Git branch named 1.4.0 always
- B. The **chart version** when using a Helm repo
- C. An AnalysisRun name
- D. An EventSource

**Q3.** `helm.valueFiles`:

- A. Kubernetes Secrets only
- B. Values files inside the source (Git path or chart)
- C. EventBus config
- D. Dex connectors

**Q4.** Repo-server’s job with Helm:

- A. Run canary analysis
- B. Render templates to manifests
- C. Host Git
- D. Host MinIO

**Q5.** Pinning `image.tag` in Helm parameters:

- A. Breaks GitOps
- B. Makes desired state a specific artifact
- C. Requires Events
- D. Requires Rollouts

**Q6.** A Git repo of raw YAML with no kustomization/chart:

- A. Cannot be an Application
- B. Directory source
- C. Must be Kafka
- D. Must be a Workflow

**Q7.** `:latest` as the declared tag:

- A. Best for rollback
- B. Weak immutability; live may change without a Git change
- C. Required by Kustomize
- D. Required by Helm

**Q8.** Overlay `overlays/prod` is typically:

- A. EventSource
- B. Kustomize (or Helm values-prod) selected by `path` / valueFiles
- C. DAG entrypoint
- D. previewService

**Q9.** Config management plugin:

- A. Replaces Kubernetes
- B. Lets repo-server render other tools (cdk8s, jsonnet variants, …)
- C. Is ApplicationSet
- D. Is EventBus

**Q10.** Helm chart from OCI:

- A. Illegal for Argo CD
- B. Supported as an Application source type in current Argo CD
- C. Only for Workflows artifacts
- D. Only for Events

## Answers

**Q1.** B  
**Q2.** B  
**Q3.** B  
**Q4.** B  
**Q5.** B  
**Q6.** B  
**Q7.** B  
**Q8.** B  
**Q9.** B  
**Q10.** B

## Hands-on

Point an Application at a Helm guestbook or kustomize overlay. Change a value, sync, confirm render.

## Exam tips

- **path = Git directory. chart + repoURL = Helm repo.**
- repo-server **renders**; controller **applies**.
- Pin versions.
