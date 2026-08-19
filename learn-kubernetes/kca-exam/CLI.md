# CLI (Deep Dive)

```bash
# install: krew / GitHub release
kyverno apply policy.yaml --resource pod.yaml
kyverno apply policy.yaml --cluster
kyverno test .
kyverno jp query -i pod.yaml 'spec.containers[].image'
```

| Command | Job |
| --- | --- |
| apply | One-shot evaluate |
| test | Fixtures + expected pass/fail |
| jp | JMESPath = `{{ }}` language |

`apply` does **not** install CRs. `kubectl apply` does.

CI: `kyverno test` must be green before merge.
