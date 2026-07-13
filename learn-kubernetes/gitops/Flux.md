# Flux / GitOps Toolkit (Enough for CGOA)

Again: **engine**, not a Flux administrator cert.

## What It Is

CNCF **Flux**. Modern Flux is the **GitOps Toolkit**: small controllers that compose.

| Controller | Job |
| --- | --- |
| Source (Git, OCI, Helm, Bucket) | **Pull** artifacts; verify (optional Cosign) |
| Kustomize | Reconcile a path of YAML/Kustomize |
| Helm | HelmRelease: in-cluster Helm based on a versioned chart + values |
| Notification | Alerts to Slack/etc. — **human feedback** |
| Image automation | Detect new tags, **commit to Git** (not kubectl apply) |
| Image reflector | Scan registries |

`flux bootstrap` writes Flux’s **own** manifests into Git and installs controllers — GitOps for the engine itself.

## Typical objects (recognise, don’t memorise CRD YAML)

```yaml
# GitRepository + Kustomization is the exam-shaped pair
kind: GitRepository   # state store pointer
kind: Kustomization   # reconcile loop: interval, prune, wait
kind: HelmRelease     # chart packaging
kind: OCIRepository   # alternative store
```

`spec.interval` on Source and Kustomization = **continuous** pull/reconcile. Webhooks (`Receiver`) speed this up.

## GitOps mapping

| Principle | Flux behaviour |
| --- | --- |
| Declarative | Kustomization/HelmRelease specs + app YAML |
| Versioned and Immutable | Git SHA, OCI digest, pinned chart |
| Pulled Automatically | Source controller |
| Continuously Reconciled | Kustomize/Helm controllers; health checks |

Image automation that **writes Git** is CI-shaped **interoperability** that still keeps the cluster applier inside Flux.

## Argo vs Flux on the exam

Neither is “more GitOps”. Flux is more **composable/platform**; Argo CD is more **app UI + Application model**. Questions that pick a winner for “which is GitOps” are trick questions — **both can be**, if configured to pull and reconcile.

## Jenkins X and others

Listed so you know the **landscape**: other engines exist (Fleet, Config Sync, homegrown). Same test: four principles, not the logo.
