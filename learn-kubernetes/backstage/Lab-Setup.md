# CBA Lab Setup

The exam is closed-book. One local Backstage app makes catalog YAML and plugins obvious.

Needs: Node.js (LTS), Yarn **4** (Backstage default), Docker optional, Git.

```bash
npx @backstage/create-app@latest
# follow prompts; Yarn is used inside the generated repo
cd <app-name>
yarn install
yarn start
```

- Frontend: [http://localhost:3000](http://localhost:3000)
- Backend: [http://localhost:7007](http://localhost:7007)

`yarn start` runs both. Config: `app-config.yaml` plus `app-config.local.yaml` (gitignored overrides).

**First catalog entity** — `examples/entities.yaml` or a `catalog-info.yaml` in a demo repo. Register via Catalog → Create → Register existing, or `catalog.locations` in config.

```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: demo-service
  annotations:
    backstage.io/techdocs-ref: dir:.
spec:
  type: service
  lifecycle: experimental
  owner: user:guest
```

**Typecheck / image**

```bash
yarn tsc
yarn build:backend
# Docker (from repo root, see packages/backend/Dockerfile)
yarn build-image
# or: docker build -f packages/backend/Dockerfile .
```

Do not spend CBA prep writing a plugin from scratch. **Install** one (e.g. kubernetes, github) and register it in `packages/app` / `packages/backend`.
