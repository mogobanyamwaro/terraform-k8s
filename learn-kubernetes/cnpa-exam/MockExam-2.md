# Mock Exam 2

Harder judgement. **120 minutes**, 60 questions, **45/60**. Same weights, more traps.

---

**1.** The platform team is drowning in “please kubectl.” First product move:  
A. Hire linearly with app teams  
B. Expose a self-service API/template for the top request  
C. Ban all deploys  
D. Delete the portal  

**2.** Mandatory exclusive framework, no hatch, 12-week wait for exceptions:  
A. Golden path  
B. A mandate that creates shadow IT  
C. TVP  
D. Elite DORA  

**3.** Backstage installed; still a ticket for namespaces and no templates:  
A. IDP complete  
B. Portal without capabilities  
C. GitOps complete  
D. DORA complete  

**4.** App team on-call for their API; platform on-call when GitOps is down:  
A. Confused ownership  
B. Correct split  
C. Illegal DevOps  
D. Requires mesh  

**5.** Crossplane composition `kind: TeamBucket` with `team` + `size`:  
A. Leaky  
B. Good self-service abstraction  
C. Forbidden CRD  
D. DORA metric  

**6.** Same composition exposing 80 AWS fields:  
A. Lowest cognitive load  
B. Leaky API  
C. Required  
D. TVP  

**7.** Helm upgrade from a laptop, no Git:  
A. Platform CD golden path  
B. Drift-prone anti-pattern  
C. Only Helm mode  
D. A CRD  

**8.** Preview env per PR:  
A. Always prod  
B. Cuts lead time / risk  
C. Replaces DORA  
D. Needs cluster-admin in CI  

**9.** Management cluster runs Argo CD + Crossplane:  
A. Cannot be a platform  
B. Valid control plane for many workload clusters  
C. Merges etcd  
D. Forbids GitOps  

**10.** Developers must configure CNI, etcd snapshots, and IAM to ship hello-world:  
A. Good path  
B. Cognitive load leak  
C. TVP  
D. Restricted PSS  

**11.** Encoding SAST + image scan in the shared CI template:  
A. Against DevOps  
B. Good practice as default  
C. Replaces unit tests  
D. Replaces Git  

**12.** Push `kubectl` from CI vs pull GitOps:  
A. Identical  
B. Push spreads kubeconfigs and misses drift  
C. Push is more GitOps  
D. Pull cannot webhook  

**13.** Ephemeral runners for untrusted PRs:  
A. Useless  
B. Pipeline isolation  
C. DORA frequency  
D. mTLS  

**14.** Pin GitHub Actions to SHA:  
A. Useless  
B. Pipeline supply-chain hygiene  
C. Forbids CI  
D. Forbids CD  

**15.** OIDC from CI to cloud vs 10-year keys:  
A. Worse  
B. Short-lived, better  
C. Forbidden  
D. Backstage-only  

**16.** Generating NetworkPolicy per namespace via Kyverno:  
A. Ticket ops  
B. Tenancy by default  
C. DORA  
D. Tracing  

**17.** Policy PDF, no admission:  
A. Continuous conformance  
B. Not a policy engine  
C. GitOps  
D. OTel  

**18.** Unlimited cardinality custom metrics from every team:  
A. Always free  
B. Cost/perf risk; platform should guide  
C. Required by OTel  
D. Required by DORA  

**19.** Correlate deploy events with error rate:  
A. Only CSS  
B. Observability + CD working together  
C. Forbids traces  
D. Forbids Git  

**20.** Workload identity as copied cluster-admin kubeconfig:  
A. Zero trust  
B. Anti-pattern  
C. Golden path  
D. CAPI  

**21.** cert-manager as a platform capability:  
A. DORA  
B. Automates cert CRs  
C. Policy engine  
D. Portal  

**22.** Node OS patching owned by each app team:  
A. Correct  
B. Should be a platform/SRE capability  
C. DORA lead time name  
D. Catalog only  

**23.** North-south TLS and east-west mTLS:  
A. The same control  
B. Different planes; both may be needed  
C. Mesh always enough alone  
D. NetworkPolicy always enough alone  

**24.** ValidatingAdmissionPolicy (CEL) vs Kyverno:  
A. Only one can exist in a platform  
B. Both can encode guardrails; product choice  
C. Both are meshes  
D. Both are DORA  

**25.** SBOM in CI:  
A. Replaces RBAC  
B. Dependency inventory for response  
C. A mesh  
D. CAPI  

**26.** SLSA-style provenance:  
A. ClickOps  
B. Attests how the artifact was built  
C. A DORA name  
D. A trace  

**27.** Pipeline p95 duration SLO:  
A. etcd election  
B. Affects lead time; treat runners as a product  
C. Only BGP  
D. Only Ingress  

**28.** Language packs (Go vs Java templates):  
A. Against platforms  
B. Same product family, different paths  
C. Need different orgs always  
D. Forbid Git  

**29.** Deprecate pipeline v1 with no notice:  
A. Product practice  
B. Breaks the platform-as-product contract  
C. Required  
D. DORA elite  

**30.** Continuous **deployment** means:  
A. Monthly CAB only  
B. Auto all the way to prod (still usually Git)  
C. No artifacts  
D. No tests  

**31.** Who holds prod apply credentials?  
A. Every CI job  
B. GitOps agent + audited break-glass  
C. Every laptop  
D. Public Git  

**32.** Different Git repos per env but same digest:  
A. Illegal  
B. Valid promotion contract  
C. Forbids Helm  
D. Forbids Kustomize  

**33.** Auto-sync prod with no human review:  
A. Always most mature  
B. A risk choice; many platforms require prod PRs  
C. Required by Flux  
D. Required by Argo  

**34.** Emergency kubectl then forget Git:  
A. Best  
B. Drift; GitOps will fight or lie  
C. Updates OpenGitOps  
D. Is pull  

**35.** One microservice crashloop:  
A. Always whole-platform IR  
B. App on-call unless the path/cluster is causal  
C. Only DBAs  
D. Nobody  

**36.** Internal status page during GitOps outage:  
A. Useless  
B. Cuts duplicate tickets  
C. Replaces SLOs  
D. Replaces Git  

**37.** Game day: GitOps controller down:  
A. Against SRE  
B. Good IR rehearsal  
C. Only posters  
D. Only Backstage  

**38.** Freeze deploys while admission is broken:  
A. Never  
B. Valid mitigation if communicated  
C. Permanent maturity  
D. Weekly required  

**39.** CR with no controller:  
A. Still provisions cloud  
B. Inert API data  
C. Replaces Git  
D. Replaces OPA  

**40.** Finalizers:  
A. Reckless delete  
B. Cleanup external resources before CR removal  
C. Image sign  
D. Canary weight  

**41.** ACK / Config Connector:  
A. Meshes  
B. Cloud services as CRs  
C. CD UIs  
D. Log DBs  

**42.** Terraform laptop apply vs Crossplane GitOps:  
A. Same Kubernetes-native loop  
B. Laptop apply is weaker platform (less reconcile/RBAC/Git)  
C. Terraform is a CRD always  
D. Crossplane cannot GitOps  

**43.** Drift of cloud bucket vs XR:  
A. Ignore  
B. Reconcile or surface toward spec  
C. DORA only  
D. Backstage only  

**44.** OLM:  
A. A mesh  
B. Example of installing/upgrading operators  
C. OTel  
D. CAPI machines only  

**45.** Random Helm operators with cluster-admin:  
A. Golden path  
B. Shadow IT; productise approved operators  
C. Required PSS  
D. Required DORA  

**46.** SaaS wrapped as an operator:  
A. Against platforms  
B. Integration via K8s API on the path  
C. Requires ClickOps  
D. Forbids GitOps  

**47.** Software catalog should answer:  
A. Only image layers  
B. Who owns this, where is the API, what’s on-call  
C. Only TSDB  
D. Only kubeconfig  

**48.** Scaffolder that does not create CI/GitOps files:  
A. Complete golden start  
B. Incomplete path  
C. CAPI  
D. mTLS  

**49.** OSB-style service catalog vs Backstage:  
A. Identical  
B. Related IDP ideas: provision APIs vs DX metadata/templates  
C. Both meshes  
D. Both DORA  

**50.** RAG bot over approved docs/catalog APIs:  
A. Worse than unconstrained kubectl  
B. Grounded DX  
C. Illegal  
D. Replaces Git  

**51.** LLM applies YAML to prod:  
A. TVP  
B. High-risk unreviewed change  
C. GitOps  
D. SLSA  

**52.** GPU training jobs as a platform path:  
A. Cannot be IDP  
B. Another golden path for those users  
C. Laptop only  
D. Forbids Kubernetes  

**53.** Source of truth with AI in the loop:  
A. Chat history  
B. Git / CRs  
C. Weights  
D. Emoji  

**54.** SPACE vs DORA:  
A. Same four keys  
B. SPACE is broader developer productivity; DORA is delivery performance  
C. SPACE is a mesh  
D. DORA replaced SPACE entirely  

**55.** Empty deploys to game frequency:  
A. Elite  
B. Metric abuse  
C. Required  
D. TVP  

**56.** Fast deploys, no tests:  
A. All DORA keys improve  
B. Change failure rate can worsen  
C. Only MTTR improves  
D. Required  

**57.** Platform API p99 create-workspace SLO:  
A. Unrelated to DX  
B. Product efficiency; slow APIs are toil  
C. NetworkPolicy  
D. Trace ID  

**58.** Measuring only plugin count:  
A. Complete  
B. Vanity  
C. Forbidden legally  
D. The only DORA use  

**59.** Lead time includes waiting on the platform queue:  
A. Never  
B. Yes — your product is on the critical path  
C. Only CI compile  
D. Only DNS  

**60.** CNPA exam length:  
A. 90 minutes  
B. **120 minutes**, 60 MCQ, 75%, closed book  
C. 2h live cluster  
D. Open book white paper  

---

## Answer key

1B 2B 3B 4B 5B 6B 7B 8B 9B 10B  
11B 12B 13B 14B 15B 16B 17B 18B 19B 20B  
21B 22B 23B 24B 25B 26B 27B 28B 29B 30B  
31B 32B 33B 34B 35B 36B 37B 38B 39B 40B  
41B 42B 43B 44B 45B 46B 47B 48B 49B 50B  
51B 52B 53B 54B 55B 56B 57B 58B 59B 60B  

Missed product thinking → `WhichLayer.md`, `01.md`, `Maturity.md`.  
DORA → `22.md`, `DORA.md`. IDP → `20.md`, `IDP.md`.
