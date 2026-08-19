# Annotations (Deep Dive)

`metadata.annotations` — string map. Plugins and the catalog **read** them. Labels are for **filtering**.

## Well-known keys

| Key | Purpose |
| --- | --- |
| `backstage.io/techdocs-ref` | Docs source (`dir:.` or URL) |
| `backstage.io/source-location` | SCM directory for the entity |
| `backstage.io/view-url` | Browse in SCM |
| `backstage.io/edit-url` | Edit in SCM |
| `backstage.io/managed-by-location` | Ingestion source (usually **system-set**) |
| `backstage.io/managed-by-origin-location` | Origin Location |
| `github.com/project-slug` | `org/repo` for GitHub plugins |
| `backstage.io/kubernetes-id` | K8s plugin: label `backstage.io/kubernetes-id=<id>` on workloads |
| `backstage.io/kubernetes-label-selector` | Alternate k8s binding |
| `sonarqube.org/project-key` | Sonar |
| `backstage.io/code-coverage` | Coverage plugin |

```yaml
metadata:
  name: demo
  annotations:
    backstage.io/techdocs-ref: dir:.
    github.com/project-slug: acme/demo
    backstage.io/kubernetes-id: demo
```

## Behaviour

- Missing TechDocs annotation → no/empty docs, entity still **valid**
- Missing k8s annotation → empty Kubernetes tab even if the plugin is installed
- Custom keys (`example.com/foo`) are allowed for **your** plugin
- Values are **strings**, not nested objects

## Not annotations

- `spec.owner` / `spec.system` — relations, not plugin URLs
- `app-config.yaml` — runtime of the portal
- MUI theme — `packages/app`

## Exam default

Empty plugin tab → **annotation + backend integration + FE mount**, in that order of suspicion.
