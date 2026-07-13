# Architecture (Deep Dive)

Frontend SPA + backend Node. Official: [backstage.io/docs](https://backstage.io/docs/).

## Processes

```text
Browser  packages/app     :3000  (dev webpack/vite)
              |
         HTTPS / CORS
              |
Node     packages/backend :7007  catalog, scaffolder, techdocs, auth, plugins
              |
         PostgreSQL (prod)   SCM / k8s / CI APIs
```

Dev: `yarn start` runs both. Prod: one **backend** container serves the built frontend (or split UI+API behind ingress). Local ports **3000 / 7007** are the exam default.

## Packages in a create-app

| Path | Role |
| --- | --- |
| `packages/app` | React SPA, routes, EntityPage, theme, sidebar |
| `packages/backend` | Node, `backend.add(...)`, catalog DB, secrets |
| `app-config.yaml` | URLs, DB, auth, integrations, catalog.locations |
| `app-config.local.yaml` | Gitignored overrides |
| `app-config.production.yaml` | Prod overlay |

## Core plugins (framework)

Catalog, Scaffolder (templates), TechDocs, Search, Auth, App backend, Permission (optional). Everything is a plugin; create-app **composes** them.

## Request path

1. UI calls `/api/catalog/...`, `/api/techdocs/...`, `/api/scaffolder/...`
2. Backend plugin handles authz, tokens, DB
3. Browser never opens Postgres or GitHub with a PAT in the bundle

## TechDocs variants

- Generate in backend (`techdocs.builder: local`)
- Generate in CI (`techdocs-cli`) + publish to S3/GCS; backend **reads** storage

## Remember

- Secrets → backend
- Empty plugin UI → missing **backend** plugin, config, or **annotation**
- `baseUrl` mismatch → auth cookies / broken links
