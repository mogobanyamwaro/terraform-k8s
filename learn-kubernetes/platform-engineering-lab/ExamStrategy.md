# Exam Strategy

## Time

17 tasks × 120 min ≈ **7 minutes** average. GitOps and Crossplane tasks run long (wait for sync). Start them, work another item, come back.

Killer.sh has **20** items. The real exam is **15–20**. Pass **64%** — you can miss several whole tasks.

## Desktop

- `ssh cnpe-xxx` as the infobox says. `exit` when done.
- Copy in terminal: **Ctrl+Shift+C / V**
- `k` = kubectl. `yq` is there.
- Firefox: Ctrl+F on docs. Quick Reference links are **the** allowed tool docs.

## Docs map (build this before exam day)

| Need | Where |
| --- | --- |
| CRD, RBAC, Quota, Probe | kubernetes.io |
| Application YAML | Argo CD docs *Getting Started* / Application CR |
| GitRepository | Flux docs |
| Pipeline | Tekton docs `Pipeline` |
| ClusterPolicy | Kyverno docs |
| ConstraintTemplate | Gatekeeper docs |
| XRD / Claim | Crossplane docs |
| ServiceMonitor | Prometheus operator API |
| Rollout | Argo Rollouts or Flagger |

## Partial credit

A correct Application that is OutOfSync still beats nothing. A Kyverno policy that exists but is slightly wrong may score a subset. **Apply something valid with the required names.**

## Do not

- Reboot `base`
- Nested SSH
- Google
- Follow kubernetes.io links off-site
- Wait 10 minutes for a Crossplane provider without checking `kubectl describe`
