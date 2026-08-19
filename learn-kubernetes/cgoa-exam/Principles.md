# The Four GitOps Principles (Deep Dive)

Largest exam domain (**30%**). If a question names a tool, still answer from these pillars.

## 1. Declarative

Desired state is **what**, not **how**.

**Satisfies:** Kubernetes YAML, Helm values, Kustomize, Terraform HCL as the description of end state, Crossplane/CRs.

**Fails:** A Git repo whose “truth” is a shell script of API calls, a wiki checklist, ClickOps in a console, Jenkins freestyle “then kubectl these five objects that are not in Git”.

Storing imperative scripts **in Git** does not make them declarative desired state.

## 2. Versioned and Immutable

The store keeps **history**. You do not silently overwrite the only copy.

**Satisfies:** Git commits, tags, protected branches, OCI artifacts with **digests**, object storage with **versioning** and no in-place clobber.

**Fails:** `:latest` images, floating Helm chart `*`, `s3://bucket/app.yaml` overwritten in place, `git push --force` rewriting prod history as normal process, wiki “current config”.

**Rollback** uses this principle: add a **new** version that restores old content. You do not rewrite history as the default undo.

## 3. Pulled Automatically

A **software agent** fetches declarations from the store. Humans and CI do not push live applies as the control plane.

**Satisfies:** Flux, Argo CD, Config Sync, an in-cluster or management-cluster controller that lists Git/OCI on an interval.

**Fails:** GitHub Action `kubectl apply`, Jenkins SSH to nodes, a human clicking Sync as the **only** mechanism, a webhook that is the **only** trigger with no poll.

**Webhooks** are allowed as **accelerators**. The agent must still be able to pull on its own (interval). If Git is updated while the webhook is down, a true GitOps agent still converges.

## 4. Continuously Reconciled

The agent **keeps** comparing actual vs desired and **attempts** to apply.

**Satisfies:** Controllers with an interval, self-heal, prune, Terraform/Crossplane loops that re-plan.

**Fails:** One-shot apply on merge, “sync once and uninstall the agent”, apply only when a human opens the UI.

**Continuous ≠ instantaneous.** A 5-minute interval is still continuous. Instant webhook-only with no loop is not.

**Attempt** matters: if apply fails, the agent retries and surfaces **feedback**; it does not pretend the cluster matches Git.

## Common Violation Matrix

| Practice | Declarative | Versioned | Pulled | Reconciled |
| --- | :---: | :---: | :---: | :---: |
| YAML in Git + Flux/Argo | Y | Y | Y | Y |
| YAML in Git + CI `kubectl apply` once | Y | Y | N | N |
| Helm in Git, `:latest` image | Y | N | Y | Y |
| Makefile of kubectl in Git as truth | N | Y | ? | ? |
| ClickOps then export YAML later | N | N | N | N |
| Webhook-only, no poll, no retry loop | Y | Y | Weak | N |

## Exam Reasoning

Ask in order: **declared?** **stored immutably with history?** **agent pulls?** **loop still running?** One “no” and it is not GitOps, even if the vendor slide says GitOps.
