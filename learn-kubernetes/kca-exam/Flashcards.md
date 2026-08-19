# Flashcards

Cover the right column. Night before and morning of.

## Meta

| Prompt | Answer |
| --- | --- |
| Format | Closed-book **MCQ**, 60 / 90 min / **75%** |
| Largest domain | **Writing Policies 32%** |
| Fundamentals / Install | **18% / 18%** |
| CLI / Apply / Manage | **12% / 10% / 10%** |
| Language | **YAML**, not Rego |

## Fundamentals

| Prompt | Answer |
| --- | --- |
| Cluster vs namespaced | **ClusterPolicy / Policy** |
| Four rules | **validate, mutate, generate, verifyImages** |
| any / all | **OR / AND** |
| Mutate webhook phase | **MutatingAdmission** |
| Validate webhook phase | **ValidatingAdmission** |
| Webhook down + Fail | **Deny API requests** |
| Audit vs webhook Fail | **Different knobs** |
| Policy-as-OCI | **Distribute YAML artifacts** |

## Install

| Prompt | Answer |
| --- | --- |
| Helm ns | **kyverno** |
| Four controllers | **admission, background, reports, cleanup** |
| HA | **admission replicas + PDB** |
| Upgrade | **helm upgrade + notes** |

## CLI

| Prompt | Answer |
| --- | --- |
| Shift-left one-shot | **`kyverno apply`** |
| Fixtures | **`kyverno test`** |
| JMESPath REPL | **`kyverno jp`** |
| apply vs kubectl apply | **test vs install CR** |

## Apply / write

| Prompt | Answer |
| --- | --- |
| Allow + report | **Audit** |
| Deny request | **Enforce** |
| Required any value | **`?*`** |
| Skip rule unless | **preconditions** |
| Existing objects | **background** |
| Overlay mutate | **patchStrategicMerge** |
| RFC 6902 | **patchesJson6902** |
| Inline generate | **data** |
| Copy generate | **clone** |
| Own the child | **synchronize: true** |
| Cosign | **verifyImages** |
| Tag → digest | **mutateDigest** |
| Pod controllers | **autogen** |
| Cron delete | **CleanupPolicy** |
| K8s expressions | **CEL** |

## Manage

| Prompt | Answer |
| --- | --- |
| Results CR | **PolicyReport** |
| Skip named rules | **PolicyException** |
| Prometheus | **controller /metrics** |
