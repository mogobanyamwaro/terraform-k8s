# Argo Workflows (Deep Dive)

Largest CAPA domain (**36%**). Official docs: [argo-workflows.readthedocs.io](https://argo-workflows.readthedocs.io/).

## Objects

| Kind | One line |
| --- | --- |
| Workflow | A **run** |
| WorkflowTemplate | Namespaced **library** |
| ClusterWorkflowTemplate | Cluster **library** |
| CronWorkflow | **Schedule** → Workflows |
| template (lowercase) | Function inside `spec.templates` |

## Spec skeleton

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
spec:
  entrypoint: main
  arguments:
    parameters: [{name: name, value: world}]
  templates:
  - name: main
    dag: { tasks: [...] }   # or steps:
  - name: echo
    container:
      image: busybox
      command: [echo]
      args: ["{{inputs.parameters.name}}"]
    inputs:
      parameters: [{name: name}]
```

## Template types

**Definitions:** container, script, resource, suspend, containerSet, http, plugin  
**Invocators:** steps, dag

## steps vs dag

- steps: outer = sequence, inner = parallel; `{{steps.x.outputs...}}`
- dag: `dependencies: []`; `{{tasks.x.outputs...}}`; `failFast`

## Passing data

| Kind | Use |
| --- | --- |
| parameters | Small values / JSON |
| artifacts | Files; S3/MinIO/GCS/…; default tar.gz |
| PVC | Shared disk for a run |

## Reliability

`retryStrategy`, `activeDeadlineSeconds`, `parallelism`, `onExit`, `ttlStrategy`, `podGC`

Cron: `schedules`, `timezone`, `concurrencyPolicy` Allow|Forbid|Replace

## CLI

`argo submit`, `list`, `get`, `logs`, `watch`, `retry`, `resume`, `stop`, `delete`, `submit --from workflowtemplate/x`

## Not Workflows

GitOps of Deployments → CD. Canary → Rollouts. S3 put trigger → Events.
