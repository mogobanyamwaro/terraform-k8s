# App Config (Deep Dive)

`app-config.yaml` is the control plane of the app. Later files override earlier.

## Load order (typical)

```text
app-config.yaml
app-config.production.yaml   # when NODE_ENV / APP_CONFIG includes it
app-config.local.yaml        # local only, gitignored
```

`${ENV}` substitution. Do not commit tokens.

## Keys that fail production if wrong

```yaml
app:
  title: Acme Portal
  baseUrl: https://backstage.example.com
backend:
  baseUrl: https://backstage.example.com
  listen: { port: 7007 }
  cors:
    origin: https://backstage.example.com
  database:
    client: pg
    connection:
      host: ${POSTGRES_HOST}
      user: ${POSTGRES_USER}
      password: ${POSTGRES_PASSWORD}
      database: backstage
auth:
  environment: production
  providers:
    github: { ... }
organization:
  name: Acme
integrations:
  github:
    - host: github.com
      token: ${GITHUB_TOKEN}
catalog:
  locations: [...]
  providers: { ... }
```

Same-host ingress often sets **both** `app.baseUrl` and `backend.baseUrl` to the public URL.

## Database

| Env | Client |
| --- | --- |
| Local | `better-sqlite3` |
| Prod | **`pg`** (PostgreSQL) |

SQLite in a Kubernetes pod = empty catalog after restart / no HA.

## Integrations

Needed for: private `type: url` locations, scaffolder publish, TechDocs from private repos, GitHub discovery.

GitHub **App** is the usual production pattern; PAT is simpler for labs.

## Auth

Guest = development. Production = GitHub/Google/OIDC + resolver to catalog User.

## Not config

- Entity YAML → `catalog-info.yaml` / locations, **not** app-config (except listing those locations)
- React routes → `App.tsx`
- Theme colours → `packages/app` theme
