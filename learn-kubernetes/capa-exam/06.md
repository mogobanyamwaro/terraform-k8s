# 06. WorkflowTemplate and templateRef

**Domain:** Argo Workflows (36%) — Understand Argo Workflow Templates

## Concept Refresher

| Kind | Scope | Use |
| --- | --- | --- |
| `WorkflowTemplate` | Namespace | Library of workflows / templates |
| `ClusterWorkflowTemplate` | Cluster | Shared platform templates |

A **Workflow** can:

- Be submitted from a template: `argo submit --from workflowtemplate/foo`
- **Reference** a template with `templateRef`:

```yaml
- name: call-shared
  templateRef:
    name: data-etl
    template: main
    clusterScope: false
```

`templateRef.template` is the **entrypoint name inside** that WorkflowTemplate.

You can also set `workflowTemplateRef` on a Workflow to use the whole stored spec.

**Why it exists:** DRY, RBAC (who may update the library vs who may submit), GitOps of templates via Argo CD while runs stay Workflow objects.

Do not confuse with Argo CD **Application**. Do not confuse with Rollouts **AnalysisTemplate**.

## Question

**Q1.** A `WorkflowTemplate` is:

- A. An Argo CD Application
- B. A reusable Workflow definition stored in the cluster (namespace)
- C. An EventBus
- D. A canary step

**Q2.** `ClusterWorkflowTemplate` is:

- A. Namespace-only
- B. Cluster-scoped reusable workflow definition
- C. Only for Rollouts
- D. Only for Dex

**Q3.** `templateRef` points at:

- A. A Helm repo
- B. Another WorkflowTemplate’s named inner template
- C. An Ingress
- D. A Prometheus UI

**Q4.** `argo submit --from workflowtemplate/etl`:

- A. Deletes the template
- B. Creates a Workflow instance from that template
- C. Syncs Argo CD
- D. Creates an EventSource

**Q5.** Storing WorkflowTemplates in Git and syncing with Argo CD:

- A. Is illegal
- B. Is GitOps of **definitions**; runs are still Workflow CRs
- C. Makes Workflows become Rollouts
- D. Removes the controller

**Q6.** AnalysisTemplate is:

- A. The same CR as WorkflowTemplate
- B. A **Rollouts** reusable analysis spec, not a workflow
- C. An EventSource
- D. A CronWorkflow

**Q7.** `clusterScope: true` on templateRef means:

- A. Use a ClusterWorkflowTemplate
- B. Use Argo CD project default
- C. Use EventBus Kafka
- D. Use preview Service

**Q8.** Updating a WorkflowTemplate:

- A. Rewrites all historical Workflow CRs automatically
- B. Affects **new** submissions (and refs); old runs keep their spec
- C. Deletes etcd
- D. Forces canary 100%

**Q9.** Platform team publishes `ClusterWorkflowTemplate` `ci-build`; app teams submit Workflows that templateRef it. This is:

- A. Against CAPA
- B. The intended reuse/RBAC pattern
- C. Only possible with Events
- D. Only possible with Rollouts

**Q10.** Inner `templates:` in a WorkflowTemplate:

- A. Cannot include dag/steps
- B. Are the same kinds as in a Workflow (container, dag, …)
- C. Must be HTTP only
- D. Must be resource only

## Answers

**Q1.** B  
**Q2.** B  
**Q3.** B  
**Q4.** B  
**Q5.** B  
**Q6.** B  
**Q7.** A  
**Q8.** B  
**Q9.** B  
**Q10.** B

## Hands-on

Convert hello-world to a WorkflowTemplate, then `argo submit --from workflowtemplate/hello`.

## Exam tips

- **WorkflowTemplate** = stored definition. **Workflow** = run.
- **templateRef** = call library. **AnalysisTemplate** = Rollouts.
