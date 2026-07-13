# CBA Pitfalls

1. Treating CBA as **CNPA** — DORA/golden-path theory is not the syllabus; **Backstage product** is.
2. Treating CBA as **CKA** — closed-book MCQ, no cluster tasks.
3. **Writing a plugin from scratch** — out of scope; **installing/wiring** is in.
4. `create-app` vs developing the **Backstage monorepo** — exam is your standalone app.
5. **`yarn start` in production** — lab only; use a built backend/image.
6. **SQLite in Kubernetes** — lost catalog, no HA; use **Postgres**.
7. **Guest auth in production**.
8. Wrong **`app.baseUrl` / `backend.baseUrl`** — broken auth and links.
9. Putting GitHub tokens in **React** / `App.tsx`.
10. **`yarn workspace app add`** then wondering why nothing shows — not **registered**.
11. Frontend plugin without the **backend** package (empty k8s/CI tabs).
12. Confusing **`app-config.yaml`** with **`catalog-info.yaml`**.
13. Component `spec.type: service` as a **Kubernetes Service**.
14. **API** kind vs **Component** vs **Resource**.
15. Entity ref missing kind/namespace (`foo` vs `component:default/foo`).
16. **Labels** vs **annotations** (filter vs plugin hooks).
17. Missing **`backstage.io/techdocs-ref`** blamed on Yarn.
18. Missing **`github.com/project-slug`** blamed on MUI.
19. Debugging ingestion in **`packages/app`** — it is **backend** + YAML + tokens.
20. **403** on a Location as a YAML schema error — it is **integrations**.
21. **`type: file` locations in prod** pods without the files.
22. **Provider** vs **processor** swapped (crawl vs transform).
23. Expecting UI **Register** to edit `app-config.yaml` — it stores a Location in the **DB**.
24. Duplicate `kind`+`namespace`+`name` from two locations.
25. Stale entity = Git already updated — **refresh / wrong branch**.
26. Empty **dependsOn** graph — target **not ingested** or bad ref.
27. Patching **`node_modules`** to customize a plugin.
28. Sidebar change in **`EntityPage`** (chrome is **`Root.tsx`**).
29. Entity tabs in **`Root.tsx`** (they are **`EntityPage.tsx`**).
30. New page without a **`<Route>`** (only `yarn add`).
31. Mixing a second CSS framework instead of **MUI + core-components**.
32. **CORS** errors as catalog YAML errors.
33. TechDocs empty as a catalog **kind** error — annotation / builder / SCM.
34. Scaffolder cannot push — missing **`integrations.github`**.
35. Closed book: drill **which package** (`app` vs `backend`) and **which YAML** (app-config vs catalog-info).
