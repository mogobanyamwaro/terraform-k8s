# Mock Exam 2

Harder pass. Same rules: **90 minutes**, 60 questions, **45/60**. Closed book. More “which tool / which object” traps.

---

**1.** A platform wants Git to be the source of truth for Deployments, plus a canary with Prometheus abort. Tools:  
A. Workflows only  
B. Argo CD + Rollouts  
C. Events only  
D. CronWorkflow + Dex  

**2.** Data scientists need a diamond DAG with parquet between tasks:  
A. Argo CD ApplicationSet  
B. Workflows DAG + artifacts or PVC  
C. Rollouts blue-green  
D. AppProject  

**3.** GitHub `push` should **refresh GitOps** faster:  
A. Events Sensor submitting a Workflow that kubectl applies  
B. Argo CD webhook (still GitOps)  
C. Rollouts promote  
D. CronWorkflow  

**4.** GitHub `push` should **run unit tests as pods**:  
A. Argo CD selfHeal  
B. Events (or WorkflowEventBinding) → Workflow  
C. `setWeight`  
D. App-of-Apps  

**5.** `clusterScope: true` on `templateRef` selects:  
A. AppProject default  
B. ClusterWorkflowTemplate  
C. ClusterAnalysisTemplate always  
D. EventBus Kafka  

**6.** Updating a WorkflowTemplate:  
A. Rewrites all old Workflow CRs  
B. Affects new runs/refs; old runs keep their spec  
C. Deletes etcd  
D. Forces canary 100%  

**7.** `retryPolicy: OnFailure` is a field of:  
A. Application syncPolicy only  
B. Workflow `retryStrategy`  
C. EventBus  
D. AppProject  

**8.** `volumeClaimTemplates` on a Workflow:  
A. ApplicationSets  
B. Per-run PVCs for data jobs  
C. EventSources  
D. AnalysisRuns  

**9.** `withSequence` is:  
A. Git log  
B. Numeric loop helper  
C. Sync waves  
D. JetStream  

**10.** `when:` on a DAG task:  
A. Deletes Git  
B. Conditionally runs that task  
C. Is prune  
D. Is selfHeal  

**11.** `failFast: false` on a DAG:  
A. GitOps prune  
B. Other branches may continue after one failure  
C. Canary 10%  
D. Kafka required  

**12.** `ttlStrategy` garbage-collects:  
A. Helm repos  
B. Finished Workflow objects  
C. EventBus only  
D. Ingress  

**13.** `activeDeadlineSeconds` on a Workflow:  
A. Prune  
B. Fails the run if it lasts too long  
C. SelfHeal  
D. Sync-wave  

**14.** Git artifact **input** on a workflow step:  
A. Replaces Argo CD for all CD  
B. Clones a repo **into that step’s files**  
C. Is EventBus  
D. Is AnalysisRun  

**15.** `containerSet` means:  
A. One container per cluster  
B. Multiple containers in one pod  
C. Only Windows  
D. Only AnalysisRuns  

**16.** HTTP workflow template:  
A. Replaces Ingress  
B. Makes an HTTP call as a step  
C. Is Application health  
D. Is Flux  

**17.** `workflowTemplateRef` on a Workflow:  
A. Points at an Application  
B. Uses a stored WorkflowTemplate as the spec  
C. Points at EventBus  
D. Points at previewService  

**18.** CI image build in Workflows then prod deploy:  
A. Workflows should kubectl apply prod  
B. Workflows produces digest; Git update; **Argo CD** deploys  
C. Rollouts clones the Dockerfile  
D. Events is the GitOps store  

**19.** `resource` template `successCondition`:  
A. Prometheus only  
B. Can wait until a K8s object reaches a condition  
C. Is sync-wave  
D. Is Dex  

**20.** `podGC` is about:  
A. Git GC  
B. Deleting completed workflow pods  
C. EventBus compact  
D. Canary scaleDown  

**21.** Parallel map over files then reduce:  
A. ApplicationSet PR generator only  
B. `withParam` / DAG fan-out then a join task  
C. Blue-green only  
D. Dex only  

**22.** `ClusterWorkflowTemplate` vs `ClusterAnalysisTemplate`:  
A. Same CRD  
B. Workflows library vs Rollouts analysis library  
C. Both are EventSources  
D. Both are Applications  

**23.** Who authenticates the UI login?  
A. repo-server  
B. API server (and Dex if SSO)  
C. Rollouts controller  
D. EventBus  

**24.** Redis in Argo CD stores:  
A. The GitOps source of truth  
B. Caches (manifests/sessions), not Git  
C. EventBus streams  
D. Prometheus TSDB  

**25.** Hard refresh:  
A. Always prunes  
B. Re-fetches/renders bypassing cache  
C. Creates Workflows  
D. Creates EventSources  

**26.** `ignoreDifferences` is for:  
A. Deleting Git  
B. Fields that should not cause OutOfSync (e.g. HPA replicas)  
C. EventBus ACL  
D. DAG failFast  

**27.** Multi-source Application:  
A. Illegal  
B. Can combine Helm chart + Git values  
C. Requires Flux  
D. Requires Events  

**28.** Argo CD rollback:  
A. kubectl undo while Git stays new  
B. Re-sync a previously recorded desired revision  
C. Deletes the project  
D. Always force-push  

**29.** Config management plugin runs on:  
A. EventBus  
B. repo-server  
C. previewService  
D. Sensor  

**30.** SyncFail hook runs:  
A. On successful sync  
B. When sync fails  
C. Instead of prune always  
D. On every refresh  

**31.** Git directory ApplicationSet generator:  
A. Always one app per cluster  
B. Can emit one Application per matching path  
C. Shifts traffic  
D. Starts CronWorkflows  

**32.** PR ApplicationSet generator:  
A. Prod only  
B. Preview apps per pull request  
C. EventBus  
D. Dex only  

**33.** `default` AppProject wide open:  
A. Production hardening  
B. Lab convenience; tighten in real clusters  
C. Required by Helm  
D. Required by Kustomize  

**34.** `:latest` image in Git desired state:  
A. Best rollback  
B. Weak pin; cluster may change without a Git commit  
C. Required by Kustomize  
D. Required by Helm  

**35.** `ServerSideApply=true`:  
A. A Rollout pause  
B. A sync option for apply mechanics  
C. DAG dependency  
D. EventBus  

**36.** Custom health for Rollout CRD:  
A. EventSource  
B. Lua in `argocd-cm` (typical)  
C. CronWorkflow  
D. Dex required  

**37.** Management cluster Argo CD:  
A. Cannot be GitOps  
B. Destinations point at workload cluster APIs  
C. Merges etcd  
D. Requires Workflows  

**38.** Auto-sync **without** prune:  
A. Always deletes unused Ingresses  
B. May leave orphans after Git deletes  
C. Forbids Helm  
D. Forbids Kustomize  

**39.** Auto-sync **without** selfHeal:  
A. kubectl edits always revert instantly  
B. Drift can remain until the next sync trigger  
C. Git auto-commits kubectl  
D. Applications delete themselves  

**40.** `argocd app diff` shows:  
A. A Workflow log  
B. Desired vs live  
C. Canary weights only  
D. EventBus lag  

**41.** Helm releaseName in Application:  
A. EventSource name  
B. Helm renderer setting for the release  
C. DAG entrypoint  
D. AnalysisRun name  

**42.** Waves vs Workflow DAG:  
A. Same CRD  
B. Waves order CD apply; DAG orchestrates workflow pods  
C. DAG is Ingress only  
D. Waves are EventBus  

**43.** Rollouts without Argo CD:  
A. Illegal  
B. Valid (kubectl or another GitOps tool can apply Rollouts)  
C. Requires Workflows  
D. Requires Events  

**44.** `autoPromotionEnabled: false` (blue-green):  
A. Deletes the Rollout  
B. Waits for promote/analysis before switching active  
C. Switches in 1s always  
D. Disables Services  

**45.** After blue-green promotion, old RS:  
A. Must remain forever  
B. Scales down after `scaleDownDelaySeconds`  
C. Becomes EventSource  
D. Becomes ApplicationSet  

**46.** Canary without a mesh:  
A. Impossible  
B. Often approximated with replica counts  
C. Requires Dex  
D. Requires MinIO  

**47.** `setMirrorRoute`:  
A. Deletes Git  
B. Shadows traffic to canary without serving users that response  
C. Is CronWorkflow  
D. Is App-of-Apps  

**48.** `successCondition` on a metric:  
A. DAG `when` only  
B. Boolean over provider results  
C. Sync-wave  
D. EventSource filter only  

**49.** `failureLimit` on analysis:  
A. Git PR cap  
B. Failed measurements allowed before the AnalysisRun fails  
C. Destination count  
D. Workflow parallelism  

**50.** Who creates AnalysisRuns?  
A. Dex  
B. Rollouts controller  
C. Workflow controller always  
D. ApplicationSet always  

**51.** ClusterAnalysisTemplate:  
A. Namespace-only Workflows  
B. Cluster-scoped reusable analysis  
C. ApplicationSet  
D. Sensor  

**52.** Header-based canary:  
A. Forbidden  
B. Supported via header routing steps (subset of users)  
C. Only blue-green  
D. Only Events  

**53.** Promote during canary pause:  
A. Deletes Rollout  
B. Skips remaining waits / advances  
C. Creates ApplicationSet  
D. Submits CronWorkflow  

**54.** Events **requires** Workflows installed:  
A. Always  
B. No — Workflows is a common trigger target  
C. Yes, and Rollouts  
D. Yes, and CD  

**55.** STAN / NATS Streaming EventBus:  
A. The only supported bus  
B. Deprecated; prefer JetStream or Kafka  
C. Required for CD  
D. Required for Rollouts  

**56.** Calendar EventSource vs CronWorkflow:  
A. Identical CRDs  
B. Calendar is Events; CronWorkflow is native Workflow scheduling  
C. Calendar is Rollouts  
D. CronWorkflow is EventBus  

**57.** K8s `resource` EventSource:  
A. Cannot watch API objects  
B. Fires when selected Kubernetes objects change  
C. Only MinIO  
D. Only Kafka  

**58.** Mapping object key → Workflow param:  
A. Impossible  
B. Sensor payload `dataKey` mapping  
C. Only Helm  
D. Only ignoreDifferences  

**59.** Two Sensor dependencies (AND):  
A. Forbidden  
B. Supported — wait for multiple events  
C. Only Rollouts AND  
D. Only CD waves  

**60.** Slack trigger in Events:  
A. Replaces Git  
B. A human-notification action  
C. SelfHeal  
D. Prune  

---

## Answer key

1B 2B 3B 4B 5B 6B 7B 8B 9B 10B  
11B 12B 13B 14B 15B 16B 17B 18B 19B 20B  
21B 22B 23B 24B 25B 26B 27B 28B 29B 30B  
31B 32B 33B 34B 35B 36B 37B 38B 39B 40B  
41B 42B 43B 44B 45B 46B 47B 48B 49B 50B  
51B 52B 53B 54B 55B 56B 57B 58B 59B 60B  

Missed “which tool” → `which-tool.md`, `integration.md`.  
Workflows YAML → `01–08`. CD → `09–15`. Rollouts → `16–19`. Events → `20–22`.
