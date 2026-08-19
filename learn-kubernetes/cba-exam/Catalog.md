# Catalog (Deep Dive)

Software Catalog model. Docs: [backstage.io/docs/features/software-catalog](https://backstage.io/docs/features/software-catalog/).

## Envelope

```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: artist-web
  namespace: default          # optional; default is default
  description: ...
  labels: { ... }             # filter
  annotations: { ... }        # plugin hooks
  tags: [java]
  links: [{ url, title }]
spec:
  type: website               # service | website | library | ...
  lifecycle: production
  owner: group:default/team-a
  system: artist-engagement
  dependsOn: [resource:default/artists-db]
  providesApis: [artist-api]
```

**Ref:** `kind:namespace/name` → `component:default/artist-web`

## Kinds

| Kind | One line |
| --- | --- |
| Domain | Business area |
| System | Product / collection |
| Component | Software |
| API | Interface (openapi, grpc, …) |
| Resource | Infra (db, bucket, queue) |
| User / Group | Org |
| Template | Scaffolder |
| Location | Ingestion pointer |

## How entities enter

| Method | Mechanism |
| --- | --- |
| Static | `catalog.locations` in app-config (`file` / `url`) |
| UI | Register existing component → Location in DB |
| Automated | **Entity providers** (GitHub org, LDAP, …) |

**Processors** validate, mutate, stitch relations. They do **not** crawl GitHub orgs.

```text
Location/Provider → fetch/parse → processors → catalog DB → API → UI
```

## Location YAML

```yaml
catalog:
  locations:
    - type: url
      target: https://github.com/org/repo/blob/main/catalog-info.yaml
      rules:
        - allow: [Component, API, Resource, System, Template]
```

Private URL needs `integrations`. `type: file` is local/dev.

## Ingestion errors

| Failure | Layer |
| --- | --- |
| 404 / 403 | Fetch (URL, token) |
| YAML parse | Syntax |
| Missing `spec.type`/`owner`/`lifecycle` | Processor validation |
| Duplicate name | Conflict |
| Stale | Refresh / wrong branch |
| Empty relations | Target missing or bad ref |

Debug **Location status + backend logs**, not `App.tsx`.

## Orphans

Source Location gone → entity may remain until orphan policy/deletion.
