# Argo CD (Deep Dive)

Second-largest domain (**34%**). Docs: [argo-cd.readthedocs.io](https://argo-cd.readthedocs.io/).

## Components

| Pod | Job |
| --- | --- |
| argocd-server | API, UI, CLI, auth |
| argocd-repo-server | Git/Helm/OCI clone + **render** |
| argocd-application-controller | **Reconcile** Applications |
| argocd-applicationset-controller | Generate Applications |
| redis | Cache |
| dex | Optional SSO |

Refresh ≈ **3 minutes** + webhook.

## Application

`project` + `source`/`sources` + `destination` + `syncPolicy`

Sync: Synced | OutOfSync | Unknown  
Health: Healthy | Progressing | Degraded | Suspended | Missing | Unknown

Automated: `prune`, `selfHeal`. Options: `CreateNamespace=true`, SSA, …

Waves: `argocd.argoproj.io/sync-wave` (lower first, default 0)  
Hooks: PreSync, Sync, PostSync, SyncFail

## Sources

Directory YAML, Kustomize path, Helm (`chart`+version or Git path + `helm.valueFiles`), jsonnet, plugin, OCI.

## Patterns

| Pattern | Idea |
| --- | --- |
| App-of-Apps | Git contains Application YAMLs |
| ApplicationSet | Generators (list, cluster, git, matrix, PR, …) |
| AppProject | sourceRepos, destinations, resource rules |
| Multi-cluster | destination.server per cluster |

Rollback = previous **recorded revision**, still desired-state based.

## CLI

`argocd login`, `app create|get|sync|diff|delete|history|rollback|refresh`

## With other Argo

CD **syncs** Rollout/WorkflowTemplate YAML. It does not run DAGs or setWeight.
