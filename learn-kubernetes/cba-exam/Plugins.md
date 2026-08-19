# Plugins (Deep Dive)

Install and compose. **Do not write a plugin from scratch** (CBA out of scope).

## Two packages

```bash
yarn workspace app add @backstage/plugin-kubernetes
yarn workspace backend add @backstage/plugin-kubernetes-backend
```

| Step | Where |
| --- | --- |
| Dependency | `package.json` via yarn workspace |
| FE register | `App.tsx` routes and/or `EntityPage.tsx` cards/tabs |
| BE register | `packages/backend` `backend.add(import('…-backend'))` |
| Configure | `app-config.yaml` |
| Bind to entity | **annotations** (often) |

`yarn add` without register = nothing in the UI.

## Frontend vs backend

| Need | Side |
| --- | --- |
| New page, tab, card, sidebar | `packages/app` |
| Tokens, GitHub, k8s API, providers, processors | `packages/backend` |
| Both for “live data” plugins | Pair of packages |

## Customizing without a new plugin

- `EntityPage.tsx` — `EntityLayout.Route`, `EntitySwitch`, `isKind`
- `Root.tsx` — `SidebarItem`
- `App.tsx` — `<Route>`
- Theme — `@backstage/theme` / MUI
- Tiny React pages in `packages/app/src`

Do not patch `node_modules`.

## New backend system (create-app today)

```ts
const backend = createBackend();
backend.add(import('@backstage/plugin-catalog-backend'));
backend.add(import('@backstage/plugin-kubernetes-backend'));
backend.start();
```

Older apps used `createRouter` + `useHotMemoize`. Exam cares **that** you register, not every API name.

## Core vs extra

create-app already wires catalog, scaffolder, techdocs, search, auth. Extra plugins (k8s, GitHub Actions, scorecards) follow the README **five steps**: FE dep, BE dep, FE mount, BE add, config.
