Install Argo CD and configure it to deploy applications from a Git repository. Tests GitOps concepts and custom resource management.

## Tasks

1. Install Argo CD in cluster:
   - Create `argocd` namespace
   - Apply Argo CD manifests (WITHOUT CRDs if specified)
2. Generate Kubernetes manifest template:
   - Define an Application resource
   - Point to a Git repository
   - Specify deployment target namespace
   - Do NOT install CRDs — let Argo CD install them
3. Save generated Application manifest to file
4. Verify Argo CD server is Running
5. Apply the Application manifest
6. Verify application deployment syncs
7. Create a port-forward to Argo CD UI (optional testing)

## Key Learning

- GitOps: cluster state matches Git repository
- Argo CD Application resource is a CRD
- CRDs are NOT in base manifests — error if you apply before Argo CD
- Application must specify repoURL, path, destination
- Exam tests CRD understanding and GitOps workflow

---

Here is the **best way** to install Argo CD and configure it to deploy applications from a Git repository on the CKA exam. This tests GitOps principles and Custom Resource Definition (CRD) management.

The core GitOps principle is that your Git repository acts as the single source of truth .

### 1. Install Argo CD in the Cluster

First, create the `argocd` namespace and apply the official installation manifests. It is critical to use the **`namespace-install.yaml`** manifest as per the task requirements to avoid issues with CRDs .

```bash
# Create the namespace
kubectl create namespace argocd

# Apply the namespace-scoped installation manifest (CRDs are NOT included here)
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/namespace-install.yaml
```

### 2. Generate the Kubernetes Manifest Template for the Application

Now, create the `Application` Custom Resource manifest. This file defines the connection between your Git repository and the Kubernetes cluster .

Create a file named `application.yaml`. You must fill in `<YOUR_GITHUB_REPO_URL>` with the actual URL of your repository.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-gitops-app
  namespace: argocd
spec:
  project: default
  source:
    # [REQUIRED] URL of your Git repository
    repoURL: "<YOUR_GITHUB_REPO_URL>"
    # Branch or tag to track
    targetRevision: HEAD
    # Path within the repo where the Kubernetes manifests are stored
    path: Kubernetes-manifest
  destination:
    # 'https://kubernetes.default.svc' targets the local cluster where Argo CD is installed
    server: "https://kubernetes.default.svc"
    # [REQUIRED] Target namespace for your application
    namespace: my-app-namespace
  syncPolicy:
    # Optional: Automates the synchronization process
    automated:
      # Prune resources that are deleted from Git
      prune: true
      # Automatically fix configuration drift
      selfHeal: true
    # Creates the target namespace if it doesn't exist
    syncOptions:
      - CreateNamespace=true
```

**Important Explanations for the Exam**:

- **`repoURL`**: Must point to your specific Git repository containing the application manifests .
- **`path`**: Tells Argo CD which folder in the repository to monitor for YAML files.
- **`destination`**: Defines where to deploy the resources. Using `https://kubernetes.default.svc` means "this same cluster" .
- **`syncPolicy`**: This is the heart of GitOps. `automated: prune: true` ensures the cluster state is perfectly mirrored to Git .

### 3. Save the Generated Application Manifest to File

Save the YAML content from step 2 into a file named `application.yaml`.

```bash
# Verify the file exists
ls -la application.yaml
```

### 4. Verify Argo CD Server is Running

Before applying the `Application`, ensure all Argo CD pods are up and running .

```bash
kubectl get pods -n argocd
```

**Expected output:** All pods should show `STATUS: Running`.

### 5. Apply the Application Manifest

Now, apply the `Application` manifest to the cluster. This registers your application with Argo CD.

```bash
kubectl apply -f application.yaml
```

**Expected output:** `application.argoproj.io/my-gitops-app created`

### 6. Verify Application Deployment Syncs

Check the status of your application to confirm it has synced successfully.

```bash
# View the application status
kubectl get application my-gitops-app -n argocd
```

Wait for the `SYNC STATUS` and `HEALTH STATUS` to show as `Synced` and `Healthy`.

### 7. (Optional) Port-Forward to Argo CD UI

To view the GitOps process visually, you can port-forward the Argo CD server and log in.

**Retrieve the auto-generated admin password:**

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

**Port-forward the server service:**

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

You can now access the UI at `https://localhost:8080` with the username `admin` and the password retrieved above.

---

### Key Learning for the CKA Exam

- **GitOps Model**: Argo CD continuously "pulls" changes from Git to ensure the cluster matches the desired state defined in the repository .
- **CRD Requirement**: The `namespace-install.yaml` does not include CRDs. They must be installed separately or the cluster must already have them. The task explicitly says to let Argo CD handle this .
- **Application Resource**: This is the core CRD used to connect a Git repository (`source`) to a target cluster (`destination`) .
- **ApplicationSet**: While not in this basic task, `ApplicationSet` is an advanced feature that allows generating multiple Applications from a single template .
