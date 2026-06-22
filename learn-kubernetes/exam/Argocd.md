Absolutely. Learning Argo CD through a mini-project is one of the best approaches because Argo CD is primarily an operational tool, not just a concept.

Since you've already been working with:

* Kubernetes (k3d)
* Namespaces
* Gateway API
* MetalLB
* Deployments and Services
* GitHub Actions

you can learn Argo CD in a way that feels practical rather than theoretical.

# Mini Project: GitOps Deployment with Argo CD

## Goal

Build a simple application and let Argo CD automatically deploy changes from Git into Kubernetes.

Architecture:

```text
Git Repository
      |
      v
   Argo CD
      |
      v
 Kubernetes
      |
      v
  Web Application
```

Instead of:

```bash
kubectl apply -f deployment.yaml
```

you will:

```bash
git push
```

and Argo CD will do the deployment.

---

# What you'll learn

By the end you'll understand:

✅ What GitOps is

✅ How Argo CD works

✅ Applications

✅ Syncing

✅ Self-healing

✅ Auto-sync

✅ Rollbacks

✅ Multi-environment deployments

✅ Helm integration

---

# Project Structure

Create a repository:

```text
argocd-demo/
│
├── app/
│   ├── deployment.yaml
│   ├── service.yaml
│
└── argocd/
    └── application.yaml
```

---

# Phase 1: Install Argo CD

Create namespace:

```bash
kubectl create namespace argocd
```

Install:

```bash
kubectl apply -n argocd \
-f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Check:

```bash
kubectl get pods -n argocd
```

Wait until all pods are Running.

---

# Phase 2: Access Argo CD UI

Port-forward:

```bash
kubectl port-forward svc/argocd-server \
-n argocd 8080:443
```

Open:

```text
https://localhost:8080
```

---

Get admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d
```

Login:

```text
username: admin
password: <output>
```

---

# Phase 3: Create Application

Create a simple nginx deployment.

`deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.27
        ports:
        - containerPort: 80
```

---

`service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-app
spec:
  selector:
    app: demo-app
  ports:
  - port: 80
    targetPort: 80
```

Push these files to GitHub.

---

# Phase 4: Connect Argo CD to Git

Create:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/YOUR_USERNAME/argocd-demo.git
    targetRevision: HEAD
    path: app

  destination:
    server: https://kubernetes.default.svc
    namespace: demo

  syncPolicy:
    automated:
      prune: true
      selfHeal: true

    syncOptions:
    - CreateNamespace=true
```

Apply:

```bash
kubectl apply -f application.yaml
```

---

# Phase 5: Watch GitOps in Action

Check:

```bash
kubectl get applications -n argocd
```

Argo CD should create:

```text
Namespace demo
Deployment demo-app
Service demo-app
```

without you running:

```bash
kubectl apply
```

against those manifests directly.

---

# Phase 6: Test Auto Sync

Change:

```yaml
image: nginx:1.27
```

to:

```yaml
image: nginx:alpine
```

Commit:

```bash
git add .
git commit -m "change image"
git push
```

Watch:

```bash
kubectl get pods -n demo -w
```

Argo CD detects the Git change and updates the Deployment automatically.

This is the "aha" moment of GitOps.

---

# Phase 7: Self Healing

Break the cluster manually:

```bash
kubectl scale deployment demo-app \
--replicas=5 \
-n demo
```

Check:

```bash
kubectl get deploy -n demo
```

You set 5 replicas.

Git says 1 replica.

Within a short time Argo CD will scale it back to 1.

Why?

Because Git is the source of truth.

This demonstrates **self-healing**.

---

# Phase 8: Rollback

Commit a bad change:

```yaml
image: nginx:does-not-exist
```

Pods fail.

Now revert:

```bash
git revert HEAD
git push
```

Argo CD restores the working version.

---

# Phase 9: Helm

Replace raw YAML with Helm:

```text
argocd-demo/
└── charts/
    └── webapp/
```

Then update Application:

```yaml
source:
  repoURL: ...
  path: charts/webapp
```

This is how many production teams use Argo CD.

---

# Phase 10: Production-Level Project

After finishing the above, build this:

```text
GitHub
│
├── frontend
├── backend
├── mysql
└── ingress/gateway

        ↓

Argo CD

        ↓

Kubernetes
```

Features:

* Multiple namespaces
* Helm charts
* Gateway API
* Secrets
* Auto-sync
* Self-healing

This will make you comfortable with the Argo CD concepts commonly used in DevOps and Platform Engineering roles.

### Suggested learning order

1. Install Argo CD
2. Create an Application
3. Sync from Git
4. Enable auto-sync
5. Test self-healing
6. Learn Projects
7. Learn Helm
8. Learn App of Apps pattern
9. Learn multi-environment deployments
10. Learn Argo Rollouts (advanced)

The first six steps can be completed in a single afternoon on your existing k3d cluster and will give you a solid understanding of GitOps and Argo CD.
---
