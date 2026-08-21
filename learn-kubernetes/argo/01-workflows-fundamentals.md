# 01. Argo Workflows Fundamentals

**Domain:** Argo Workflows (36%)

## Concept Refresher

**Argo Workflows** is a Kubernetes-native **workflow engine**. A `Workflow` is a CRD. Each **template definition** usually runs as a **Pod** (container). Orchestration is declared in YAML, not in a Jenkinsfile on a VM.

**Components**

| Piece | Role |
| --- | --- |
| **Workflow controller** | Watches `Workflow` CRs and creates pods / manages status |
| **Argo server** | API + UI (`argo` CLI talks here or to the K8s API) |
| **Executor** (in the wait/main sidecar model) | Collects artifacts, handles outputs inside the workflow pod |

**Core objects**

| Kind | Role |
| --- | --- |
| `Workflow` | One run (like a Job, but a graph) |
| `WorkflowTemplate` | Reusable workflow definition **in a namespace** |
| `ClusterWorkflowTemplate` | Cluster-scoped reusable definition |
| `CronWorkflow` | Schedule that **spawns** Workflows |
| `WorkflowEventBinding` | Bind events to submit workflows (less common than Argo Events) |

**Mental model:** `spec.entrypoint` names the template that starts. `spec.templates` is the function library.

Use cases: CI on Kubernetes, ETL/ML pipelines, batch, infra automation (resource templates). **Not** GitOps CD (that is Argo CD).

## Question

**Q1.** Argo Workflows is primarily:

- A. A GitOps continuous delivery controller
- B. A Kubernetes-native workflow engine for container jobs
- C. A service mesh
- D. An Ingress controller

**Q2.** The controller’s job is to:

- A. Replace etcd
- B. Watch Workflow CRs and run the graph (pods, status)
- C. Clone Git for Argo CD Applications
- D. Shift canary traffic

**Q3.** A `Workflow` compared with a Kubernetes `Job`:

- A. They are identical CRDs
- B. A Workflow can orchestrate many templates (steps/DAG), not only one pod spec
- C. Jobs support DAGs natively
- D. Workflows cannot run containers

**Q4.** The first template that runs is named by:

- A. `spec.destination.server`
- B. `spec.entrypoint`
- C. `spec.syncPolicy`
- D. `metadata.finalizers`

**Q5.** Argo server provides:

- A. Only kube-proxy
- B. API and UI for workflows
- C. Only EventBus
- D. Only Helm rendering

**Q6.** ML/ETL pipelines of many container steps belong to:

- A. Argo CD only
- B. Argo Workflows
- C. Argo Rollouts only
- D. Hubble

**Q7.** `CronWorkflow` is:

- A. An Argo CD Application
- B. A scheduled factory that creates Workflows
- C. An EventBus
- D. A Rollout strategy

**Q8.** Workflows vs Argo CD:

- A. Workflows keep Git = cluster
- B. CD is GitOps; Workflows run jobs/pipelines
- C. They are the same CRD
- D. CD cannot exist without Workflows

**Q9.** Submitting `argo submit hello.yaml` creates:

- A. An Application
- B. A Workflow instance
- C. An EventSource
- D. An AnalysisRun

**Q10.** Each container template typically becomes:

- A. A Node in etcd only
- B. A Pod (plus workflow plumbing)
- C. An Ingress
- D. A Cilium identity

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

Submit the hello-world example from `lab-setup.md`. `argo list` / `kubectl get wf -n argo`.

## Exam tips

- **Workflow = one run.** Template = function. CronWorkflow = schedule.
- Controller ≠ Argo CD application-controller.
