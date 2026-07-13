# CGOA Pitfalls

1. Treating CGOA as an **Argo CD** or **Flux** admin exam — it is **OpenGitOps**.
2. Thinking **Git in a repo** automatically means GitOps (imperative scripts, CI apply).
3. **Declarative** = “stored in Git”. Declarative means **what, not how**.
4. **Desired state** includes the production database dump — usually **it does not**.
5. **State store** = **etcd** — etcd is **actual** cluster state.
6. Git is the **only** legal store — alternatives must still be versioned/immutable/ACL/auditable.
7. **Continuous** = instantaneous / real-time.
8. Webhook as the **only** trigger, no poll — agents must still **pull**.
9. Webhooks are “forbidden in GitOps” — they **accelerate** pull.
10. CI `kubectl apply` / `helm upgrade` from the runner as CD — **push**, not GitOps.
11. `:latest` or floating chart `*` as “fine if GitOps” — violates **Versioned and Immutable**.
12. Rollback = `kubectl rollout undo` while Git still has the new spec — **drift**; agent may revert **you**.
13. Rollback = `git push --force` rewriting prod history as the normal path — not how **immutable** history is used.
14. One-shot apply on merge, then uninstall the agent — fails **Continuously Reconciled**.
15. Manual Sync button as the **only** reconcile — weak / not continuous.
16. **Self-heal off** + humans kubectl forever — Git is not the winner.
17. Pull vs push confused with **in-cluster vs management cluster**.
18. Management cluster Argo = “not GitOps because the agent is external”.
19. Event-driven GitOps = CI applies on image webhook.
20. **Deploy** and **release** used as synonyms.
21. Progressive delivery analysis that only lives in a push pipeline.
22. CaC / IaC / DevOps / GitOps as **the same word**.
23. DevSecOps = “we use Git” — still need review, ACL, no raw secrets, policy on config PRs.
24. Raw production secrets in Git as desired state.
25. Kustomize vs Helm as “one is GitOps, one is not”.
26. Rendering in CI vs in-cluster Helm — **both can be GitOps** if Git holds inputs and an agent reconciles.
27. Flux image automation that **commits to Git** mistaken for `kubectl apply` from CI.
28. Notifications **replace** the reconciler.
29. Observability **is** the state store.
30. Feedback = only Prometheus, never Slack to humans.
31. Break-glass kubectl **without** a follow-up Git commit.
32. App-of-Apps / root Kustomization = a new principle — it is **composition**.
33. Choosing Argo **or** Flux as the only correct engine.
34. Closed book: you cannot open opengitops.dev — drill the **four sentences** and glossary.
