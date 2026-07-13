# Exam-Day Cheat Sheet

Last page before KCA. Closed book. **90 minutes, 60 questions, 75% (45/60).**

## Exam Facts

| | |
| --- | --- |
| Name | Kyverno Certified Associate (KCA) |
| Format | Multiple choice, PSI |
| Docs | **None** |
| Focus | **YAML policies**, CLI, Helm, reports |

| Domain | Weight | ~Q |
| --- | ---: | ---: |
| **Writing Policies** | **32%** | ~19 |
| Fundamentals | 18% | ~11 |
| Install / upgrade | 18% | ~11 |
| CLI | 12% | ~7 |
| Applying | 10% | ~6 |
| Management | 10% | ~6 |

## Split brain

```text
Which rule?     validate | mutate | generate | verifyImages | cleanup CR
When?           admission vs background vs cron
Fail closed?    Enforce vs Audit vs webhook failurePolicy
Laptop?         kyverno apply/test   Cluster? kubectl apply CR
```

## Envelope

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
spec:
  validationFailureAction: Enforce   # or Audit
  background: true
  rules:
    - name: r
      match:
        any: [{ resources: { kinds: [Pod] } }]
      validate:
        message: "..."
        pattern: { metadata: { labels: { team: "?*" } } }
```

## Helm

```text
helm repo add kyverno https://kyverno.github.io/kyverno/
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
```

## CLI

```text
kyverno apply p.yaml --resource r.yaml
kyverno test .
kyverno jp query -i r.yaml 'spec.containers[].image'
```

## Don’t confuse

| A | B |
| --- | --- |
| Policy | ClusterPolicy |
| Audit | webhook `failurePolicy` |
| generate | mutate |
| clone | data |
| Exception | Audit |
| Java/OTel agent | Kyverno admission |
| Rego | Kyverno YAML |
| Background fail | Pod eviction |
