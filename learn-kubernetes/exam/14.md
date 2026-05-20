Build a base deployment and apply an overlay that changes the namespace and replica count. Kustomize is built into kubectl and is now part of the CKA skill set.

## Tasks

1. Create a directory structure:
   ```
   kustomize-lab/
     base/
       deployment.yaml
       service.yaml
       kustomization.yaml
     overlays/
       staging/
         kustomization.yaml
   ```
2. In the base:
   - A Deployment named `app` with image `nginx:1.27` and 1 replica
   - A ClusterIP Service named `app-svc` on port 80
   - A `kustomization.yaml` listing both resources
3. In the staging overlay:
   - Set namespace to `exercise-14`
   - Patch replicas to 3
   - Add a common label `env: staging`
4. Create namespace `exercise-14`
5. Apply the staging overlay with `kubectl apply -k`
6. Verify 3 pods are running in namespace `exercise-14` with label `env=staging`

---

Here's the **best way** to tackle Kustomize on the CKA exam – this tests overlay patterns and kubectl integration.

---

## 1. Create directory structure

```bash
mkdir -p kustomize-lab/base
mkdir -p kustomize-lab/overlays/staging
```

---

## 2. Create base resources

### 2a. Create base deployment.yaml

```bash
cat <<EOF > kustomize-lab/base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app
  template:
    metadata:
      labels:
        app: app
    spec:
      containers:
      - name: nginx
        image: nginx:1.27
        ports:
        - containerPort: 80
EOF
```

### 2b. Create base service.yaml

```bash
cat <<EOF > kustomize-lab/base/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: app-svc
spec:
  selector:
    app: app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
```

### 2c. Create base kustomization.yaml

```bash
cat <<EOF > kustomize-lab/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
EOF
```

---

## 3. Create staging overlay

### 3a. Create staging kustomization.yaml

```bash
cat <<EOF > kustomize-lab/overlays/staging/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: exercise-14

resources:
  - ../../base

patches:
  - patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: app
      spec:
        replicas: 3
    target:
      kind: Deployment
      name: app

commonLabels:
  env: staging
EOF
```

---

## 4. Create namespace exercise-14

```bash
kubectl create namespace exercise-14
```

---

## 5. Apply staging overlay with kubectl apply -k

```bash
kubectl apply -k kustomize-lab/overlays/staging/
```

**Alternative – using full path:**

```bash
kubectl apply -k ./kustomize-lab/overlays/staging
```

**Expected output:**

```
deployment.apps/app created
service/app-svc created
```

**Preview what will be applied (dry-run):**

```bash
kubectl apply -k kustomize-lab/overlays/staging/ --dry-run=client -o yaml
```

---

## 6. Verify 3 pods are running in namespace exercise-14 with label env=staging

**Check pods:**

```bash
kubectl get pods -n exercise-14
```

**Expected:** 3 pods running

**Check pod labels:**

```bash
kubectl get pods -n exercise-14 --show-labels
```

**Expected:** Each pod has `env=staging` and `app=app`

**Verify replica count:**

```bash
kubectl get deployment app -n exercise-14 -o jsonpath='{.spec.replicas}'
```

Expected output: `3`

**Check service:**

```bash
kubectl get svc app-svc -n exercise-14
```

**Verify service selector includes env label:**

```bash
kubectl get svc app-svc -n exercise-14 -o yaml | grep -A3 selector
```

**Check all resources:**

```bash
kubectl get all -n exercise-14
```

---

## Quick Verification Commands

```bash
echo "=== Namespace Resources ==="
kubectl get all -n exercise-14

echo -e "\n=== Pod Count ==="
kubectl get pods -n exercise-14 --no-headers | wc -l

echo -e "\n=== Pod Labels ==="
kubectl get pods -n exercise-14 --show-labels

echo -e "\n=== Deployment Replicas ==="
kubectl get deployment app -n exercise-14 -o jsonpath='{.spec.replicas}'
echo ""

echo -e "\n=== Service Details ==="
kubectl get svc app-svc -n exercise-14

echo -e "\n=== Rendered Kustomization ==="
kubectl kustomize kustomize-lab/overlays/staging/ | head -40
```

---

## Additional Kustomize Commands for Exam

**Build and view rendered YAML:**

```bash
kubectl kustomize kustomize-lab/overlays/staging/
```

**Apply with specific kustomization file:**

```bash
kubectl apply -k kustomize-lab/overlays/staging/
```

**Delete resources managed by kustomize:**

```bash
kubectl delete -k kustomize-lab/overlays/staging/
```

**Diff before applying:**

```bash
kubectl diff -k kustomize-lab/overlays/staging/
```

---

## Common Kustomize Patches for Exam

### Strategic Merge Patch (used above)

```yaml
patches:
  - patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: app
      spec:
        replicas: 3
    target:
      kind: Deployment
      name: app
```

### JSON Patch (alternative)

```yaml
patchesJson6902:
  - target:
      group: apps
      version: v1
      kind: Deployment
      name: app
    path: patch.json
```

### Patch with inline JSON

```yaml
patchesStrategicMerge:
  - |-
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: app
    spec:
      replicas: 3
```

---

## More Overlay Examples

### Production overlay (different namespace, more replicas)

```bash
mkdir -p kustomize-lab/overlays/production
```

```yaml
# kustomize-lab/overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: exercise-14-prod

resources:
  - ../../base

patches:
  - patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: app
      spec:
        replicas: 5
        template:
          spec:
            containers:
            - name: nginx
              image: nginx:1.28
    target:
      kind: Deployment
      name: app

commonLabels:
  env: production
```

---

## Image Transformation (Exam Important)

**Change image without modifying base:**

```yaml
# In overlay kustomization.yaml
images:
  - name: nginx
    newName: nginx
    newTag: 1.29
```

**Or with registry change:**

```yaml
images:
  - name: nginx
    newName: myregistry/nginx
    newTag: latest
```

---

## Namespace Management with Kustomize

**Setting namespace in overlay:**

```yaml
namespace: exercise-14
```

**This adds namespace to ALL resources in the base**

**If resources already have namespace in base:**

```yaml
# Use patches to remove/override
patchesStrategicMerge:
  - |-
    apiVersion: v1
    kind: Service
    metadata:
      name: app-svc
      namespace: null
```

---

## Common Labels and Annotations

**Add labels to all resources:**

```yaml
commonLabels:
  env: staging
  managed-by: kustomize
  team: devops
```

**Add annotations:**

```yaml
commonAnnotations:
  deployed-by: kubectl-kustomize
  version: "1.0"
```

---

## ConfigMap Generator (Common Exam Pattern)

```yaml
# In kustomization.yaml
configMapGenerator:
  - name: app-config
    literals:
      - APP_MODE=production
      - LOG_LEVEL=debug
  - name: app-config-file
    files:
      - config.properties
```

**Reference in deployment:**

```yaml
# Patch to add envFrom
patchesStrategicMerge:
  - |-
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: app
    spec:
      template:
        spec:
          containers:
          - name: nginx
            envFrom:
            - configMapRef:
                name: app-config
```

---

## Secret Generator

```yaml
secretGenerator:
  - name: app-secret
    literals:
      - DB_PASS=s3cret
    type: Opaque
```

---

## Exam Critical Notes

| Kustomize Feature    | Syntax                | Use Case                        |
| -------------------- | --------------------- | ------------------------------- |
| `resources`          | List of file paths    | Include base resources          |
| `namespace`          | String                | Set namespace for all resources |
| `patches`            | List of patch objects | Modify specific fields          |
| `commonLabels`       | Key/value pairs       | Add labels to all resources     |
| `images`             | Name/newName/newTag   | Update container images         |
| `configMapGenerator` | List of generators    | Create ConfigMaps               |

---

## Common Exam Traps

| Trap                          | Consequence             | Fix                            |
| ----------------------------- | ----------------------- | ------------------------------ |
| Wrong patch target            | Patch doesn't apply     | Match apiVersion, kind, name   |
| Forgetting commonLabels scope | Labels not on pods      | Labels apply to all resources  |
| Missing namespace in overlay  | Resources in default ns | Add `namespace:` field         |
| Path error in resources       | Can't find base         | Use relative path `../../base` |
| No selector match             | Service can't find pods | Ensure labels match            |
| kubectl apply without -k      | Treated as regular file | Always use `-k` for kustomize  |

---

## Pro Tips for CKA

1. **Use `kubectl kustomize` to preview** – See rendered YAML before applying
2. **Kustomize is built into kubectl** – No separate installation needed
3. **Overlay paths are relative** – `../../base` works from overlays/staging/
4. **Base should be generic** – No namespace, minimal replicas
5. **Overlay adds environment specifics** – Namespace, replicas, labels
6. **`commonLabels` affects selectors** – Be careful with existing labels
7. **Test with `--dry-run`** – Always dry-run before applying

---

## Complete Directory Structure After Setup

```
kustomize-lab/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/
    └── staging/
        └── kustomization.yaml
```

---

## Clean Up

```bash
# Delete resources from overlay
kubectl delete -k kustomize-lab/overlays/staging/

# Delete namespace
kubectl delete namespace exercise-14

# Remove directory structure
rm -rf kustomize-lab/
```

---

**Total exam time for this task:** ~5-6 minutes

**Most likely exam scenario:** You're given a base deployment and need to create an overlay that changes namespace, replica count, and adds labels. Or debug why an overlay isn't applying correctly (usually path or selector issues).
