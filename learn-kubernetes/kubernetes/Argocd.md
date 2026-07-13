Absolutely. Learning Argo CD through a mini-project is one of the best approaches because Argo CD is primarily an operational tool, not just a concept.

Since you've already been working with:

- Kubernetes (k3d)
- Namespaces
- Gateway API
- MetalLB
- Deployments and Services
- GitHub Actions

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

# if got an error
# Delete the problematic CRD
kubectl delete crd applicationsets.argoproj.io

# Reapply with server-side apply
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml \
--server-side --force-conflicts
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
    repoURL: git@github.com:mogobanyamwaro/argocd-for-learning.git # SSH URL
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

Yep. Full minimal-overhead process for a **private GitHub repo + Argo CD + SSH deploy key**.

**1. Generate A Key**
Run this on your machine:

```bash
ssh-keygen -t ed25519 -C "argocd-demo-app" -f ~/.ssh/argocd_demo_app
```

When it asks for a passphrase, press Enter for no passphrase. Argo CD needs to use the key non-interactively.

This creates:

```text
~/.ssh/argocd_demo_app      # private key, give this to Argo CD
~/.ssh/argocd_demo_app.pub  # public key, give this to GitHub
```

**2. Add Public Key To GitHub**
Print the public key:

```bash
cat ~/.ssh/argocd_demo_app.pub
```

Copy the output.

In GitHub:

```text
Repo -> Settings -> Deploy keys -> Add deploy key
```

Use something like:

```text
Title: argocd-demo-app
Key: paste the .pub key
Allow write access: unchecked
```

Leave write access off unless Argo CD or another tool needs to push back to the repo.

**3. Set The App Back To SSH**
Your [application.yaml](/Users/douglas/Documents/k8s/argocd/application.yaml:10) should use the SSH repo URL:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app
  namespace: argocd
spec:
  project: default

  source:
    repoURL: git@github.com:mogobanyamwaro/argocd.git
    targetRevision: main
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

**4. Add The Private Repo To Argo CD**
If you have the Argo CD CLI logged in:

```bash
argocd repo add git@github.com:mogobanyamwaro/argocd.git \
  --ssh-private-key-path ~/.ssh/argocd_demo_app
```

That is the cleanest method. Argo CD’s official docs support adding SSH private repos with `argocd repo add ... --ssh-private-key-path`.

**5. Apply The Application**
Then apply the app manifest:

```bash
kubectl apply -f application.yaml
```

**6. Sync Or Let Auto-Sync Handle It**
Since your app has automated sync enabled, Argo CD should pick it up automatically.

You can force a sync:

```bash
argocd app sync demo-app
```

Then check status:

```bash
argocd app get demo-app
```

Or with Kubernetes:

```bash
kubectl get application demo-app -n argocd
kubectl get pods -n demo
kubectl get svc -n demo
```

**Alternative Without Argo CD CLI**
You can also create the repo credential as a Kubernetes Secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: repo-mogobanyamwaro-argocd
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: git@github.com:mogobanyamwaro/argocd.git
  sshPrivateKey: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    paste-private-key-here
    -----END OPENSSH PRIVATE KEY-----
```

Apply it:

```bash
kubectl apply -f repo-secret.yaml
kubectl apply -f application.yaml
```
