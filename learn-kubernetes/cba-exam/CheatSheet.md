# Exam-Day Cheat Sheet

Last page before CBA. Closed book. **90 minutes, 60 questions, 75% (45/60).**

## Exam Facts

| | |
| --- | --- |
| Name | Certified Backstage Associate (CBA) |
| Format | Multiple choice, PSI |
| Docs | **None** |
| Focus | **Your create-app**: yarn, catalog YAML, plugins, React/MUI |

| Domain | Weight | ~Q |
| --- | ---: | ---: |
| **Customizing** | **32%** | ~19 |
| Development Workflow | 24% | ~14 |
| Infrastructure | 22% | ~13 |
| Catalog | 22% | ~13 |

## Commands

```text
npx @backstage/create-app@latest
yarn install && yarn start          # :3000 UI  :7007 API
yarn tsc
yarn workspace app add <fe-plugin>
yarn workspace backend add <be-plugin>
yarn build:backend && yarn build-image
```

## Split brain

| Symptom | Layer |
| --- | --- |
| Entity YAML / kinds / annotations / ingest | **Catalog** |
| yarn / tsc / Docker / workspaces | **Workflow** |
| baseUrl, Postgres, auth, FE vs BE process | **Infra** |
| App.tsx, EntityPage, sidebar, MUI, plugin install | **Customize** |
| Write plugin from zero | **Not CBA** |

## Catalog YAML

```yaml
apiVersion: backstage.io/v1alpha1
kind: Component          # API | Resource | System | Domain | Template | User | Group
metadata:
  name: demo
  annotations:
    backstage.io/techdocs-ref: dir:.
    github.com/project-slug: org/repo
    backstage.io/kubernetes-id: demo
spec:
  type: service
  lifecycle: production
  owner: group:default/team-a
```

Ref: `kind:namespace/name`. **Provider = ingest. Processor = transform.**

Locations: `catalog.locations` (`file`/`url`) or UI register. Private URL → `integrations` token.

## Prod vs lab

| | Lab | Prod |
| --- | --- | --- |
| DB | SQLite | **Postgres** |
| Auth | Guest | **IdP** |
| Run | `yarn start` | **Image / backend** |
| URLs | localhost | Real **baseUrl** + HTTPS |

## Plugin three steps

1. `yarn workspace … add`
2. Register FE (`App.tsx` / `EntityPage`) + BE (`backend.add`)
3. `app-config.yaml` + annotations

Empty tab → missing 2 or 3, or annotation.

## React surfaces

- `App.tsx` — routes, `createApp`
- `Root.tsx` — sidebar
- `EntityPage.tsx` — tabs/cards, `EntitySwitch`
- MUI `Grid` / `Button` + `InfoCard`
