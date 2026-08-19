# Mock Exam 1

Timer: **90 minutes**. 60 questions. Closed book. Passing simulation: **45/60**.

Mix ≈ exam: Workflows 22, Argo CD 20, Rollouts 11, Events 7.

Mark answers on paper. Key at the end.

---

**1.** Argo Workflows is primarily:  
A. GitOps CD  
B. A Kubernetes-native workflow engine  
C. A service mesh  
D. An Ingress controller  

**2.** `spec.entrypoint` names:  
A. A Git branch  
B. The starting template  
C. An EventBus  
D. A preview Service  

**3.** Inner list items in a `steps` template:  
A. Always sequential  
B. Run in parallel  
C. Are sync waves  
D. Are AnalysisRuns  

**4.** Outer step groups:  
A. Always parallel  
B. Run sequentially  
C. Require Kafka  
D. Require Helm  

**5.** A `script` template:  
A. Shifts canary weight  
B. Inlines source (e.g. python) in the workflow  
C. Is repo-server  
D. Is Dex  

**6.** A `resource` template:  
A. Only builds images  
B. Applies/creates/deletes Kubernetes API objects  
C. Is EventBus  
D. Is AppProject  

**7.** `suspend` is for:  
A. Deleting Git  
B. Pausing until duration or resume  
C. Always failing DAGs  
D. Helm render  

**8.** Artifacts vs parameters:  
A. Identical  
B. Artifacts are files/directories; parameters are small values  
C. Parameters are S3 buckets only  
D. Artifacts cannot be passed  

**9.** Common artifact backend:  
A. Hubble  
B. S3 / MinIO  
C. Maglev  
D. Dex  

**10.** DAG tasks with empty dependencies:  
A. Never run  
B. Start immediately (can be parallel)  
C. Wait for Cron  
D. Require promote  

**11.** Task D `dependencies: [B, C]` waits for:  
A. Either B or C to start  
B. B and C to succeed (default)  
C. Git push  
D. EventBus  

**12.** DAG output references use:  
A. `{{steps}}` only  
B. `{{tasks.NAME.outputs...}}`  
C. `{{app.status}}`  
D. `{{analysis}}`  

**13.** Default DAG `failFast: true`:  
A. Ignores failures  
B. Stops scheduling remaining tasks after a failure  
C. Always retries forever  
D. Always prunes  

**14.** `WorkflowTemplate` is:  
A. An Application  
B. A reusable workflow definition in the cluster  
C. An EventSource  
D. A canary step  

**15.** `argo submit --from workflowtemplate/etl` creates:  
A. An EventBus  
B. A Workflow instance  
C. A Rollout  
D. An AppProject  

**16.** CronWorkflow is:  
A. ApplicationSet  
B. A schedule that spawns Workflows  
C. AnalysisRun  
D. Dex  

**17.** `concurrencyPolicy: Forbid` on CronWorkflow:  
A. Deletes Git  
B. Skips a run if the previous is still active  
C. Always overlaps  
D. Always replaces  

**18.** `onExit` runs:  
A. Only on success  
B. At the end on success or failure  
C. Only on PreSync  
D. Only on canary pause  

**19.** Fan-out over a JSON array:  
A. `setWeight`  
B. `withParam`  
C. `prune`  
D. `sourceRepos`  

**20.** Limit concurrent workflow pods:  
A. `spec.parallelism`  
B. `spec.syncPolicy`  
C. `autoPromotionEnabled`  
D. `eventBus`  

**21.** Nightly ETL DAG belongs with:  
A. Rollouts canary  
B. Workflows (often CronWorkflow)  
C. Only Ingress  
D. Only Hubble  

**22.** S3 object-created should start that DAG **now**:  
A. CronWorkflow alone is best  
B. Events EventSource + Sensor → Workflow  
C. CD selfHeal  
D. `setWeight: 10`  

**23.** Argo CD’s primary job:  
A. Run Spark DAGs  
B. Make the cluster match Git desired state  
C. Own Istio weights without Rollouts  
D. Host EventBus  

**24.** Manifest generation is done by:  
A. Dex  
B. repo-server  
C. previewService  
D. Sensor  

**25.** Live vs Git differ. Sync status is:  
A. Healthy always  
B. OutOfSync  
C. Synced always  
D. Missing always  

**26.** `automated.selfHeal: true`:  
A. Disables Git  
B. Reverts cluster drift toward Git  
C. Is EventBus  
D. Is DAG failFast  

**27.** `automated.prune: true`:  
A. Deletes the Git remote  
B. Deletes live objects removed from Git  
C. Deletes Argo CD  
D. Deletes only Events  

**28.** `destination.namespace` is:  
A. Always `argocd`  
B. Where application resources are created  
C. Only Redis  
D. Only Dex  

**29.** In-cluster destination server is typically:  
A. GitHub  
B. `https://kubernetes.default.svc`  
C. MinIO  
D. JetStream  

**30.** Health vs sync:  
A. Identical  
B. Health is runtime; sync is Git vs live spec  
C. Both mean prune  
D. Both mean canary  

**31.** Kustomize Application source is usually:  
A. EventBus  
B. A Git `path` with `kustomization.yaml`  
C. A Rollout pause  
D. A CronWorkflow  

**32.** Helm `chart:` + `targetRevision: 1.2.3` often means:  
A. Always a Git branch named 1.2.3  
B. Chart version 1.2.3 from a Helm repo  
C. An AnalysisRun  
D. An EventSource  

**33.** Sync-wave default:  
A. 100  
B. 0  
C. -1 required  
D. 50  

**34.** Lower sync-wave numbers:  
A. Apply last  
B. Apply first  
C. Are EventSources  
D. Are DAG tasks  

**35.** PreSync hook is typically:  
A. EventSource  
B. A Job that must succeed before resources apply  
C. CronWorkflow  
D. Dex  

**36.** ApplicationSet:  
A. WorkflowTemplate  
B. Generates Applications from generators  
C. EventSource  
D. Canary strategy  

**37.** App-of-Apps:  
A. Forbidden  
B. Parent Application whose Git path contains child Application YAML  
C. EventBus  
D. `setWeight`  

**38.** AppProject `sourceRepos` limits:  
A. NATS subjects  
B. Which remotes apps may use  
C. Canary weights  
D. Entrypoints  

**39.** AppProject `destinations` limit:  
A. Artifact buckets  
B. Cluster + namespace pairs  
C. DAG names  
D. Prometheus URLs only  

**40.** `CreateNamespace=true` is:  
A. A Rollout pause  
B. A sync option  
C. A DAG dependency  
D. An EventBus  

**41.** Synced but Degraded means:  
A. Impossible  
B. Git matches; runtime is unhealthy  
C. Git always mismatches  
D. Prune always failed  

**42.** Progressive delivery with CD:  
A. CD implements canary weights itself  
B. Git has a Rollout; CD syncs; Rollouts executes  
C. Workflows set Istio weight  
D. EventBus setWeight  

**43.** Argo Rollouts is primarily:  
A. Git clone  
B. Progressive delivery (blue-green, canary, analysis)  
C. EventBus  
D. Helm render  

**44.** Blue-green users stay on:  
A. Mixed 10% always  
B. Active until promotion  
C. Preview only  
D. Workflow pods  

**45.** `previewService` is for:  
A. EventBus  
B. Testing the new version before switch  
C. Git clone  
D. Helm repo  

**46.** Canary `setWeight: 20`:  
A. Wave 20  
B. ~20% traffic/weight to canary  
C. 20 CronWorkflows  
D. 20 AppProjects  

**47.** `pause: {}` means:  
A. Fail immediately  
B. Wait until promote  
C. Skip analysis always  
D. Duration 0 and continue  

**48.** AnalysisTemplate is:  
A. A running canary  
B. A reusable analysis spec  
C. EventBus  
D. Application  

**49.** AnalysisRun is:  
A. A Git tag only  
B. One execution of analysis  
C. CronWorkflow  
D. Dex  

**50.** Failed analysis typically:  
A. Prunes Git  
B. Aborts the Rollout  
C. Deletes Argo CD  
D. Creates EventBus  

**51.** `kubectl argo rollouts promote`:  
A. `argocd app sync`  
B. Advances the Rollout (e.g. unpause / switch)  
C. Submits a Workflow  
D. Creates EventBus  

**52.** Who moves canary weight?  
A. repo-server  
B. Rollouts controller (+ traffic provider)  
C. Workflow controller only  
D. Dex  

**53.** Job analysis provider:  
A. Always Prometheus  
B. Uses a Kubernetes Job as the check  
C. EventBus  
D. repo-server  

**54.** Argo Events is for:  
A. Helm rendering  
B. Event-driven triggers  
C. Blue-green Services  
D. Lua health  

**55.** EventBus is:  
A. Git  
B. Transport between EventSources and Sensors  
C. previewService  
D. Dex  

**56.** EventSource:  
A. Renders Helm  
B. Ingests events and publishes to the bus  
C. setWeight  
D. Application sync  

**57.** Sensor:  
A. Clones Git  
B. Matches dependencies and fires triggers  
C. Canary Service  
D. Dex  

**58.** Typical exam trigger:  
A. Maglev  
B. Submit an Argo Workflow  
C. Hubble  
D. BGP  

**59.** Trigger is stored as:  
A. Its own required CRD always  
B. Part of the Sensor spec  
C. An Application only  
D. A Rollout step only  

**60.** CAPA exam format:  
A. 2h live cluster  
B. 60 MCQ, 90 min, 75%, closed book  
C. Oral  
D. Open book argo docs  

---

## Answer key

1B 2B 3B 4B 5B 6B 7B 8B 9B 10B  
11B 12B 13B 14B 15B 16B 17B 18B 19B 20A  
21B 22B 23B 24B 25B 26B 27B 28B 29B 30B  
31B 32B 33B 34B 35B 36B 37B 38B 39B 40B  
41B 42B 43B 44B 45B 46B 47B 48B 49B 50B  
51B 52B 53B 54B 55B 56B 57B 58B 59B 60B  

Missed 1–22 → `01.md`–`08.md`, `Workflows.md`.  
Missed 23–42 → `09.md`–`15.md`, `ArgoCD.md`.  
Missed 43–53 → `16.md`–`19.md`, `Rollouts.md`.  
Missed 54–60 → `20.md`–`22.md`, `Events.md`.  
Tool mix-ups → `WhichTool.md`, `Integration.md`.
