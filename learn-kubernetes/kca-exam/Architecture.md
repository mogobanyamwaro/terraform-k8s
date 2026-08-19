# Architecture (Deep Dive)

Admission + four controllers. Docs: [kyverno.io](https://kyverno.io/docs/).

```text
API request
  MutatingWebhook  → mutate rules
  ValidatingWebhook → validate / verifyImages
  etcd

background-controller → existing objects, generate/sync, mutate-existing
reports-controller    → PolicyReport CRs
cleanup-controller    → CleanupPolicy cron deletes
```

| Kind | Scope |
| --- | --- |
| Policy | Namespace |
| ClusterPolicy | Cluster |
| PolicyException | Skip rules |
| CleanupPolicy | Scheduled delete |

Helm chart into `kyverno`. Webhook **failurePolicy** (Kyverno down) ≠ **validationFailureAction** (Audit/Enforce).

HA: admission replicas + PDB. Fail-closed webhook + 0 pods = outage.
