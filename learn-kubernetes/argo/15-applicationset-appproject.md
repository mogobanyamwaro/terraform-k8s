# 15. ApplicationSet and AppProject

**Domain:** Argo CD (34%) — Application / reconciliation patterns

## Concept Refresher

**AppProject** constrains Applications:

- `sourceRepos` — which Git/Helm remotes
- `destinations` — which clusters/namespaces
- `clusterResourceWhitelist` / `namespaceResourceBlacklist`
- Roles / RBAC (who can sync in the UI)

Default project `default` is often wide-open — tighten in real clusters.

**ApplicationSet** (`kind: ApplicationSet`) uses **generators** to stamp out Applications:

| Generator | Idea |
| --- | --- |
| List | Explicit elements |
| Cluster | Registered clusters |
| Git | Directories/files in a repo |
| Matrix / Merge | Combine generators |
| Pull request / SCM | Preview apps per PR |
| Cluster decision / Plugin | Custom |

`template` is an Application spec with Go `{{name}}` placeholders.

**App-of-Apps:** a normal Application whose path contains Application YAMLs. No generator; Git is the list.

Management cluster: Argo CD in `mgmt`, destinations `https://prod-api:6443`. Credentials are cluster secrets in Argo CD, not in every app CI.

## Question

**Q1.** AppProject `sourceRepos` limits:

- A. EventBus NATS
- B. Which repositories Applications in that project may use
- C. Canary weights
- D. Workflow entrypoints

**Q2.** AppProject `destinations`:

- A. Artifact S3 buckets
- B. Allowed cluster + namespace pairs
- C. DAG tasks
- D. Analysis metrics

**Q3.** ApplicationSet is:

- A. A WorkflowTemplate
- B. A controller that generates Applications from generators
- C. An EventSource
- D. A Rollout strategy

**Q4.** Git directory generator:

- A. Creates one app per cluster always
- B. Can create one Application per path (e.g. `apps/*`)
- C. Shifts traffic
- D. Starts CronWorkflows

**Q5.** PR generator is for:

- A. Prod only always
- B. Preview/ephemeral apps per pull request
- C. EventBus
- D. Dex only

**Q6.** App-of-Apps vs ApplicationSet:

- A. ApplicationSet forbids Git
- B. App-of-Apps lists children **in Git YAML**; ApplicationSet **computes** children
- C. They are Rollouts
- D. They are Events

**Q7.** A team must not deploy to `prod`:

- A. Impossible
- B. AppProject destinations omit prod (and RBAC)
- C. Only failFast
- D. Only prune

**Q8.** Cluster generator:

- A. Ignores registered clusters
- B. Emits an Application per cluster Argo CD knows
- C. Is MinIO
- D. Is JetStream

**Q9.** `default` project wide open:

- A. Best production hardening
- B. Convenient lab; real installs should tighten projects
- C. Required by Helm
- D. Required by Kustomize

**Q10.** ApplicationSet template placeholders:

- A. Are DAG `{{tasks}}` only
- B. Fill Application fields from generator parameters
- C. Are EventBus subjects
- D. Are sync-wave integers only

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

Create a tight AppProject. Optional: ApplicationSet list generator with two names.

## Exam tips

- **Project = guardrails. ApplicationSet = factory. App-of-Apps = Git list.**
- Multi-cluster = destinations, not “merge etcd”.
