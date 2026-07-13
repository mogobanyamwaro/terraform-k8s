# CNPE Pitfalls

1. Treating CNPE like CNPA (no YAML to apply).
2. Working on hostname `base` instead of SSH `host`.
3. Rebooting `base`.
4. Googling; following k8s.io off-site links.
5. Waiting 15 minutes on the first GitOps task.
6. Flux `path` wrong (`./kustomize` vs `/kustomize`).
7. Argo Application in the app namespace instead of `argocd`.
8. ServiceMonitor labels ≠ Prometheus selector.
9. ServiceMonitor `port:` as a number instead of port **name**.
10. Kyverno matching Deployment only — Pods still violate.
11. PSS restricted + nginx root — apply succeeds, pods fail.
12. Default-deny egress without DNS.
13. HPA without metrics-server — object still required.
14. Crossplane Claim while editing Composition unasked.
15. `cluster-admin` for app groups.
16. kubectl-fixing a GitOps object that **selfHeals** back.
17. Canary without deleting the old Deployment.
18. `pause: {}` when the task wanted a timed pause.
19. Tekton `v1alpha1` copied from a blog.
20. CRD without `required` / enum mismatch.
21. Forgetting `workspaces/status` RBAC.
22. OpenCost UI rabbit hole when labels/right-size would score.
23. Istio YAML when the task only needed NetworkPolicy.
24. `:latest` in your own solution images.
25. No partial apply — empty cluster scores zero.
26. Killer.sh session unused (two attempts are in the price).
27. Pass is **64%**, not 75%.
28. Nested SSH.
29. Ctrl+W closing the browser tab.
30. Closed-book muscle memory — **use Quick Reference**.
