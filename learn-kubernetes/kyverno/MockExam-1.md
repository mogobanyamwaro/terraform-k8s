# Mock Exam 1

Timer: **90 minutes**. 60 questions. Closed book. Passing simulation: **45/60**.

Mix ≈ exam: Writing ~19, Fundamentals ~11, Install ~11, CLI ~7, Applying ~6, Management ~6.

Mark answers on paper. Key at the end.

---

**1.** Kyverno policies are written in:  
A. Rego only  
B. Kubernetes YAML (Kyverno CRs)  
C. CUE only  
D. PromQL  

**2.** `kind: ClusterPolicy` is:  
A. Namespaced only  
B. A Helm chart  
C. Cluster-scoped  
D. A webhook of kube-proxy  

**3.** A **validate** rule:  
A. Always creates a ConfigMap  
B. Checks the resource and can block or audit  
C. Is Cosign only  
D. Is `helm install`  

**4.** A **mutate** rule:  
A. Only reports  
B. Verifies Cosign  
C. Changes the resource  
D. Deletes namespaces  

**5.** A **generate** rule:  
A. Patches the same object only  
B. Creates additional resources  
C. Is CEL only  
D. Is Helm  

**6.** `match.any` means:  
A. AND  
B. Exclude only  
C. OR — any clause may match  
D. Background only  

**7.** Kyverno mutate runs in:  
A. etcd compaction  
B. Mutating admission webhook phase  
C. kube-scheduler  
D. CSI  

**8.** Webhook `failurePolicy: Fail` means:  
A. Policy Audit mode  
B. Always allow  
C. If Kyverno is down, deny the API request  
D. Skip RBAC  

**9.** `validationFailureAction: Audit` vs webhook failurePolicy:  
A. Identical knobs  
B. Both are Helm only  
C. Audit/Enforce is policy result; failurePolicy is webhook availability  
D. Both are CLI only  

**10.** Policy-as-OCI means:  
A. Replacing Kubernetes  
B. Storing/distributing policy YAML as registry artifacts  
C. PromQL in a container  
D. etcd in Harbor  

**11.** verifyImages vs policy-as-OCI:  
A. Identical  
B. Both are Helm hooks  
C. verifyImages checks **workload** images; OCI can also ship **policies**  
D. Both are PolicyReports  

**12.** Typical Helm install namespace:  
A. `kube-public`  
B. `kyverno`  
C. `default` required  
D. `kube-node-lease`  

**13.** After Helm install you should see:  
A. Only a Job  
B. Only kube-proxy  
C. Multiple Kyverno controller Deployments  
D. Only etcd  

**14.** ClusterPolicy is a:  
A. Built-in `apps/v1` kind  
B. Core Service  
C. Kyverno CRD  
D. Helm hook only  

**15.** Admission webhooks are served by:  
A. cleanup-controller only  
B. The admission-controller  
C. kube-scheduler  
D. CoreDNS  

**16.** PolicyReports are typically written by:  
A. kubelet  
B. etcd only  
C. reports-controller  
D. Helm  

**17.** CleanupPolicy cron is handled by:  
A. admission webhook only  
B. kube-proxy  
C. cleanup-controller  
D. Cosign  

**18.** HA admission means:  
A. One replica always  
B. Multiple admission-controller replicas + anti-affinity  
C. Only CLI HA  
D. Only cleanup HA  

**19.** Upgrade path:  
A. Delete namespace always  
B. `kubectl taint` only  
C. `helm upgrade` (+ CRD notes)  
D. Recreate kind only  

**20.** Single replica + Fail webhook + pod crash:  
A. No impact  
B. API requests using the webhook can fail  
C. etcd elects a Kyverno leader  
D. Autogen disables  

**21.** Users creating ClusterPolicy need:  
A. Only `get pods`  
B. Node SSH  
C. Permission to create ClusterPolicy  
D. etcd keys  

**22.** `helm uninstall` leftover ClusterPolicies:  
A. Impossible  
B. Always wipe etcd  
C. Can remain as CRs without webhooks  
D. Convert to Rego  

**23.** `kyverno apply pol.yaml --resource pod.yaml`:  
A. Installs Helm  
B. Evaluates the policy against the file  
C. Always mutates the live cluster  
D. Deletes the Policy CR  

**24.** `kyverno test` is for:  
A. Helm upgrades  
B. etcd defrag  
C. Structured policy unit tests  
D. Cosign keygen  

**25.** `kyverno jp` is for:  
A. Helm  
B. JMESPath (policy `{{ }}` language)  
C. etcd  
D. PDB  

**26.** apply vs kubectl apply of policy YAML:  
A. Identical  
B. CLI apply tests; kubectl apply installs the CR  
C. CLI apply installs Helm  
D. kubectl apply runs jp  

**27.** Expected `result: fail` when the Pod is good:  
A. Ideal  
B. Installs CRDs  
C. The test fails (expectation mismatch)  
D. Enables HA  

**28.** CLI without a cluster:  
A. Useless  
B. Only Helm works  
C. `apply`/`test` on files still work  
D. Only jp works  

**29.** kubectl JSONPath vs jp:  
A. Identical always  
B. JSONPath is required in ClusterPolicy  
C. Related idea; policies use JMESPath  
D. jp is Rego  

**30.** To enforce in-cluster you must:  
A. Only run laptop `apply`  
B. Create the Policy/ClusterPolicy in the cluster  
C. Only install krew  
D. Only set PDB  

**31.** `validationFailureAction: Enforce`:  
A. Always Audit  
B. Rejects the API request on validate fail  
C. Disables reports  
D. Disables match  

**32.** Safe rollout of a deny policy:  
A. Enforce first always  
B. Delete admission-controller  
C. Audit, review reports, then Enforce  
D. Set replicas to 0  

**33.** `background: false`:  
A. Mandatory  
B. Skip existing-object scans  
C. Disables the CLI  
D. Deletes reports CRD  

**34.** Excluding `kube-system`:  
A. Never needed  
B. Common to avoid breaking cluster components  
C. Disables Enforce  
D. Required for CLI  

**35.** `names: ["nginx-*"]` in match:  
A. JSON 6902  
B. Image digest  
C. Glob on resource name  
D. JMESPath only  

**36.** `validate.pattern` is:  
A. A Helm chart  
B. An overlay the resource must satisfy  
C. Cosign only  
D. A webhook CRD  

**37.** Preconditions exist to:  
A. Replace match  
B. Install Helm  
C. Skip the rule unless extra conditions hold  
D. Sign images  

**38.** `?*` in a pattern:  
A. Helm glob  
B. Always optional  
C. Field must exist (wildcard value)  
D. Image digest  

**39.** Background failing validate:  
A. Always deletes the Pod  
B. Records a report (no magic eviction)  
C. Uninstalls Kyverno  
D. Changes failurePolicy  

**40.** `patchStrategicMerge` is:  
A. RFC 6902 only  
B. PromQL  
C. Kubernetes strategic-merge overlay  
D. Cosign  

**41.** `patchesJson6902` is:  
A. Helm values  
B. JSON Patch add/replace/remove  
C. A PolicyReport  
D. Autogen  

**42.** `generate.data`:  
A. Cosign  
B. Helm repo  
C. Inline resource spec to create  
D. PDB  

**43.** `generate.clone`:  
A. JSON 6902  
B. Copy an existing source object  
C. verifyImages  
D. `kyverno jp`  

**44.** `synchronize: true`:  
A. Disable background  
B. Audit only  
C. Keep generated object aligned; revert drift  
D. OCI only  

**45.** verifyImages is for:  
A. Helm chart versions  
B. Cosign/Sigstore on workload images  
C. PolicyReport syntax  
D. PDB  

**46.** `mutateDigest: true`:  
A. Deletes the image  
B. Disables Cosign  
C. Rewrites tag to digest  
D. Sets Audit  

**47.** Autogen exists so:  
A. Helm upgrades  
B. Cosign rotates  
C. Pod rules also apply to workload controllers  
D. Reports CRDs install  

**48.** `context.apiCall`:  
A. Illegal  
B. Uninstalls Kyverno  
C. Fetches Kubernetes API data during evaluation  
D. Is JSON 6902  

**49.** CleanupPolicy is:  
A. A validate pattern  
B. A CR that deletes matching resources on a schedule  
C. Helm uninstall  
D. `kyverno apply` only  

**50.** CEL in Kyverno validate:  
A. Illegal  
B. Only Gatekeeper  
C. `validate.cel.expressions`  
D. Only Cosign  

**51.** `{{ request.operation }}`:  
A. Always GENERATE  
B. Only Audit  
C. CREATE/UPDATE/DELETE/CONNECT  
D. Only clone  

**52.** Mutating a running Pod’s image:  
A. Always works  
B. Required  
C. Often rejected — spec mostly immutable  
D. CLI-only  

**53.** `foreach` on validate:  
A. Illegal  
B. Only generate  
C. Applies checks to each list element  
D. Only OCI  

**54.** `generateExisting`:  
A. CLI-only  
B. A pattern `?*`  
C. Generate for already-existing triggers  
D. Webhook timeout  

**55.** PolicyReport is:  
A. A Helm release  
B. A CR of pass/fail results  
C. A Cosign key  
D. `kyverno jp` only  

**56.** Result `fail` in Audit:  
A. Request was blocked  
B. Helm failed  
C. Resource violated but was allowed  
D. CRDs missing  

**57.** PolicyException is for:  
A. Helm upgrades  
B. Exempting matched subjects from named rules  
C. Installing CRDs  
D. `kyverno jp`  

**58.** Exception vs Audit:  
A. Identical  
B. Both delete Pods  
C. Exception skips the rule; Audit still evaluates and reports  
D. Both are generate.clone  

**59.** Kyverno metrics are typically:  
A. PromQL stored in etcd  
B. PolicyReport YAML only  
C. Prometheus `/metrics` on controllers  
D. Helm NOTES only  

**60.** KCA exam format:  
A. 2h live cluster  
B. 60 MCQ, 90 min, 75%, closed book  
C. Oral  
D. Open book kyverno.io  

---

## Answer key

1B 2C 3B 4C 5B 6C 7B 8C 9C 10B  
11C 12B 13C 14C 15B 16C 17C 18B 19C 20B  
21C 22C 23B 24C 25B 26B 27C 28C 29C 30B  
31B 32C 33B 34B 35C 36B 37C 38C 39B 40C  
41B 42C 43B 44C 45B 46C 47C 48C 49B 50C  
51C 52C 53C 54C 55B 56C 57B 58C 59C 60B  

Missed 1–11 → `01.md`–`04.md`, `Architecture.md`.  
Missed 12–22 → `05.md`–`08.md`.  
Missed 23–29 → `09.md`–`11.md`, `CLI.md`.  
Missed 30–35 → `12.md`–`13.md`.  
Missed 36–54 → `14.md`–`20.md`, `Validate.md`, `MutateGenerate.md`, `VerifyImages.md`.  
Missed 55–59 → `21.md`–`22.md`.  
Format → `00.md`.
