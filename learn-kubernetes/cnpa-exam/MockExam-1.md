# Mock Exam 1

Timer: **120 minutes**. 60 questions. Closed book. Pass simulation: **45/60**.

Mix ≈ exam: Core 22, Obs/Sec 12, CD 9, APIs 7, IDP 5, Measuring 5.

---

**1.** The primary customer of an internal platform is:  
A. The platform team  
B. Application teams using self-service  
C. The CNCF TOC  
D. Only finance  

**2.** A 5-day ticket for every namespace is:  
A. A golden path  
B. Ticket-ops; replace with self-service  
C. GitOps  
D. Elite DORA  

**3.** A golden path should be:  
A. The only legal way with no exceptions  
B. The easiest recommended way, with an escape hatch  
C. A wiki only  
D. cluster-admin for all  

**4.** Thinnest viable platform means:  
A. Install the whole CNCF landscape  
B. Smallest capabilities that cut the biggest toil now  
C. No Kubernetes  
D. No docs  

**5.** Platform engineering vs DevOps:  
A. Synonyms  
B. Platform engineering enables DevOps at scale; app teams still own delivery  
C. Platform team must deploy all apps  
D. DevOps forbids platforms  

**6.** “Platform as a product” implies:  
A. No SLOs  
B. Users, docs, roadmap, versioning, feedback  
C. Tickets only  
D. Slack only  

**7.** Declarative management asks users to:  
A. Paste kubectl procedures as the contract  
B. Declare desired state; the platform converges  
C. SSH to nodes  
D. Edit etcd  

**8.** Cloud console ClickOps as source of truth:  
A. Ideal GitOps  
B. Fails declarative management  
C. Required by Crossplane  
D. Required by Backstage  

**9.** Promote the **same image digest** staging → prod:  
A. Bad  
B. Correct: env is config, artifact is immutable  
C. Forbidden  
D. Only with `:latest`  

**10.** Many teams on one cluster need:  
A. No quotas  
B. Tenancy guardrails (RBAC, NetworkPolicy, quotas)  
C. Shared cluster-admin  
D. Disabled audit  

**11.** API-first architecture means:  
A. UI only  
B. Portal, CLI, and Git drive the same APIs  
C. No RBAC  
D. No Git  

**12.** Observability as a capability:  
A. Each team invents a stack  
B. Platform provides OTel/metrics/logs/traces by default on the path  
C. ICMP only  
D. Laptop stdout only  

**13.** Service mesh on CNPA is usually:  
A. Mandatory in every design  
B. One way to implement secure service communication / traffic features  
C. A GitOps engine  
D. A DORA key  

**14.** CI’s main output is:  
A. A live prod mutation  
B. An immutable digest plus test evidence  
C. An etcd snapshot  
D. A DORA chart only  

**15.** `:latest` as the artifact:  
A. Best provenance  
B. Weak immutability; prefer digest  
C. Required by Kubernetes  
D. Required by GitOps  

**16.** Prod kubeconfig in every CI job:  
A. Least privilege  
B. Anti-pattern; CD agent should apply  
C. Required GitOps  
D. Required SBOM  

**17.** GitOps on a platform means:  
A. Wiki is desired state  
B. Git holds desired state; an agent reconciles  
C. CI kubectl required  
D. No reviews  

**18.** Rollback in GitOps:  
A. kubectl undo leaving Git new  
B. Restore desired state in Git, then reconcile  
C. Delete the platform  
D. Disable RBAC  

**19.** “You build it, you run it” with a platform:  
A. Platform on-call for every app bug  
B. App teams operate their services; platform operates the path  
C. No on-call  
D. Only DBAs  

**20.** Reducing cognitive load means:  
A. Developers assemble 20 tools  
B. The path hides incidental complexity  
C. No abstraction  
D. Ban YAML  

**21.** Scaling platform headcount 1:1 with app teams:  
A. Intended model  
B. Sign the platform is not self-service  
C. DORA requirement  
D. Kubernetes requirement  

**22.** Feature flags vs GitOps:  
A. Incompatible  
B. Complementary: Git deploys; flags may release  
C. Flags replace Git  
D. GitOps forbids flags  

**23.** CNPA observability signals include:  
A. CPU only  
B. Traces, metrics, logs, and events  
C. Only DORA  
D. Only BGP  

**24.** OpenTelemetry is:  
A. The only metrics DB  
B. Vendor-neutral instrumentation/export  
C. A GitOps engine  
D. A policy engine  

**25.** Ingress TLS alone:  
A. Encrypts all pod-to-pod traffic  
B. Covers north-south; east-west needs more  
C. Replaces NetworkPolicy always  
D. Replaces RBAC  

**26.** mTLS provides:  
A. Git signing only  
B. Encryption and mutual authentication  
C. DORA frequency  
D. Helm render  

**27.** Policy engines exist to:  
A. Replace Git  
B. Enforce guardrails as code continuously  
C. Store traces  
D. Render Helm only  

**28.** Mutating admission is useful to:  
A. Delete Git  
B. Inject secure defaults  
C. Disable RBAC  
D. Disable NetworkPolicy  

**29.** Restricted Pod Security typically:  
A. Allows privileged always  
B. Enforces non-root / dropped caps / no hostPath  
C. Replaces NetworkPolicy  
D. Replaces GitOps  

**30.** Plaintext secrets in Git:  
A. Golden path  
B. Anti-pattern  
C. Required GitOps  
D. Required Kyverno  

**31.** Prod cluster-admin in GitHub Actions for all repos:  
A. Least privilege  
B. Pipeline security failure  
C. Required GitOps  
D. Required SLSA  

**32.** Signing images (cosign) helps:  
A. DORA only  
B. Verify provenance at admission  
C. Replace tests  
D. Replace NetworkPolicy  

**33.** Fork PRs with write secrets:  
A. Fine  
B. Exfiltration risk; isolate  
C. Required by Git  
D. Required by OTel  

**34.** Default-allow all pods on a shared cluster:  
A. Zero trust  
B. A tenancy gap  
C. Required GitOps  
D. Required Backstage  

**35.** After a green CI build, GitOps-friendly next step:  
A. kubectl apply prod  
B. Config-repo PR with the digest  
C. SSH to nodes  
D. Disable admission  

**36.** CI answers:  
A. Is prod healthy?  
B. Did this change build and test cleanly?  
C. What is MTTR?  
D. What is PSS?  

**37.** CD answers:  
A. Did unit tests pass?  
B. Is the desired revision in an environment?  
C. Go version?  
D. Dockerfile lint?  

**38.** Rebuild a new image at promote time:  
A. Build once  
B. Breaks the CI/CD contract  
C. Required GitOps  
D. Required OTel  

**39.** Promoting via PR into `overlays/prod`:  
A. Ticket ops  
B. Standard GitOps env workflow  
C. Forbidden  
D. Only Events  

**40.** CODEOWNERS on prod paths:  
A. Against self-service  
B. Guardrail; the PR *is* self-service  
C. Replaces GitOps  
D. Replaces CI  

**41.** All GitOps syncs failing cluster-wide:  
A. Each app’s private incident  
B. A platform incident  
C. Only a DORA survey  
D. Only a theme  

**42.** First mitigation for a bad prod overlay:  
A. Rewrite history routinely  
B. Revert Git / abort rollout  
C. Disable RBAC  
D. Delete etcd  

**43.** Continuous delivery vs deployment:  
A. Always identical  
B. Delivery = releasable; deployment = auto to prod  
C. Delivery forbids Git  
D. Deployment forbids GitOps  

**44.** The reconciliation loop:  
A. Runs unit tests  
B. Drives actual toward desired repeatedly  
C. Is DORA MTTR  
D. Is Backstage search  

**45.** A CRD on a platform is:  
A. A Grafana folder  
B. A self-service API schema  
C. A DORA key  
D. An Ingress class only  

**46.** Users of a `Postgres` CR should set:  
A. Every cloud IAM flag  
B. High-level spec; controller fills cloud  
C. etcd peers  
D. kubelet flags  

**47.** Cluster API provisions:  
A. Backstage  
B. Kubernetes clusters as CRs  
C. Traces  
D. DORA  

**48.** Crossplane XRD/XR:  
A. DORA keys  
B. Composed infra APIs over cloud resources  
C. NetworkPolicy  
D. PSS  

**49.** An operator is:  
A. A DORA dashboard  
B. A controller with operational knowledge of a CR lifecycle  
C. A Backstage theme  
D. A NetworkPolicy  

**50.** A controller that applies once and exits:  
A. Continuous reconciliation  
B. Not the operator pattern  
C. Crossplane  
D. CAPI  

**51.** spec vs status:  
A. Identical  
B. spec desired; status observed  
C. status is Git only  
D. spec is traces  

**52.** A developer portal’s job:  
A. Replace GitOps  
B. Simplify discover/request of capabilities  
C. Store etcd  
D. Compute DORA alone  

**53.** Backstage on CNPA is:  
A. Mandatory in every answer  
B. A common portal/catalog/scaffolder example  
C. A CNI  
D. A policy engine  

**54.** Portal with zero backend APIs:  
A. Complete IDP  
B. Wallpaper; need real self-service  
C. GitOps  
D. MTTR  

**55.** Safe AI helper should:  
A. Apply YAML to prod with no review  
B. Propose PRs/CRs still gated by GitOps and policy  
C. Hold cluster-admin in the prompt  
D. Disable audit  

**56.** The four DORA metrics are:  
A. CPU, RAM, disk, GPU  
B. Deploy frequency, lead time, change failure rate, time to restore  
C. RED only  
D. USE only  

**57.** A 10-day ticket queue mainly hurts:  
A. Ingress TLS  
B. Lead time for changes  
C. mTLS ciphers  
D. etcd compaction  

**58.** One-click Git revert mainly improves:  
A. CVE count only  
B. Time to restore  
C. Catalog CSS  
D. CRD versions only  

**59.** Best success metric:  
A. CNCF projects installed  
B. Golden-path adoption and falling wait/tickets  
C. Lines of Rego  
D. Slack bots  

**60.** Using DORA to blame teams while the path is a ticket farm:  
A. Peak platform engineering  
B. Misuse; fix the product first  
C. Required by CNCF  
D. The only DORA lever  

---

## Answer key

1B 2B 3B 4B 5B 6B 7B 8B 9B 10B  
11B 12B 13B 14B 15B 16B 17B 18B 19B 20B  
21B 22B 23B 24B 25B 26B 27B 28B 29B 30B  
31B 32B 33B 34B 35B 36B 37B 38B 39B 40B  
41B 42B 43B 44B 45B 46B 47B 48B 49B 50B  
51B 52B 53B 54B 55B 56B 57B 58B 59B 60B  

Missed 1–22 → `01–07`, `WhichLayer.md`, `PlatformsWhitepaper.md`.  
23–34 → `08–12`. 35–43 → `13–16`, `GitOps.md`. 44–51 → `17–19`, `Operators.md`.  
52–55 → `20–21`, `IDP.md`. 56–60 → `22.md`, `DORA.md`.
