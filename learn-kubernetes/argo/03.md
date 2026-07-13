# 03. Template Definitions

**Domain:** Argo Workflows (36%) — Understand Argo Workflow Templates

## Concept Refresher

Two layers of the word **template**:

1. **`spec.templates[]` entries** (lowercase “template”) — functions inside a Workflow.
2. **`WorkflowTemplate` CR** — a whole workflow definition stored in the cluster.

This file is (1). Types split into **definitions** (do work) and **invocators** (call others).

**Definitions (do work)**

| Type | Does |
| --- | --- |
| **container** | Run a container (most common) |
| **script** | Like container, but you inline `source:` (python/bash) and stdout can become a result |
| **resource** | `kubectl`-style create/get/delete/apply/replace/patch a Kubernetes object; can succeed on a condition |
| **suspend** | Pause until a duration **or** manual resume (`argo resume`) |
| **containerSet** | Multiple containers in **one pod** |
| **http** | HTTP request from the workflow |
| **plugin** | Plugin executor (e.g. notifications) |

**Invocators** (next files): **steps**, **dag**.

A template has `name`, optional `inputs`/`outputs`, and **exactly one** of the type fields.

## Question

**Q1.** A `container` template:

- A. Shifts canary weight
- B. Runs a container image as a workflow step
- C. Is Argo CD repo-server
- D. Is EventBus

**Q2.** A `script` template is best when:

- A. You need GitOps prune
- B. You want inline source (python/sh) whose result can be captured
- C. You need blue-green
- D. You need an EventSource

**Q3.** A `resource` template:

- A. Only builds Docker images
- B. Creates/updates/deletes Kubernetes API objects from the workflow
- C. Is a PVC
- D. Is Dex SSO

**Q4.** `suspend` is for:

- A. Deleting Git
- B. Pausing the workflow for a duration or until resume
- C. Always failing the DAG
- D. Helm rendering

**Q5.** `containerSet` runs:

- A. One container per cluster
- B. Multiple containers in a single pod
- C. Only on Windows nodes
- D. Only AnalysisRuns

**Q6.** An HTTP template:

- A. Replaces Ingress
- B. Performs an HTTP call as a step
- C. Is Argo CD Application health
- D. Is Flux

**Q7.** Template **invocators** are:

- A. container and script
- B. steps and dag
- C. only resource
- D. only http

**Q8.** Each template should have:

- A. Five type fields at once
- B. One implementation type (container *or* script *or* …)
- C. An Argo CD destination
- D. A Rollout strategy

**Q9.** Manual approval in a pipeline is typically:

- A. `setWeight`
- B. `suspend` then `argo resume`
- C. `prune: true`
- D. EventBus JetStream

**Q10.** `WorkflowTemplate` (the CR) vs `templates:` in a Workflow:

- A. Identical words, identical objects
- B. The CR is a stored workflow definition; `templates:` are steps/functions inside a spec
- C. The CR is only for Rollouts
- D. `templates:` is only for Events

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

Write a Workflow with a `script` python step that prints a number, then a `suspend` of `5s`.

## Exam tips

- **container / script / resource / suspend / http / containerSet** = definitions.
- **steps / dag** = invocators.
- Capital **WorkflowTemplate** ≠ lowercase **template**.
