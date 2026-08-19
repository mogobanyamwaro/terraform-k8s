# Mock Exam 2

Timer: **90 minutes**. 60 questions. Closed book. Passing simulation: **45/60**. Harder distractors than Mock 1.

Same mix: Writing ~19, Fundamentals ~11, Install ~11, CLI ~7, Applying ~6, Management ~6.

Mark answers on paper. Key at the end.

---

**1.** Namespaced `Policy` in `dev` plus a Pod in `prod`:  
A. Always evaluated  
B. Typically **not** in scope of that Policy  
C. Always Enforce  
D. Always generate  

**2.** One rule with both `validate` and `mutate` maps:  
A. The usual style  
B. Split into separate named rules  
C. Required  
D. How ClusterPolicy works  

**3.** Validate sees the object **after** mutate in the same admission chain:  
A. Never  
B. Usually yes (mutating webhooks first)  
C. Only for generate  
D. Only for CLI  

**4.** `failurePolicy: Ignore` on the **webhook**:  
A. Enforce all policies  
B. Kyverno down → requests **proceed**  
C. Delete CRDs  
D. Disable Helm  

**5.** Short `webhookTimeoutSeconds`:  
A. Always faster success  
B. Deadlines / fail per failurePolicy  
C. Autogen off  
D. OCI pull always  

**6.** Signing a **policy** OCI artifact:  
A. Illegal  
B. Consumers can verify the policy pack like an image  
C. Replaces ClusterPolicy CRDs  
D. Disables admission  

**7.** `imageRegistry` context vs verifyImages:  
A. Identical  
B. Registry lookup for metadata vs Cosign/attestation check  
C. Both are Helm  
D. Both are PDB  

**8.** `match.all` two clauses kinds=Pod AND namespace=prod:  
A. OR  
B. Resource must satisfy **both**  
C. Always skip  
D. CLI-only  

**9.** Direct etcd edit bypassing the API:  
A. Normal GitOps  
B. Admission **does not** see it  
C. Always mutated  
D. Always reported  

**10.** `apiVersion: kyverno.io/v1` vs Exception `v2`:  
A. Impossible mix  
B. Different CRs may use different versions  
C. v2 is Helm only  
D. v1 is CLI only  

**11.** Autogen off, match Deployment only, user creates a naked Pod:  
A. Deployment rule always catches it  
B. That Deployment rule does **not** select the Pod  
C. Always Enforce  
D. Always skip background  

**12.** Chart values vs ClusterPolicy YAML:  
A. Identical  
B. Values configure **controllers**; ClusterPolicy is **rules**  
C. Values are validate.pattern  
D. ClusterPolicy sets replicaCount  

**13.** Reports CRDs missing, admission still up:  
A. Impossible  
B. Enforce can work; **reports** won’t persist  
C. etcd deletes  
D. Helm repo vanishes  

**14.** background-controller without list Pods:  
A. Faster admission  
B. Pod background scans fail/skip  
C. Helm uninstalls  
D. CRDs delete  

**15.** Scaling reports-controller:  
A. Changes mutate order  
B. Helps report throughput more than user admission RTT  
C. Replaces admission replicas  
D. Disables exceptions  

**16.** Upgrade skipping notes:  
A. Best practice  
B. CRD/webhook break risk  
C. Required  
D. Enables CEL  

**17.** PDB `minAvailable` on admission during drain:  
A. A ClusterPolicy  
B. Keeps webhook pods available  
C. Signs images  
D. Is `kyverno test`  

**18.** Kyverno SA needs create NetworkPolicy:  
A. Only for validate.pattern  
B. For **generate** of NetworkPolicy  
C. For `kyverno jp`  
D. For Cosign  

**19.** Private registry for controller images:  
A. Impossible  
B. Override Helm image values  
C. Only PolicyException  
D. Only jp  

**20.** `UpdateRequest` objects:  
A. User ClusterPolicies  
B. Internal generate/sync work  
C. kubectl plugins  
D. OCI artifacts  

**21.** Splitting controllers into Deployments:  
A. Illegal  
B. Scale admission independently of reports  
C. Disables YAML  
D. Removes webhooks  

**22.** Resource requests on admission pods:  
A. Only Grafana  
B. Protect the webhook from CPU/OOM  
C. Set Audit  
D. Set match.any  

**23.** `apply --cluster` needs:  
A. No kubeconfig  
B. kubeconfig to live objects  
C. Uninstall Kyverno  
D. Sign OCI  

**24.** Green `kyverno test` then forgot `kubectl apply` of the policy:  
A. Cluster still Enforces  
B. Cluster does **not** have the CR — no admission  
C. Tests install CRDs  
D. Tests set PDB  

**25.** Mutate test fixtures:  
A. Only validate  
B. Can assert the **patched** YAML  
C. Only in-cluster  
D. Only Rego  

**26.** Empty `{{ request.object.spec.foo }}`:  
A. Always webhook outage  
B. Debug with `jp` on sample YAML  
C. Helm only  
D. Cosign only  

**27.** CI `kyverno test ./policies`:  
A. Uninstalls Kyverno  
B. Runs fixtures under that path  
C. Starts kind always  
D. Signs images  

**28.** CLI much older than cluster:  
A. Always fine  
B. Missing rule types / flags risk  
C. Required for Audit  
D. Disables CRDs  

**29.** `skip` result in tests:  
A. etcd down  
B. Rule did not select (match/precondition)  
C. Helm repo  
D. PDB  

**30.** `validationFailureActionOverrides` per namespace:  
A. Helm only  
B. Mix Audit/Enforce by NS  
C. Cosign  
D. jp only  

**31.** `admission: false` on a policy:  
A. Helm only  
B. Not on the webhook path (background/reports still possible)  
C. Deletes CRDs  
D. Forces Enforce  

**32.** Matching requestor `clusterRoles`:  
A. Illegal  
B. Filters by **who** called the API  
C. Creates ClusterRoles  
D. Is PolicyReport  

**33.** `operations: [DELETE]` on a validate:  
A. Default for all  
B. Fires on delete  
C. Always mutate  
D. Always generate  

**34.** GitOps apply of ClusterPolicy:  
A. Illegal  
B. Normal (same as kubectl apply of CRs)  
C. Replaces Helm Kyverno  
D. Replaces CRDs  

**35.** Removing ClusterPolicy after mutate added labels:  
A. Rewinds all labels  
B. Stops future admission; old fields remain  
C. Deletes all Pods  
D. Uninstalls Helm  

**36.** deny conditions vs pattern:  
A. Identical YAML  
B. Two validate styles; deny is JMESPath conditions  
C. Deny is mutate  
D. Pattern is CLI-only  

**37.** Conditional anchor `(securityContext)`:  
A. Deletes the field  
B. Inner constraints **if** the field exists  
C. Forces Enforce  
D. Is autogen  

**38.** `mutateExistingOnPolicyUpdate`:  
A. CLI only  
B. Can patch **already stored** objects when policy changes  
C. Audit only  
D. OCI only  

**39.** JSON Patch escape of `/` in a key:  
A. JMESPath `[]`  
B. `~1` in the path  
C. match.kind  
D. OCI  

**40.** Strategic merge of containers:  
A. Always index 0  
B. Merge key usually `name`  
C. Only JSON 6902  
D. Only CEL  

**41.** `synchronize: false` generate:  
A. Illegal  
B. Create once; later edits not forced back  
C. Always clone  
D. Always Enforce  

**42.** Two policies generating the same child name:  
A. Ideal  
B. Conflict / fight over ownership  
C. Required for HA  
D. CLI-only  

**43.** Keyless attestors:  
A. etcd  
B. Identity (issuer/subject), not a static public key  
C. PromQL  
D. Strategic merge  

**44.** Attestation vs signature:  
A. Identical  
B. Attestation is extra in-toto/predicate; signature is the image  
C. Both are Helm  
D. Both are cleanup  

**45.** Autogen disabled, match Pod, `kubectl apply -f deploy.yaml`:  
A. Always denied by that Pod rule  
B. Deployment object may **miss** the Pod-only rule  
C. CLI breaks  
D. CRDs vanish  

**46.** ConfigMap context allowlist:  
A. Only OCI  
B. Loads allow/deny data without baking it in the policy  
C. A webhook  
D. PDB  

**47.** API call context without RBAC:  
A. Faster  
B. Empty/error variable  
C. Enforce off  
D. Autogen on  

**48.** Cleanup vs background validate fail:  
A. Identical  
B. Cleanup **deletes**; background **reports**  
C. Both always Enforce  
D. Both JSON 6902  

**49.** CEL `object.spec` is:  
A. Helm  
B. The resource being evaluated  
C. PolicyReport  
D. PDB  

**50.** Overlay pattern **and** CEL in the product:  
A. Only one allowed ever  
B. Both are official validate styles  
C. CEL is mutate only  
D. pattern is verifyImages  

**51.** `time_since` on cleanup conditions:  
A. generate.clone  
B. Typical “older than 24h” delete  
C. jp install  
D. Exception required  

**52.** foreach over `spec.containers`:  
A. Illegal  
B. Check each container (e.g. no `:latest`)  
C. Only cluster-scoped  
D. Only Cosign  

**53.** `required: true` on verifyImages + unsigned + Enforce:  
A. Always allowed  
B. Admission denied  
C. Helm warning only  
D. CRDs removed  

**54.** `+(label)` / add-if-not-present mutate:  
A. validate.deny  
B. Mutate overlay (don’t overwrite existing)  
C. cleanup schedule  
D. test name  

**55.** Result `error` on a PolicyReport:  
A. Always pass  
B. Engine/eval problem, not a clean pass/fail  
C. Helm repo  
D. PDB  

**56.** Broad exception `kinds: ['*']`:  
A. Best practice  
B. Dangerous — narrow it  
C. Required  
D. CLI-only  

**57.** Who may create PolicyExceptions:  
A. Anyone with `get pods`  
B. A privileged action (bypass)  
C. Same as `kyverno apply` on a laptop  
D. Same as Cosign verify  

**58.** ServiceMonitor in the Kyverno chart:  
A. A ClusterPolicy  
B. Optional Prometheus scrape of controller metrics  
C. A mutate patch  
D. Autogen  

**59.** Reports disabled, policy in Audit:  
A. Violations still obvious in PolicyReport CRs  
B. Admission allows; you **lose** the CR report trail  
C. Enforce starts  
D. Autogen forces on  

**60.** Closed-book KCA passing score:  
A. 64%  
B. 75% (45/60)  
C. 90%  
D. No score; lab only  

---

## Answer key

1B 2B 3B 4B 5B 6B 7B 8B 9B 10B  
11B 12B 13B 14B 15B 16B 17B 18B 19B 20B  
21B 22B 23B 24B 25B 26B 27B 28B 29B 30B  
31B 32B 33B 34B 35B 36B 37B 38B 39B 40B  
41B 42B 43B 44B 45B 46B 47B 48B 49B 50B  
51B 52B 53B 54B 55B 56B 57B 58B 59B 60B  

Missed 1–11 → `01.md`–`04.md`.  
Missed 12–22 → `05.md`–`08.md`.  
Missed 23–29 → `09.md`–`11.md`.  
Missed 30–35 → `12.md`–`13.md`.  
Missed 36–54 → `14.md`–`20.md`.  
Missed 55–59 → `21.md`–`22.md`.  
Score → `00.md`, `CheatSheet.md`.
