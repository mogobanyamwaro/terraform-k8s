# Mock Exam 1

Timer: **90 minutes**. 60 questions. Closed book. Passing simulation: **45/60**.

Domain mix ≈ real exam: Terminology 12, Principles 18, Related practices 10, Patterns 12, Tooling 8.

Mark answers on paper. Key at the end.

---

**1.** A declarative description specifies:  
A. Ordered kubectl commands  
B. Desired operating state, not the procedure to reach it  
C. Only SQL dumps  
D. Slack approval messages  

**2.** Desired state should be sufficient to:  
A. Replace all observability  
B. Recreate a behaviourally indistinguishable system instance  
C. Store every user upload  
D. Compile the kernel  

**3.** Persistent application data (database rows) in GitOps desired state is:  
A. Always required as SQL in Git  
B. Generally not included  
C. The definition of reconciliation  
D. The state store  

**4.** Drift means:  
A. Git and GitHub are different products  
B. CI is slow  
C. Actual state differs from desired state  
D. Helm is used  

**5.** Reconciliation is:  
A. Deleting Git history  
B. Making actual state match desired state  
C. Only human chat  
D. Compiling images  

**6.** The canonical GitOps state store is:  
A. etcd  
B. Prometheus  
C. Git  
D. Slack  

**7.** A state store alternative to Git must still provide:  
A. Unlogged overwrite  
B. Versioning, immutability, history, and access control/audit  
C. A wiki UI  
D. Direct etcd writes  

**8.** “Continuous” in OpenGitOps means:  
A. Instantaneous  
B. Real-time only  
C. Happening regularly and frequently, not necessarily instantly  
D. Once per year  

**9.** Feedback in GitOps is:  
A. Only the Git commit message  
B. Information about actual state used by agents or humans  
C. Only Helm values  
D. A fifth principle  

**10.** The GitOps-native rollback is:  
A. `kubectl rollout undo` while leaving Git unchanged  
B. Restore a previous desired-state version in the store, then reconcile  
C. Force-push rewriting history as the everyday method  
D. SSH and edit binaries  

**11.** A GitOps managed software system is:  
A. The laptop that ran kubectl  
B. Runtime instance(s) that implement the declared desired state  
C. Only GitHub Actions  
D. Only Prometheus  

**12.** Live etcd contents are best described as:  
A. Desired state  
B. The OpenGitOps store  
C. Actual (cluster) state  
D. A declarative description in Git  

**13.** The Declarative principle requires:  
A. Desired state expressed as what, not a procedure  
B. Python only  
C. Push pipelines only  
D. No version control  

**14.** A Makefile of `helm upgrade` commands as the *only* source of truth:  
A. Fully satisfies Declarative  
B. Is imperative procedure even if stored in Git  
C. Is principle 3  
D. Replaces the state store  

**15.** Versioned and Immutable is violated by:  
A. Git tags of chart versions  
B. Image digests in Git  
C. Deploying `:latest` as the declared image  
D. OCI artifacts with sha256  

**16.** Completing a rollback by `git push --force` to erase the bad commit from prod history:  
A. Is the recommended immutable pattern  
B. Treats history as disposable; normal GitOps rollback adds a new version  
C. Is required by Flux  
D. Is required by Argo CD  

**17.** Pulled Automatically means:  
A. Humans always click Apply  
B. Software agents fetch desired-state declarations from the store  
C. CI must kubectl  
D. Webhooks are forbidden  

**18.** A GitHub Action that `kubectl apply`s on every merge:  
A. Is the textbook pull model  
B. Is push-based CD, not GitOps pull  
C. Satisfies all four principles  
D. Is the only CNCF method  

**19.** A webhook that tells Argo/Flux to refresh Git, while an interval still polls:  
A. Forbidden  
B. An accelerator for pull, still GitOps-shaped  
C. Replaces Git  
D. Makes CI the applier  

**20.** If the webhook is down but the agent still polls Git every few minutes:  
A. GitOps pull has stopped forever  
B. Reconciliation can still converge  
C. Desired state is now etcd  
D. Principles require instant apply  

**21.** Continuously Reconciled requires agents to:  
A. Apply once and exit  
B. Keep observing actual state and attempt to apply desired state  
C. Only run on Fridays  
D. Disable self-heal  

**22.** A 5-minute reconcile interval is:  
A. Not continuous because it is not instant  
B. Still continuous in the OpenGitOps sense  
C. Illegal  
D. Only valid for Helm  

**23.** `selfHeal: true` (Argo) or a repeating Kustomization interval (Flux) primarily implements:  
A. Declarative only  
B. Continuous reconciliation of drift  
C. CaC only  
D. Progressive delivery only  

**24.** Which set is the official OpenGitOps principle names in order?  
A. Immutable, Event-driven, Synced, Declarative  
B. Declarative; Versioned and Immutable; Pulled Automatically; Continuously Reconciled  
C. CI, CD, Git, Kubernetes  
D. Pull, Push, Merge, Tag  

**25.** ClickOps in the cloud console as the real source of truth fails first because it is not:  
A. Using Helm  
B. Declarative desired state in a proper store  
C. Using kind  
D. Using Slack  

**26.** Storing imperative runbooks in Git:  
A. Automatically satisfies Declarative for the managed system  
B. Does not by itself make the managed system’s desired state declarative  
C. Replaces the agent  
D. Is principle 4  

**27.** The agent “attempts” to apply desired state. If apply fails:  
A. GitOps requires pretending the cluster matches  
B. The loop should retry and surface feedback  
C. You must delete Git  
D. Principles no longer apply  

**28.** Which statement is true?  
A. GitOps requires Argo CD  
B. GitOps requires Flux  
C. Any engine that implements the four principles can be GitOps  
D. GitOps requires Jenkins X  

**29.** Desired state in a wiki page edited in place with no history:  
A. Satisfies Versioned and Immutable  
B. Fails as a GitOps state store  
C. Is OCI  
D. Is pull  

**30.** Kubernetes fits GitOps mainly because:  
A. It has no API  
B. You declare resources and controllers converge  
C. It forbids YAML  
D. It requires sidecars  

**31.** Configuration as Code compared with GitOps:  
A. They are identical terms  
B. GitOps is CaC plus pull-based continuous reconciliation  
C. CaC forbids Git  
D. GitOps forbids YAML  

**32.** Infrastructure as Code:  
A. Cannot be operated with GitOps  
B. Can be the declarative infra description that an agent reconciles  
C. Replaces OpenGitOps  
D. Is only ClickOps  

**33.** DevOps versus GitOps:  
A. Exact synonyms  
B. DevOps is a broader culture/practice; GitOps is a specific operating model  
C. GitOps replaced the need for teams  
D. DevOps forbids Git  

**34.** A DevSecOps control on the config repo is:  
A. Disabling PR review  
B. CODEOWNERS, required reviews, and policy checks on manifests  
C. Raw production passwords in YAML  
D. Public write access  

**35.** Continuous Integration in a GitOps workflow should typically:  
A. kubectl to production  
B. Build, test, and update desired state in Git (for example an image digest)  
C. Disable the cluster agent  
D. Force-push rewritten history daily  

**36.** Continuous Delivery that is GitOps is:  
A. Push apply from the CI runner as the control plane  
B. Pull-based reconciliation of declared desired state  
C. Only weekly cron kubectl  
D. Only chatops apply  

**37.** CI and CD in GitOps:  
A. Must be the same job that applies YAML  
B. Are split: CI produces artifacts/Git updates; the agent performs cluster CD  
C. CD is deleted  
D. CI is deleted  

**38.** Sealed Secrets / SOPS in Git:  
A. Violate Declarative  
B. Keep secrets declared without storing plaintext as the reviewable source  
C. Replace Git  
D. Replace the reconciler  

**39.** “We put YAML in Git, therefore we do GitOps”:  
A. Always true  
B. False if CI still pushes applies and nothing reconciles drift  
C. True only for Helm  
D. True only for Argo  

**40.** Policy-as-code (Kyverno/OPA) on config PRs is:  
A. Against GitOps  
B. DevSecOps on desired state before it is pulled  
C. A replacement for reconciliation  
D. A replacement for Git  

**41.** Deploy versus release:  
A. Exact synonyms  
B. Deploy places a version in the runtime; release exposes it to users (traffic or flag)  
C. Release is only Git clone  
D. Deploy is only Slack  

**42.** Blue/green in GitOps:  
A. Forbidden  
B. Two stacks declared; Git (or Git-owned objects) flips which serves traffic  
C. Requires `:latest`  
D. Requires deleting Git  

**43.** Canary delivery:  
A. Sends 100% traffic immediately  
B. Sends a small fraction of traffic to the new version, then more if healthy  
C. Is only database backup  
D. Is only etcd snapshot  

**44.** Progressive delivery adds:  
A. Random kubectl  
B. Gradual exposure plus automated analysis and abort  
C. Removal of Git  
D. Removal of the agent  

**45.** Analysis metrics (error rate, latency) in progressive delivery are:  
A. The desired-state store  
B. Feedback used to continue or roll back the declared rollout  
C. A replacement for Git  
D. Only Hubble  

**46.** Event-driven GitOps means:  
A. CI kubectl on every image webhook  
B. Notifications can accelerate an agent that still pulls Git  
C. Git is removed  
D. Polling is forbidden forever  

**47.** A security argument for pull-based apply:  
A. More copies of cluster-admin in every CI job  
B. Cluster apply credentials stay with the in-cluster or management agent  
C. Public Git is required  
D. RBAC must be disabled  

**48.** An in-cluster reconciler:  
A. Never talks to Git  
B. Runs in the Kubernetes cluster (or a cluster) and pulls desired state  
C. Is only Jenkins  
D. Is only Terraform Cloud push  

**49.** A management cluster running Argo CD for many workload clusters:  
A. Cannot be GitOps  
B. Is a valid architecture; destinations are the runtimes  
C. Requires `:latest`  
D. Merges all etcds  

**50.** App-of-Apps / root Kustomization:  
A. Forbidden  
B. Parent desired state that points at child apps/paths  
C. Replaces Git  
D. Is CI  

**51.** After emergency kubectl, Git is left unchanged:  
A. Best practice  
B. Leaves drift; the agent may revert the emergency or the store becomes a lie  
C. Updates OpenGitOps automatically  
D. Is pull by definition  

**52.** Promoting to production in GitOps is typically:  
A. kubectl from a laptop  
B. A reviewed change to the prod overlay/path in the state store  
C. Editing etcd  
D. Posting YAML in Slack  

**53.** Kustomize is:  
A. A programming language runtime  
B. Overlay/patch packaging without Go templates  
C. A reconciler  
D. A state store  

**54.** Pinning Helm chart version and image digest primarily supports:  
A. Instant webhooks  
B. Versioned and Immutable  
C. ClickOps  
D. Wiki stores  

**55.** Overwriting `s3://bucket/app.yaml` in place with no versioning:  
A. A complete GitOps store  
B. A poor state store  
C. Required by Flux  
D. Required by Argo  

**56.** Argo CD and Flux are best classified as:  
A. State stores  
B. Reconciliation engines  
C. Only CI systems  
D. Only Ingress controllers  

**57.** Flux image automation that opens a Git commit for a new tag:  
A. kubectl apply from CI  
B. CI-shaped interoperability that still keeps apply with the agent  
C. Push CD to the API server  
D. A violation of Declarative always  

**58.** Deploy keys for the cluster agent should usually be:  
A. Org owner  
B. Read-only on the config repo (write only if image automation needs it)  
C. Root on GitHub  
D. Shared laptop SSH with write-all  

**59.** A Slack alert when sync fails is:  
A. The state store  
B. Human-facing feedback  
C. Drift itself  
D. A fifth principle  

**60.** The CGOA exam is:  
A. Hands-on 2 hours with cluster docs  
B. 60 multiple-choice questions, 90 minutes, 75%, closed book  
C. Oral only  
D. Open book opengitops.dev  

---

## Answer key

1B 2B 3B 4C 5B 6C 7B 8C 9B 10B  
11B 12C 13A 14B 15C 16B 17B 18B 19B 20B  
21B 22B 23B 24B 25B 26B 27B 28C 29B 30B  
31B 32B 33B 34B 35B 36B 37B 38B 39B 40B  
41B 42B 43B 44B 45B 46B 47B 48B 49B 50B  
51B 52B 53B 54B 55B 56B 57B 58B 59B 60B  

Missed 1–12 → `01.md`–`04.md`, `OpenGitOps.md`.  
Missed 13–30 → `05.md`–`08.md`, `Principles.md`.  
Missed 31–40 → `09.md`–`11.md`.  
Missed 41–52 → `12.md`–`15.md`, `Patterns.md`, `RepoLayout.md`.  
Missed 53–60 → `16.md`–`19.md`, `ArgoCD.md`, `Flux.md`.
