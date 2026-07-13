# CAPA Pitfalls

1. Treating CAPA as **Argo CD only** — Workflows is **36%**.
2. Treating CAPA as **CGOA** — principles help, but you need **Argo CRDs**.
3. **Workflows** as GitOps CD (`kubectl` in a loop vs Application controller).
4. **Argo CD** as a DAG/ETL engine.
5. **Rollouts** as Git clone/Helm render.
6. **Events** as Argo CD’s Git webhook / 3-minute refresh.
7. Lowercase **template** vs **WorkflowTemplate** vs **AnalysisTemplate**.
8. `{{steps}}` inside a **DAG** (use `{{tasks}}`).
9. Inner vs outer **steps** lists (parallel vs sequential).
10. Cycles in a DAG; forgetting `failFast`.
11. Huge files as **parameters** instead of **artifacts**/PVC.
12. Artifact S3 confused with GitOps **state store**.
13. CronWorkflow vs Events **calendar** vs CD webhook.
14. Thinking Events **requires** Workflows always.
15. Trigger as its own CRD — it lives on the **Sensor**.
16. EventSource talking **directly** to Sensor, skipping **EventBus**.
17. NATS Streaming as the modern bus (it is **deprecated**).
18. Sync status = health status.
19. Refresh = sync (look vs apply).
20. Auto-sync **without prune** still deletes orphans — it does **not**.
21. Auto-sync **without selfHeal** still reverts kubectl — it does **not**.
22. `destination.namespace` = where Argo CD itself runs — usually **app** namespace.
23. App-of-Apps = ApplicationSet (related, **not** the same).
24. Helm `targetRevision` always a Git branch — often a **chart version**.
25. Sync-wave **higher** numbers first — **lower** first.
26. PreSync hook = Rollouts analysis.
27. CD `rollingUpdate` = canary with Prometheus abort.
28. Blue-green = `setWeight: 10`.
29. Empty `pause: {}` as 0 seconds — it **waits for promote**.
30. AnalysisRun = AnalysisTemplate.
31. Failed analysis = Git prune.
32. Promote = `argocd app sync`.
33. `resource` workflow template = Argo CD Application.
34. `suspend` template = Rollout pause (different products).
35. Closed book: drill **which tool** + the four Events names.
