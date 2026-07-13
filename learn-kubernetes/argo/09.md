# 09. Argo CD Fundamentals

**Domain:** Argo CD (34%)

## Concept Refresher

**Argo CD** is a declarative **GitOps continuous delivery** tool for Kubernetes. Git (or Helm/OCI) holds **desired state**. Argo CD **pulls**, **diffs** live vs desired, and **syncs**. Drift → `OutOfSync`.

**Components**

| Component | Role |
| --- | --- |
| **API server** (`argocd-server`) | UI, CLI, API, authz |
| **Repository server** (`argocd-repo-server`) | Clone Git/Helm/OCI, **render** manifests (Helm, Kustomize, jsonnet, directory, plugin) |
| **Application controller** | Compare live vs desired, sync, health, status |
| **ApplicationSet controller** | Generates Applications |
| **Redis** | Cache (manifests, etc.) |
| **Dex** (optional) | SSO |

Applications live as CRs, usually in namespace `argocd` (or the apps namespace if configured).

Default **refresh/reconcile** is on the order of **3 minutes** unless a webhook notifies sooner.

**Not** a workflow engine. **Not** progressive delivery (Rollouts). **Not** an event bus.

## Question

**Q1.** Argo CD’s primary job is:

- A. Running ETL DAGs
- B. GitOps: make the cluster match Git desired state
- C. Shifting canary weight by itself without a Rollout
- D. Consuming Kafka as EventBus

**Q2.** The repo-server:

- A. Applies canary AnalysisRuns
- B. Fetches Git/Helm/OCI and generates manifests
- C. Is the EventBus
- D. Is kube-proxy

**Q3.** The application-controller:

- A. Only serves the UI
- B. Reconciles Applications (diff, sync, health)
- C. Only runs Dex
- D. Only stores artifacts in MinIO

**Q4.** API server is used by:

- A. Only Cilium
- B. UI and `argocd` CLI
- C. Only Workflow executors
- D. Only Kafka

**Q5.** Desired vs live differ. Argo CD marks the app:

- A. Healthy always
- B. OutOfSync (sync status)
- C. Synced always
- D. Suspended always

**Q6.** Dex in a typical install:

- A. Renders Helm
- B. Optional SSO
- C. Is the Git repo
- D. Is Rollouts traffic

**Q7.** Argo CD vs Workflows:

- A. Identical
- B. CD delivers apps from Git; Workflows run job graphs
- C. Workflows prune Applications
- D. CD requires DAGs

**Q8.** Redis in Argo CD:

- A. Is the GitOps state store
- B. Caches (e.g. generated manifests)
- C. Is EventBus JetStream
- D. Is Prometheus

**Q9.** Refresh is often:

- A. Only once ever
- B. Periodic (about 3 minutes) plus optional Git webhook
- C. Only via CronWorkflow
- D. Only via AnalysisRun

**Q10.** Git as source of truth for Deployments is:

- A. Argo Events
- B. Argo CD
- C. Only Workflows resource templates
- D. Hubble

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

Port-forward `argocd-server`. `kubectl get applications -n argocd`. Identify repo-server vs application-controller pods.

## Exam tips

- **repo-server = generate YAML. controller = reconcile cluster.**
- OutOfSync ≠ Unhealthy (different status axes).
