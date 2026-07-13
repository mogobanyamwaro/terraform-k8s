# Mock Exam 2

Harder pass. Same rules: **90 minutes**, 60 questions, **45/60** to simulate a pass. Closed book.

Expect more “which principle fails” and lookalike terms. Key at the end.

---

**1.** OpenGitOps allows a non-Git store when:  
A. It is a Slack channel  
B. It is versioned, immutable, historical, access-controlled, and auditable  
C. It is live etcd  
D. It is a wiki with one page  

**2.** “Behaviourally indistinguishable” in the desired-state definition refers to:  
A. Identical disk serial numbers  
B. Recreated instances that behave the same for that configuration  
C. Identical Prometheus TSDB files  
D. Identical node hostnames always  

**3.** Which is *least* part of GitOps desired state?  
A. Deployment spec  
B. Ingress host  
C. Customer rows in PostgreSQL  
D. Resource quotas  

**4.** Drift is detected by:  
A. Reading only Git, never the cluster  
B. Comparing actual runtime state to desired declarations  
C. Counting GitHub stars  
D. Helm Hub rankings  

**5.** Feedback used *by the agent* during reconcile is typically:  
A. Marketing email  
B. Resource status, health, apply errors  
C. The word “GitOps” in a README  
D. A human vacation calendar  

**6.** Feedback used *by humans* is typically:  
A. Replacing Git  
B. Notifications that sync is stuck or health is degraded  
C. Force-push  
D. Disabling RBAC  

**7.** Rollback that adds a new commit restoring old YAML:  
A. Violates immutability because YAML looks old  
B. Uses history; the new commit is a new version of desired state  
C. Requires deleting `.git`  
D. Requires kubectl undo first always  

**8.** `kubectl rollout undo` while Git still declares the new image, with self-heal on:  
A. Is a complete GitOps rollback  
B. Is likely undone by reconciliation back to Git  
C. Updates Git automatically in all engines  
D. Deletes the Application  

**9.** Continuous does *not* mean:  
A. Regular  
B. Frequent  
C. Instantaneous  
D. Ongoing  

**10.** Two clusters pulling the same desired-state path are:  
A. Illegal  
B. Two runtime instances of the same software system (for that config)  
C. One etcd  
D. Forbidden by principle 1  

**11.** Access control on who can merge to `overlays/prod` is:  
A. Unrelated trivia  
B. State-store management (who may change desired state)  
C. Hubble  
D. Maglev  

**12.** A complete version history matters for GitOps because:  
A. GitHub billing  
B. Audit and rollback to known-good desired state  
C. etcd compaction  
D. Ingress class names  

**13.** Which principle is primarily about *who fetches* declarations?  
A. Declarative  
B. Versioned and Immutable  
C. Pulled Automatically  
D. Continuously Reconciled  

**14.** Which principle is primarily about *what vs how*?  
A. Pulled Automatically  
B. Declarative  
C. Continuously Reconciled  
D. None  

**15.** Which principle is primarily about *history that cannot be silently clobbered*?  
A. Declarative  
B. Versioned and Immutable  
C. Pulled Automatically  
D. Continuously Reconciled  

**16.** Which principle is primarily about *the loop against actual state*?  
A. Declarative  
B. Versioned and Immutable  
C. Pulled Automatically  
D. Continuously Reconciled  

**17.** Helm `image.tag: latest` in Git, with Flux reconciling every minute:  
A. Satisfies all four principles equally well  
B. Fails Versioned and Immutable even if pull and reconcile work  
C. Fails Declarative only  
D. Fails pull only  

**18.** Jenkins `kubectl apply -f` from kubeconfig on merge, YAML otherwise perfect:  
A. GitOps because YAML is declarative  
B. Fails Pulled Automatically (and typically continuous reconcile)  
C. Fails only packaging  
D. Fails only DevOps culture  

**19.** Agent applies once at install, then is removed:  
A. Still continuously reconciled  
B. One-shot converge; not GitOps going forward  
C. Stronger GitOps  
D. Required for OCI  

**20.** Humans must click Sync for every Git change; no interval, no webhook, no automation:  
A. Ideal continuous reconciliation  
B. Weak/absent automatic pull-and-reconcile  
C. Stronger than Flux  
D. Required by OpenGitOps  

**21.** A webhook is the *only* way the agent ever learns Git changed, and there is no interval:  
A. Fully equivalent to pull-on-interval GitOps  
B. Breaks the “agents pull automatically” story if events are missed  
C. Required  
D. The definition of immutable  

**22.** Terraform HCL in Git applied by a controller that replans on a loop:  
A. Can be GitOps for that infra  
B. Can never be GitOps  
C. Is only CaC, never GitOps  
D. Requires Argo CD  

**23.** Ansible playbooks of shell commands as the *desired state*:  
A. Ideal Declarative  
B. Typically imperative procedure, not a declarative description  
C. Principle 3  
D. Principle 4  

**24.** Why `:latest` is an exam trap:  
A. Kubernetes forbids it always  
B. The Git commit no longer pins a unique artifact version  
C. Flux cannot pull Git  
D. Argo cannot render YAML  

**25.** Self-heal off, engineers kubectl daily, Git lags:  
A. Git remains the winner  
B. Actual state is operated outside the store; drift is the process  
C. Strong DevSecOps  
D. Strong pull  

**26.** “Attempt to apply” implies:  
A. Success is guaranteed  
B. Failures are possible; the agent keeps trying and should expose status  
C. Git is deleted on error  
D. Webhooks are removed  

**27.** Rendering Helm in-cluster versus committing rendered YAML:  
A. Only in-cluster can be GitOps  
B. Only CI-render can be GitOps  
C. Either can be GitOps if Git holds the inputs/outputs the agent uses  
D. Neither can be GitOps  

**28.** Force-pushing `main` to hide a bad release as routine rollback:  
A. Preserves complete history  
B. Undermines Versioned and Immutable / audit  
C. Required by Git  
D. Required by OpenGitOps  

**29.** The four principles are:  
A. Optional guidelines  
B. The definition of GitOps for CGOA  
C. Argo CD only  
D. Flux only  

**30.** An engine with a beautiful UI that only pushes manifests from a form, never Git:  
A. GitOps because it is CNCF-related  
B. Not GitOps; no proper pulled desired-state store  
C. Principle 2 only  
D. Principle 4 only  

**31.** CaC without an agent:  
A. Is already GitOps  
B. May be good practice but is not GitOps until pull + reconcile exist  
C. Forbids YAML  
D. Forbids Git  

**32.** IaC that is applied by a human once a quarter from a laptop:  
A. GitOps  
B. IaC, not GitOps  
C. Progressive delivery  
D. Feedback loop  

**33.** DevSecOps most clearly fails when:  
A. Image digests are pinned  
B. Production kubeconfig is in every contractor CI and raw secrets sit in Git  
C. CODEOWNERS protect prod  
D. PRs run kubeconform  

**34.** The correct CI output for GitOps CD is usually:  
A. A live cluster mutation  
B. An immutable artifact plus a Git change declaring it  
C. A Slack screenshot  
D. An etcd dump  

**35.** Calling GitOps “just CD”:  
A. Precise enough  
B. Too loose: many CD systems are push-based and not continuously reconciled  
C. GitOps is only CI  
D. GitOps is only IaC  

**36.** Conftest/Kyverno CLI on the config repo:  
A. Replaces Flux  
B. Shifts policy left onto desired state  
C. Replaces Git  
D. Is ClickOps  

**37.** Platform team owns prod overlays; app teams own app repos:  
A. Illegal GitOps  
B. Common split of duties aligned with config-as-code + least privilege  
C. Requires one monorepo always  
D. Requires no reviews  

**38.** ChatOps “deploy this YAML I pasted”:  
A. A proper state store  
B. Not a versioned immutable store with review/audit  
C. Principle 3  
D. OCI  

**39.** GitOps is a subset of:  
A. eBPF  
B. Practices that include CaC/IaC/DevOps ideas, specialised into pull+reconcile  
C. Only Helm  
D. Only Istio  

**40.** CD Foundation / Linux Foundation CGOA is:  
A. An Argo CD administrator cert  
B. Vendor-neutral GitOps associate  
C. A CKA replacement  
D. Hands-on Istio  

**41.** Recreate deploy strategy:  
A. Always zero downtime  
B. Terminate old then start new (downtime possible)  
C. Always canary  
D. Always blue/green  

**42.** Rolling update vs GitOps:  
A. Incompatible  
B. The Deployment strategy can be declared in Git and reconciled  
C. Requires push CI  
D. Requires `:latest`  

**43.** A/B testing vs canary:  
A. Identical always  
B. A/B is often experiment/assignment; canary is risk-reducing gradual rollout  
C. A/B forbids Git  
D. Canary forbids metrics  

**44.** Shadow/dark traffic:  
A. Users hit only the new version  
B. Duplicated traffic to a new version without serving them that response  
C. Deletes Git  
D. Is etcd restore  

**45.** Progressive delivery abort should:  
A. Only kubectl while Git still ramps to 100%  
B. Update desired state (or Git-owned rollout object) so Git and cluster agree  
C. Disable the agent forever  
D. Force-push unrelated repos  

**46.** Pull vs event-driven on CGOA is about:  
A. eBPF vs iptables  
B. How the agent is *triggered* to refresh, not abandoning Git  
C. Blue vs green  
D. Helm vs Kustomize  

**47.** Push CD from CI is often criticised because:  
A. Git cannot store YAML  
B. Cluster credentials proliferate and drift is invisible between pipelines  
C. Kubernetes cannot reconcile  
D. Helm cannot pin versions  

**48.** External reconciler that still polls Git and applies to a cluster:  
A. Automatically not GitOps because it is not a DaemonSet  
B. Can be GitOps (management-cluster / SaaS agent pattern)  
C. Is always Jenkins kubectl  
D. Forbids principle 4  

**49.** External process that applies only on GitHub `push` webhook and then exits:  
A. Strong continuous reconciliation  
B. Event-driven push, not a standing reconcile loop  
C. Flux by definition  
D. OpenGitOps principle 4  

**50.** Monorepo of all env YAML:  
A. Illegal  
B. Valid if prod paths are protected (CODEOWNERS/reviews)  
C. The only legal GitOps  
D. Requires SaaS GitHub  

**51.** Polyrepo (one config repo per service):  
A. Forbids GitOps  
B. Valid; the agent is configured with the right sources  
C. Requires merging etcd  
D. Requires `:latest`  

**52.** Break-glass documented, audited, then Git updated to match:  
A. Against GitOps forever  
B. How emergencies can return the store to being the winner  
C. Replaces the agent  
D. Is webhook-only  

**53.** Jsonnet/CUE generating YAML:  
A. Cannot be GitOps  
B. Fine if declared inputs are versioned and an agent applies the result  
C. Replaces the agent  
D. Is push CD by definition  

**54.** Chart version `*` :  
A. Best for rollback  
B. Weakens Versioned and Immutable  
C. Required by Flux  
D. Required by Helm  

**55.** OCI Helm chart referenced by digest:  
A. Always illegal  
B. Can be a versioned artifact store  
C. Replaces reconciliation  
D. Requires wiki  

**56.** Argo CD Application `automated.prune: true`:  
A. Disables Git  
B. Deletes cluster resources removed from Git  
C. Is CI  
D. Is only Flux  

**57.** Flux `GitRepository` + `Kustomization` pair is:  
A. The CI runner  
B. Source pull plus reconcile loop  
C. Only Helm  
D. Only Argo Rollouts  

**58.** Choosing Argo versus Flux as “the GitOps one”:  
A. Argo is GitOps; Flux is not  
B. Flux is GitOps; Argo is not  
C. Both can implement OpenGitOps; CGOA is not a product pick  
D. Neither can  

**59.** Observability (Prometheus, Argo health) in GitOps:  
A. Replaces the state store  
B. Complements Git by exposing actual/health for feedback and analysis  
C. Forbids progressive delivery  
D. Forbids pull  

**60.** If notifications are ignored by humans:  
A. The agent still attempts reconcile; stuck systems may go unseen  
B. GitOps stops by definition  
C. Drift becomes impossible  
D. Principles auto-fail  

---

## Answer key

1B 2B 3C 4B 5B 6B 7B 8B 9C 10B  
11B 12B 13C 14B 15B 16D 17B 18B 19B 20B  
21B 22A 23B 24B 25B 26B 27C 28B 29B 30B  
31B 32B 33B 34B 35B 36B 37B 38B 39B 40B  
41B 42B 43B 44B 45B 46B 47B 48B 49B 50B  
51B 52B 53B 54B 55B 56B 57B 58C 59B 60A  

Missed store/glossary → `01–04`, `OpenGitOps.md`.  
Missed principle IDs → `05–08`, `Principles.md`.  
Missed CaC/CI/CD → `09–11`.  
Missed deploy/architecture → `12–15`, `Patterns.md`, `RepoLayout.md`.  
Missed engines/packaging → `16–19`, `ArgoCD.md`, `Flux.md`.
