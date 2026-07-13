# Mock Exam 2

Timer: **90 minutes**. 60 questions. Closed book. Passing simulation: **45/60**. Harder distractors than Mock 1.

Same mix: Customizing ~19, Workflow ~14, Infrastructure ~13, Catalog ~13.

Mark answers on paper. Key at the end.

---

**1.** `npx @backstage/create-app@latest` produces:  
A. A Kubernetes operator you apply to every cluster  
B. A standalone app repo (`packages/app`, `packages/backend`, app-config)  
C. A fork of `backstage/backstage` you must rebase weekly  
D. Only a `catalog-info.yaml`  

**2.** In local dev, port 7007 is:  
A. The webpack UI  
B. PostgreSQL  
C. The Backstage backend API  
D. Yarn’s cache HTTP server  

**3.** `app-config.local.yaml` is for:  
A. Entities that must be committed to Git  
B. Machine-specific overrides that should not be committed  
C. Replacing `packages/backend`  
D. The PSI exam policy  

**4.** `yarn workspace app add` vs `yarn add` at an arbitrary nested folder:  
A. Identical always  
B. Workspace command targets the `app` package and the lockfile correctly  
C. Nested `yarn add` is required by Backstage  
D. Neither updates `package.json`  

**5.** `yarn tsc` does **not**:  
A. Typecheck TypeScript  
B. Start the portal UI on :3000  
C. Catch many plugin wiring type errors  
D. Run from the app root in a typical create-app  

**6.** Production images should run:  
A. `yarn start` with webpack  
B. The **built** backend (frontend assets served by backend or CDN)  
C. `npx create-app` on every pod start  
D. SQLite plus guest auth by policy  

**7.** `packages/app` vs `packages/backend` — installing `@backstage/plugin-search`:  
A. Always only backend  
B. Search UI is frontend; indexing/collators need backend  
C. Always only a catalog Location  
D. Always only MUI  

**8.** Hot reload while customizing `EntityPage.tsx`:  
A. Requires `yarn build-image` each save  
B. Works with `yarn start` frontend rebuild/reload  
C. Requires restarting Postgres  
D. Requires a new `kind:`  

**9.** `yarn install` after cloning a create-app:  
A. Optional if Docker is installed  
B. Required to fetch workspace dependencies  
C. Replaces `app-config.yaml`  
D. Registers catalog Locations  

**10.** Dockerfile for Backstage typically builds:  
A. Only the React Storybook  
B. The backend image that includes the app  
C. An etcd snapshot  
D. A Cilium agent  

**11.** Switching a dependency from app to backend by editing the wrong `package.json`:  
A. Has no effect  
B. The plugin may compile in the UI but `/api/...` 404s (or the reverse)  
C. Automatically moves Yarn workspaces  
D. Converts SQLite to Postgres  

**12.** `create-app` is **not**:  
A. The supported way to start a portal  
B. `kubectl create namespace backstage`  
C. Using Yarn workspaces  
D. Generating `app-config.yaml`  

**13.** TypeScript errors in `packages/backend` after adding a plugin:  
A. Are always CORS  
B. Often a missing `backend.add` import or wrong package  
C. Mean the catalog YAML indent is wrong  
D. Mean MUI Grid `md` is wrong  

**14.** `app-config.production.yaml` exists to:  
A. Store Component entities  
B. Overlay prod URLs, Postgres, real auth  
C. Replace `yarn.lock`  
D. Theme the sidebar  

**15.** `app.baseUrl` and `backend.baseUrl` behind one Ingress host should:  
A. Stay `http://localhost:3000` and `:7007`  
B. Be the **public** URLs users and the API actually use  
C. Be the Postgres connection string  
D. Be omitted in production  

**16.** SQLite `better-sqlite3` on three replicas:  
A. Correct HA  
B. Split-brain / empty/inconsistent catalog; use Postgres  
C. Required by Scaffolder  
D. Required by MUI  

**17.** Sign-in resolver maps:  
A. Docker tags to Helm  
B. IdP identity → catalog User (or a chosen identity strategy)  
C. Locations to Ingress  
D. Grid columns to annotations  

**18.** Scaffolder cannot push to GitHub. First check:  
A. `EntityPage` Grid spacing  
B. `integrations.github` credentials and backend registration  
C. `yarn tsc` only  
D. `kind: Domain`  

**19.** Direct browser → Postgres is:  
A. The Backstage design  
B. Not the architecture; the backend owns the database  
C. Faster than `/api/catalog`  
D. How annotations work  

**20.** TechDocs generated in CI + object storage:  
A. Illegal  
B. Valid; backend still authenticates/serves docs  
C. Removes the need for a catalog  
D. Removes `packages/backend`  

**21.** `backend.cors.origin` must include:  
A. The Postgres host  
B. The frontend origin  
C. etcd  
D. Yarn’s registry  

**22.** Permission framework:  
A. Replaces TLS  
B. Optional authorization on catalog/scaffolder-style actions  
C. A required Component `spec.type`  
D. Docker HEALTHCHECK  

**23.** Framework building blocks do **not** include:  
A. Software Catalog  
B. Software Templates  
C. kube-scheduler  
D. TechDocs  

**24.** Config `${GITHUB_TOKEN}` is:  
A. Invalid YAML  
B. Environment substitution  
C. A catalog kind  
D. A Location `type:`  

**25.** Guest auth is appropriate for:  
A. Production SSO  
B. Local/demo only  
C. Replacing Postgres  
D. Replacing integrations  

**26.** A frontend-only install of a data plugin typically fails at:  
A. `yarn tsc` always  
B. Runtime `/api/<plugin>` (backend missing)  
C. `metadata.name` uniqueness  
D. MUI `Typography`  

**27.** `organization.name` in app-config:  
A. A CRD  
B. Display/org branding  
C. A Processor  
D. A Location type  

**28.** `spec.type: service` on a Component means:  
A. A Kubernetes Service object must exist  
B. Conventional software type in the catalog model  
C. An auth provider  
D. A Location type  

**29.** `providesApis: [artist-api]` links:  
A. Docker CMD  
B. The Component to API entities  
C. Port 7007  
D. `yarn tsc`  

**30.** Default catalog namespace if omitted:  
A. `kube-system`  
B. `default`  
C. `backstage-system`  
D. `production`  

**31.** Labels vs annotations:  
A. Identical  
B. Labels for filtering; annotations for plugin/system string metadata  
C. Labels replace `spec.owner`  
D. Annotations are only Kubernetes  

**32.** `backstage.io/managed-by-location` is usually:  
A. Required in every hand-written YAML  
B. Stamped by ingestion  
C. The MUI palette  
D. The Docker tag  

**33.** `rules.allow: [Template]` on a location:  
A. Allows every kind  
B. Restricts that location to Template entities  
C. Disables the catalog  
D. Sets `spec.owner`  

**34.** UI “Register existing” vs `catalog.locations`:  
A. Identical storage always  
B. UI persists a Location in the **database**; config lists static locations  
C. UI edits `Dockerfile`  
D. Config cannot use `type: url`  

**35.** Fetch 403 on a GitHub Location:  
A. Wrong `kind:`  
B. Missing/invalid SCM integration token or permissions  
C. Missing `spec.lifecycle` only  
D. Port 3000 closed  

**36.** Duplicate `kind` + namespace + `metadata.name`:  
A. Always kept as two independent entities with no conflict  
B. Catalog conflict / overwrite / error  
C. Changes `app.baseUrl`  
D. Fixes auth  

**37.** Entity graph empty despite `dependsOn`:  
A. Need `yarn tsc`  
B. Target not ingested or entity ref misspelled  
C. Need guest auth  
D. Need port 80  

**38.** GitHub org discovery is:  
A. A frontend-only plugin  
B. A backend **entity provider** plus GitHub integration  
C. `app.baseUrl`  
D. A Template `step`  

**39.** Providers vs processors — correct pair:  
A. Same API  
B. Providers ingest; processors transform/validate  
C. Processors replace Postgres  
D. Providers compile TypeScript  

**40.** Debugging a YAML parse error in `Root.tsx`:  
A. Correct first step  
B. Wrong layer; ingestion is backend + YAML  
C. Required by CBA  
D. Replaces Location status  

**41.** A catalog entity provider belongs in:  
A. `packages/app` only  
B. Backend registration + `catalog.providers` (or plugin config)  
C. MUI `Grid`  
D. `SidebarItem` only  

**42.** Orphan entity:  
A. A User without email  
B. Catalog item whose Location/source disappeared  
C. A dangling Docker image only  
D. A failed `yarn install`  

**43.** Frontend plugin + backend plugin + config, still empty entity tab:  
A. Always Postgres vacuum  
B. Often a missing **annotation** (or `EntityPage` not mounting the tab)  
C. Always `yarn.lock`  
D. Always wrong `app.title`  

**44.** `EntityLayout.Route` lives in:  
A. `packages/backend/src/index.ts`  
B. `EntityPage.tsx`  
C. `catalog-info.yaml`  
D. `app-config.yaml` `catalog.locations`  

**45.** Hide Scaffolder from users without uninstalling Node:  
A. Delete Postgres  
B. Remove sidebar item / route (and optionally disable plugin)  
C. Delete `kind: Template` from the universe  
D. Set `app.baseUrl` to empty  

**46.** Custom React page `/ops` without a new plugin package:  
A. Out of CBA  
B. Valid: `<Route>` in `App.tsx` + sidebar in `Root.tsx`  
C. Must be a backend plugin  
D. Must be a catalog kind  

**47.** `useEntity()` is valid:  
A. In Dockerfiles  
B. On catalog entity pages to read the current entity  
C. To start Yarn  
D. To set `backend.listen`  

**48.** Prefer `@backstage/core-components` because:  
A. It avoids Postgres  
B. Progress/EmptyState/InfoCard match the portal  
C. It skips `yarn add`  
D. It skips auth  

**49.** `Grid item md={6}` on an entity page:  
A. Kubernetes millicores  
B. Half-width column on medium+ breakpoints  
C. Backend port 6  
D. Yarn timeout 6s  

**50.** `createUnifiedTheme` / Backstage theme helpers:  
A. Ingest GitHub orgs  
B. Build a MUI-compatible theme  
C. Compile the backend image  
D. Create Users  

**51.** Logo replacement is:  
A. `backstage.io/logo` annotation only  
B. App theme / Root logo / static assets in `packages/app`  
C. A Location URL  
D. A Processor  

**52.** `yarn workspace app add` without `EntityPage` change for an entity card plugin:  
A. The card always appears on Overview  
B. The card will not show until you mount it  
C. Backend `add()` is enough  
D. Annotations alone mount React  

**53.** Putting cluster kubeconfig in a frontend plugin:  
A. Recommended  
B. Wrong; cluster credentials stay on the backend  
C. How `kubernetes-id` works  
D. Required for MUI  

**54.** `SignInPage` customization is:  
A. A Location  
B. React / `createApp` components  
C. `kind: User` YAML only  
D. TechDocs MkDocs  

**55.** Mixing Bootstrap globally with Backstage MUI:  
A. Required  
B. Fights the theme; avoid  
C. How Locations work  
D. How providers work  

**56.** New backend system registration is closest to:  
A. `kubectl apply`  
B. `backend.add(import('…'))`  
C. `metadata.annotations`  
D. `SidebarDivider`  

**57.** Entity tab only for APIs:  
A. Impossible  
B. `EntitySwitch` / `isKind('api')`  
C. A Location `rules.allow` on the UI  
D. `yarn tsc --force`  

**58.** Customizing a plugin the CBA way is:  
A. Fork and rewrite the plugin package  
B. Compose routes/cards/config in **your** app  
C. Patch `node_modules`  
D. Write a CNI  

**59.** Empty TechDocs with a valid Component:  
A. Always a wrong `apiVersion`  
B. Missing/wrong `backstage.io/techdocs-ref`, builder, or SCM fetch  
C. Always guest auth  
D. Always port 3000  

**60.** Closed-book CBA passing score:  
A. 64%  
B. 75% (45/60)  
C. 90%  
D. No score; lab only  

---

## Answer key

1B 2C 3B 4B 5B 6B 7B 8B 9B 10B  
11B 12B 13B 14B 15B 16B 17B 18B 19B 20B  
21B 22B 23C 24B 25B 26B 27B 28B 29B 30B  
31B 32B 33B 34B 35B 36B 37B 38B 39B 40B  
41B 42B 43B 44B 45B 46B 47B 48B 49B 50B  
51B 52B 53B 54B 55B 56B 57B 58B 59B 60B  

Missed 1–14 → `01.md`–`05.md`.  
Missed 15–27 → `06.md`–`10.md`, `Architecture.md`, `AppConfig.md`.  
Missed 28–42 → `11.md`–`16.md`, `Catalog.md`, `Annotations.md`.  
Missed 43–59 → `17.md`–`22.md`, `Plugins.md`.  
Score/format → `00.md`, `CheatSheet.md`.
