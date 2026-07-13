# Flashcards

Cover the right column. Night before and morning of.

## Meta

| Prompt | Answer |
| --- | --- |
| Format | Closed-book **MCQ**, 60 / 90 min / **75%** |
| Largest domain | **Customizing 32%** |
| Workflow / Infra / Catalog | **24% / 22% / 22%** |
| Write a plugin from scratch? | **Out of scope** |
| Install a plugin? | **In scope** |

## Workflow

| Prompt | Answer |
| --- | --- |
| Scaffold | **`npx @backstage/create-app@latest`** |
| Local run | **`yarn start`** |
| UI port | **3000** |
| Backend port | **7007** |
| Typecheck | **`yarn tsc`** |
| Add FE dep | **`yarn workspace app add`** |
| Add BE dep | **`yarn workspace backend add`** |
| Prod image | **`yarn build:backend` / `yarn build-image`** |
| Local config overlay | **`app-config.local.yaml`** |

## Infrastructure

| Prompt | Answer |
| --- | --- |
| Main config | **`app-config.yaml`** |
| Public UI URL | **`app.baseUrl`** |
| Public API URL | **`backend.baseUrl`** |
| Local DB | **SQLite** |
| Prod DB | **PostgreSQL** |
| Prod auth | **IdP, not guest** |
| Prod process | **Built backend**, not `yarn start` |
| Secrets in React? | **No** |
| SPA talks to | **Backend HTTP APIs** |

## Catalog

| Prompt | Answer |
| --- | --- |
| apiVersion | **`backstage.io/v1alpha1`** |
| Entity ref | **`kind:namespace/name`** |
| Default ns | **`default`** |
| Software | **Component** |
| Interface | **API** |
| Infra | **Resource** |
| Scaffolder YAML | **Template** |
| Docs annotation | **`backstage.io/techdocs-ref`** |
| GitHub repo | **`github.com/project-slug`** |
| K8s bind | **`backstage.io/kubernetes-id`** |
| Static ingest | **`catalog.locations`** |
| UI ingest | **Register existing** |
| Discover orgs | **Entity provider** |
| Validate/mutate | **Processor** |
| Private URL 403 | **Missing integration token** |

## Customize

| Prompt | Answer |
| --- | --- |
| React app | **`packages/app`** |
| Node API | **`packages/backend`** |
| Routes | **`App.tsx`** |
| Sidebar | **`Root.tsx`** |
| Entity tabs | **`EntityPage.tsx`** |
| Per-kind tabs | **`EntitySwitch` / `isKind`** |
| UI library | **Material UI** |
| Consistent cards | **`@backstage/core-components`** |
| `yarn add` alone | **Not visible until registered** |
| Theme | **`packages/app` + `@backstage/theme`** |
