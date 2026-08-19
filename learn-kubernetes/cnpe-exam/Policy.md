# Policy Engines (Exam)

## Kyverno

`ClusterPolicy` / `Policy`. `validationFailureAction: Enforce|Audit`. Match `kinds: [Pod]` + `namespaces:`.

Mutate for defaults; validate for gates; generate for NetworkPolicy-per-ns.

Clone samples: “require run as non-root”, “disallow latest tag”.

```bash
kubectl get clusterpolicy
kubectl describe clusterpolicy NAME
```

## Gatekeeper

`ConstraintTemplate` (Rego) + Constraint (`K8sRequiredLabels` etc.).

```bash
kubectl get constrainttemplate,k8srequiredlabels
```

Use whichever CRDs exist: `kubectl get crd | grep -iE 'kyverno|gatekeeper|constraints'`.
