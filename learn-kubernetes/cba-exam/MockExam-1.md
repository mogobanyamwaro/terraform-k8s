# Mock Exam 1

Timer: **90 minutes**. 60 questions. Closed book. Passing simulation: **45/60**.

Mix ≈ exam: Customizing ~19, Workflow ~14, Infrastructure ~13, Catalog ~13.

Mark answers on paper. Key at the end.

---

**1.** Scaffold a new Backstage app with:  
A. `kubectl apply -f backstage.yaml` only  
B. `npx @backstage/create-app@latest`  
C. `npm init vite`  
D. Fork kubernetes/kubernetes  

**2.** `yarn start` in a created app typically starts:  
A. Only PostgreSQL  
B. Only TechDocs  
C. Frontend and backend together  
D. Only Docker  

**3.** Default local frontend port is:  
A. 3000  
B. 8080  
C. 9090  
D. 2746  

**4.** Default local backend port is:  
A. 2379  
B. 6443  
C. 16686  
D. 7007  

**5.** A created app is:  
A. A Helm chart only  
B. A standalone project that depends on Backstage packages  
C. A fork you must rebase forever  
D. A CRD only  

**6.** Gitignored local overrides belong in:  
A. `catalog-info.yaml`  
B. `Dockerfile`  
C. `app-config.local.yaml`  
D. `yarn.lock`  

**7.** Compile/typecheck the project with:  
A. `yarn tsc`  
B. `kubectl taint`  
C. `helm lint`  
D. `etcdctl`  

**8.** Add a frontend plugin dependency with:  
A. `kubectl apply`  
B. `yarn workspace app add <package>`  
C. `helm install` only  
D. Edit `catalog-info.yaml` only  

**9.** Add a backend plugin dependency with:  
A. `npx create-react-app`  
B. `docker commit`  
C. `yarn workspace app add` only  
D. `yarn workspace backend add <package>`  

**10.** `yarn start` in production is:  
A. Required for Postgres  
B. The only supported process  
C. A development workflow; use a built image/process  
D. Required by PSI  

**11.** create-app’s two main packages are:  
A. `packages/app` and `packages/backend`  
B. `cmd/kubelet` and `cmd/kube-apiserver`  
C. `charts/` and `crds/`  
D. `workflows/` and `sensors/`  

**12.** Backstage apps typically install JS deps with:  
A. Maven only  
B. apt-get only  
C. Yarn (workspaces)  
D. Go modules only  

**13.** Build a container image of the app with:  
A. `yarn tsc` only  
B. `npx create-app` again  
C. `yarn build:backend` / `yarn build-image` (or the repo Dockerfile)  
D. `kubectl run`  

**14.** `yarn tsc` failing means:  
A. Postgres is down  
B. TypeScript types/compile errors  
C. The catalog Location 404s  
D. CORS is misconfigured  

**15.** Backstage is primarily:  
A. A CNI  
B. A framework for internal developer portals  
C. A service mesh  
D. An etcd operator  

**16.** The primary runtime config file is:  
A. `app-config.yaml`  
B. `catalog-info.yaml`  
C. `kyverno.yaml`  
D. `Chart.yaml` only  

**17.** `app.baseUrl` should be:  
A. The Postgres URL  
B. The Yarn cache  
C. The public URL users open for the UI  
D. Port 2379  

**18.** `backend.baseUrl` should be:  
A. Always port 3000  
B. The public URL of the backend API  
C. etcd  
D. The MUI theme  

**19.** Production database should be:  
A. SQLite in the container  
B. etcd as the catalog  
C. Redis only always  
D. PostgreSQL  

**20.** Guest auth in production is:  
A. Insufficient; use a real identity provider  
B. Ideal  
C. Required by CBA  
D. A replacement for HTTPS  

**21.** The UI is:  
A. PostgreSQL  
B. etcd  
C. A React SPA that calls the backend  
D. kube-proxy  

**22.** A GitHub PAT for plugins belongs:  
A. In `App.tsx`  
B. On the backend (env / integrations)  
C. In `metadata.tags`  
D. In MUI `makeStyles`  

**23.** Browser blocks frontend→backend calls when:  
A. `yarn.lock` is wrong  
B. Docker layers are wrong  
C. Catalog YAML indent is wrong  
D. CORS / origin does not allow the UI  

**24.** Private GitHub catalog URLs need:  
A. `integrations` credentials  
B. Only MUI  
C. Only `yarn tsc`  
D. kind: Template  

**25.** Multiple backend replicas need:  
A. Nested SSH  
B. Flux only  
C. Shared PostgreSQL (and aligned config)  
D. Each their own SQLite file  

**26.** Software Templates (Scaffolder) provide:  
A. NetworkPolicy  
B. HPA  
C. Ticket ops only  
D. Golden-path project creation from a Template entity  

**27.** TechDocs:  
A. Replaces Git  
B. A CRD  
C. Renders docs-like-code inside the portal  
D. Prometheus  

**28.** The Software Catalog’s job is:  
A. Compile TypeScript  
B. Inventory software/APIs/resources with owners  
C. Schedule pods  
D. Sign images  

**29.** A Component typically represents:  
A. A Postgres replica only  
B. An Ingress class  
C. A piece of software (service, website, library)  
D. A Yarn workspace always  

**30.** `kind: API` is for:  
A. An interface a Component provides (OpenAPI, gRPC, …)  
B. A Kubernetes Service  
C. A Yarn package  
D. A Docker image  

**31.** `kind: Resource` is for:  
A. React routes  
B. MUI buttons  
C. TypeScript enums  
D. Infrastructure a Component uses (database, bucket, …)  

**32.** Catalog YAML `apiVersion` is typically:  
A. `apps/v1`  
B. `backstage.io/v1alpha1`  
C. `v1`  
D. `argoproj.io/v1alpha1`  

**33.** Entity reference format is:  
A. `host:port`  
B. `sha256:...`  
C. `kind:namespace/name`  
D. `arn:aws:...` only  

**34.** `backstage.io/techdocs-ref: dir:.` means:  
A. TechDocs sources in this repo (MkDocs at `.`)  
B. Delete the repo  
C. A Kubernetes volume  
D. Postgres schema  

**35.** `github.com/project-slug: org/repo` :  
A. Compiles TypeScript  
B. Tells GitHub-aware plugins which repository  
C. Sets `baseUrl`  
D. A Location type  

**36.** Kubernetes plugin binding often uses:  
A. Only MUI  
B. Only `yarn start`  
C. A Template kind  
D. `backstage.io/kubernetes-id` (or a label selector)  

**37.** `catalog.locations` in app-config:  
A. Docker build args  
B. Frontend routes  
C. Locations loaded on backend start  
D. MUI themes  

**38.** Register existing component in the UI:  
A. Adds a Location (URL) into the catalog database  
B. Writes a Dockerfile  
C. Runs `yarn tsc`  
D. Creates a Kubernetes Namespace  

**39.** Entity **providers**:  
A. Only style the sidebar  
B. Ingest/emit entities from an external system  
C. Are React hooks only  
D. Are `catalog-info.yaml` kinds  

**40.** Catalog **processors**:  
A. Crawl GitHub orgs by default  
B. Are Ingress controllers  
C. Are Yarn scripts  
D. Validate/mutate entities already in the pipeline  

**41.** Frontend plugins run:  
A. In PostgreSQL  
B. In the browser as React  
C. Only in Docker build  
D. In kube-proxy  

**42.** Backend plugins run:  
A. In the Node Backstage backend process  
B. Only in webpack  
C. Only on the GPU  
D. In etcd  

**43.** After `yarn add`, the plugin appears in the sidebar:  
A. Always  
B. Yes if the name contains `plugin`  
C. Not until you register routes/sidebar/entity cards  
D. Yes after `yarn tsc` only  

**44.** Adding a CI tab on a service is usually:  
A. Forking plugin Git  
B. Editing Postgres  
C. Editing `kind: Location`  
D. Mounting plugin content in `EntityPage.tsx`  

**45.** Sidebar items are declared in:  
A. `catalog-info.yaml`  
B. `Root.tsx`  
C. `packages/backend/Dockerfile`  
D. PSI policy  

**46.** A new top-level page is added in:  
A. `App.tsx` routes (and usually a sidebar item)  
B. `catalog-info.yaml`  
C. `yarn.lock` only  
D. `Dockerfile` only  

**47.** `EntitySwitch` is used to:  
A. Switch Yarn versions  
B. Switch `baseUrl`  
C. Render different cards/tabs per kind or annotation  
D. Switch SQLite to Redis  

**48.** Backstage frontend styling is primarily:  
A. Bootstrap 2 only  
B. Material UI (+ core-components)  
C. ncurses  
D. GTK  

**49.** `InfoCard` is:  
A. A catalog kind  
B. A backend plugin  
C. A Location type  
D. A Backstage core component for card layout  

**50.** `backend.add(import('…-backend'))` is:  
A. New-backend-system plugin registration  
B. A catalog Location  
C. A MUI theme  
D. A Docker HEALTHCHECK  

**51.** Writing a custom plugin from scratch is:  
A. The entire CBA syllabus  
B. Required for every new sidebar link  
C. Out of CBA scope; installing/wiring is in scope  
D. How Locations work  

**52.** Kubernetes tab empty with the FE plugin installed:  
A. Always a `yarn.lock` bug  
B. Often missing backend plugin, cluster config, or annotation  
C. Always a wrong `spec.lifecycle`  
D. Always port 3000 closed  

**53.** Changing portal colours is typically:  
A. A catalog processor  
B. `kind: System`  
C. Postgres `ALTER ROLE`  
D. A Backstage/MUI theme in `packages/app`  

**54.** Laying out entity Overview cards uses:  
A. MUI `Grid` (or equivalent) in `EntityPage.tsx`  
B. `iptables`  
C. `catalog.locations`  
D. `yarn tsc` flags  

**55.** Embedding a GitHub token in the React bundle is:  
A. Recommended  
B. Required for TechDocs  
C. Wrong architecture (secret leak)  
D. How Locations work  

**56.** Live Kubernetes data in Backstage needs:  
A. Only a frontend package  
B. Frontend + backend plugin + cluster config + entity annotation  
C. Only `app.title`  
D. Only `yarn tsc`  

**57.** Editing `node_modules/@backstage/...` to customize:  
A. The supported path  
B. Required for MUI  
C. How Locations work  
D. Fragile and not exam practice  

**58.** `createApp` from app-defaults:  
A. Builds the app object (plugins, APIs, sign-in)  
B. Scaffolds a GitHub org  
C. Runs `yarn tsc`  
D. Creates a Location  

**59.** Largest CBA domain is:  
A. Only Docker  
B. Only DORA  
C. Customizing Backstage (~32%)  
D. Only GitOps theory  

**60.** CBA exam format:  
A. 2h live cluster  
B. 60 MCQ, 90 min, 75%, closed book  
C. Oral  
D. Open book backstage.io  

---

## Answer key

1B 2C 3A 4D 5B 6C 7A 8B 9D 10C  
11A 12C 13C 14B 15B 16A 17C 18B 19D 20A  
21C 22B 23D 24A 25C 26D 27C 28B 29C 30A  
31D 32B 33C 34A 35B 36D 37C 38A 39B 40D  
41B 42A 43C 44D 45B 46A 47C 48B 49D 50A  
51C 52B 53D 54A 55C 56B 57D 58A 59C 60B  

Missed 1–14 → `01.md`–`05.md`, `Lab-Setup.md`.  
Missed 15–27 → `06.md`–`10.md`, `Architecture.md`, `AppConfig.md`.  
Missed 28–40 → `11.md`–`16.md`, `Catalog.md`, `Annotations.md`.  
Missed 41–59 → `17.md`–`22.md`, `Plugins.md`.  
Format → `00.md`.
