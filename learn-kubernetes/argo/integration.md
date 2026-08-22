# Integrating the Four Tools

CAPA asks **wiring**, not only isolated CRDs.

## Picture

```text
[SaaS / S3 / GitHub / Kafka]
            |
      Argo Events
            |  submit
      Argo Workflows     (build, test, ETL, image)
            |  commit digest to config repo
          Git
            |
        Argo CD          (sync desired state)
            |
     Deployment or Argo Rollouts
            |
     analysis / promote / abort
```

Each arrow is a **different controller**. None of them is optional to name wrongly.

## Legal combos

| Combo | Role split |
| --- | --- |
| Events + Workflows | When + DAG |
| CD + Rollouts | GitOps + progressive traffic |
| CD + WorkflowTemplates | GitOps of pipeline **definitions** |
| Events + k8s trigger | When + create Job without Workflows |
| CD + ApplicationSet + Rollouts | Many clusters, each with canary |

## Illegal exam stories

- “Argo CD runs the Spark DAG”
- “Workflows self-heals Deployments from Git”
- “Events is how Argo CD polls Git”
- “Rollouts clones Helm charts”
- “AnalysisTemplate is a WorkflowTemplate”

## Git webhook vs Events webhook

- **CD webhook:** refresh Git faster (still GitOps).
- **Events webhook:** arbitrary HTTP → trigger (often a Workflow).

Same word, different products.
