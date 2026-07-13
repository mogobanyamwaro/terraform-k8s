# Validate (Deep Dive)

```yaml
validate:
  message: "..."
  pattern:
    spec:
      containers:
        - name: "*"
          image: "!*:latest"
  # or
  deny:
    conditions:
      any:
        - key: "{{ request.object.metadata.labels.team || '' }}"
          operator: Equals
          value: ""
  # or
  cel:
    expressions:
      - expression: "object.spec.containers.all(c, has(c.resources.limits))"
```

| Tool | Role |
| --- | --- |
| pattern | Overlay + anchors `?*` `(field)` `X()` `!` |
| deny | JMESPath conditions |
| foreach | Lists |
| cel | Kubernetes CEL |
| preconditions | Skip rule |

`validationFailureAction: Audit|Enforce`

Background: reports, not eviction.
