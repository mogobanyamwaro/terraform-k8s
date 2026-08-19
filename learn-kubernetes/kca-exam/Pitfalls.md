# KCA Pitfalls

1. Treating KCA as **CKS** — closed-book MCQ, not a live cluster.
2. Treating Kyverno as **Gatekeeper** — **YAML**, not Rego.
3. **Policy vs ClusterPolicy** swapped.
4. **Audit vs Enforce** swapped.
5. **Webhook failurePolicy** vs **validationFailureAction**.
6. `kyverno apply` thought to **install** the CR.
7. `kyverno test` vs ad-hoc apply.
8. **any vs all** (OR vs AND).
9. Matching **Pod** only and forgetting **autogen** / controller admission.
10. **Background** expected to **delete** bad Pods.
11. **generate** confused with **mutate**.
12. **clone** vs **data**.
13. `synchronize: false` expected to revert drift.
14. JSON 6902 path vs JMESPath `{{ }}`.
15. kubectl **jsonpath** vs **jp**.
16. Mutating **immutable** Pod spec after create.
17. **verifyImages** vs policy-as-OCI.
18. Signature vs **attestation**.
19. CleanupPolicy as a validate rule.
20. **CEL** skipped because overlay exists.
21. PolicyException as Audit mode.
22. Reports disabled then wondering why Audit is invisible.
23. Single admission replica + **Fail** webhook.
24. `helm uninstall` assumed to wipe CRDs/policies.
25. Missing RBAC blamed as “generate bug.”
26. Excluding **kube-system** too late (lockout).
27. `:latest` allowed because `*` matched.
28. Preconditions vs match — empty skip vs fail.
29. `?*` vs optional field.
30. Closed book: drill **which YAML key** lives where.
