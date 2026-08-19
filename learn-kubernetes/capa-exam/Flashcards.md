# Flashcards

Cover the right column. Night before and morning of.

## Meta

| Prompt | Answer |
| --- | --- |
| Format | Closed-book **MCQ**, 60 / 90 min / **75%** |
| Largest domain | **Workflows 36%** |
| Second | **Argo CD 34%** |
| Rollouts / Events | **18% / 12%** |

## Which tool

| Prompt | Answer |
| --- | --- |
| Git desired state | **Argo CD** |
| ETL/ML/CI DAG | **Workflows** |
| Canary + Prometheus abort | **Rollouts** |
| S3 put → start job | **Events** (+ Workflows) |
| Nightly workflow only | **CronWorkflow** |

## Workflows

| Prompt | Answer |
| --- | --- |
| Start template | **`spec.entrypoint`** |
| Do-work types | container, script, resource, suspend, containerSet, http |
| Invocators | **steps**, **dag** |
| Inner steps list | **Parallel** |
| Outer steps list | **Sequence** |
| DAG wait | **`dependencies`** |
| DAG outputs | **`{{tasks.x}}`** |
| Steps outputs | **`{{steps.x}}`** |
| Stored definition | **WorkflowTemplate** |
| One execution | **Workflow** |
| Schedule | **CronWorkflow** |
| Small values | **parameters** |
| Files | **artifacts** |
| Always at end | **`onExit`** |
| Fan-out JSON | **`withParam`** |
| Limit pods | **`parallelism`** |
| Pause for approval | **`suspend`** + resume |

## Argo CD

| Prompt | Answer |
| --- | --- |
| Renders manifests | **repo-server** |
| Reconciles apps | **application-controller** |
| UI/CLI | **argocd-server** |
| SSO optional | **Dex** |
| Cache | **Redis** |
| Git vs live mismatch | **OutOfSync** |
| Runtime bad | **Degraded** (health) |
| Revert kubectl | **selfHeal** |
| Delete gone Git objects | **prune** |
| Default wave | **0** (lower first) |
| Before apply Job | **PreSync** |
| Factory of Applications | **ApplicationSet** |
| Git list of Applications | **App-of-Apps** |
| Guardrails | **AppProject** |
| Refresh cadence | ~**3 minutes** + webhook |

## Rollouts

| Prompt | Answer |
| --- | --- |
| CR instead of Deployment | **Rollout** |
| Users until switch | **activeService** |
| Test new colour | **previewService** |
| Gradual % | **`setWeight`** |
| Wait forever | **`pause: {}`** |
| Reusable metrics spec | **AnalysisTemplate** |
| One metrics execution | **AnalysisRun** |
| Bad metrics | **abort** |
| Continue paused | **promote** |

## Events

| Prompt | Answer |
| --- | --- |
| Ingest | **EventSource** |
| Transport | **EventBus** |
| Decide + fire | **Sensor** |
| Action | **Trigger** (on Sensor) |
| Typical trigger | **argoWorkflow submit** |
| Bus tech | **JetStream / Kafka** |
| STAN | **Deprecated** |
| Event format | **CloudEvents** |
