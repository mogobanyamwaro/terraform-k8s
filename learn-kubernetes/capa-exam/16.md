# 16. Argo Rollouts Fundamentals

**Domain:** Argo Rollouts (18%)

## Concept Refresher

**Argo Rollouts** is a Kubernetes **controller + CRDs** for **progressive delivery**. The main CR is `Rollout`. It is a **drop-in replacement for Deployment** when you need blue-green, canary, experiments, or analysis — not a GitOps engine.

A Rollout still has `spec.template` (pod spec) and `replicas`. The difference is `spec.strategy.canary` or `spec.strategy.blueGreen`.

**Traffic:** often a pair of Services (stable/canary or active/preview) plus optional mesh/Ingress (Istio, NGINX, ALB, SMI, …).

**With Argo CD:** Git contains the Rollout YAML; CD syncs it; **Rollouts controller** executes steps. CD health can understand Rollout if custom health is configured.

**Objects:** `Rollout`, `Experiment`, `AnalysisTemplate`, `ClusterAnalysisTemplate`, `AnalysisRun`.

CLI: `kubectl argo rollouts get rollout … --watch`, `promote`, `abort`, `undo`.

## Question

**Q1.** Argo Rollouts is primarily:

- A. Git clone and Helm render
- B. Progressive delivery (blue-green, canary, analysis)
- C. EventBus transport
- D. Workflow DAG scheduling

**Q2.** A `Rollout` compared with a `Deployment`:

- A. Identical strategy field always
- B. Adds blueGreen/canary strategies beyond rollingUpdate
- C. Cannot run pods
- D. Replaces Git

**Q3.** Who shifts canary weight?

- A. Argo CD repo-server
- B. Rollouts controller (plus traffic provider)
- C. Workflow controller only
- D. Dex

**Q4.** Argo CD’s role with a Rollout in Git:

- A. It implements Istio VirtualService weights itself
- B. It syncs the Rollout object; Rollouts runs the strategy
- C. It is unused
- D. It must be uninstalled

**Q5.** `kubectl argo rollouts abort`:

- A. Deletes Git
- B. Stops the progressive update (typically back toward stable)
- C. Creates EventBus
- D. Prunes Applications

**Q6.** Traffic splitting often needs:

- A. Only etcd snapshots
- B. Extra Services and/or a service mesh/Ingress plugin
- C. Only CronWorkflow
- D. Only AppProject

**Q7.** Experiment CR is for:

- A. Git webhook
- B. Running one or more versions (A/B-style) for analysis
- C. EventSource
- D. Dex SSO

**Q8.** Installing Rollouts without Argo CD:

- A. Illegal
- B. Valid; you can kubectl/GitOps-with-Flux the Rollout
- C. Required to use Workflows
- D. Required to use Events

**Q9.** Rollouts does **not** replace:

- A. Deployment progressive strategies
- B. Argo CD GitOps reconciliation of arbitrary apps
- C. Canary steps
- D. Blue-green switch

**Q10.** Dashboard/plugin `get rollout --watch` shows:

- A. Only Git commits
- B. Replica sets, steps, weights, analysis
- C. Only EventBus lag
- D. Only Helm hooks

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

Install Rollouts. Apply a sample canary Rollout from the official examples. `kubectl argo rollouts get rollout --watch`.

## Exam tips

- **Rollout ≈ Deployment + progressive strategy.**
- **CD syncs YAML. Rollouts moves traffic.**
