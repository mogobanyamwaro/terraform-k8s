Install a chart, override values, upgrade to a new version, and roll back when something breaks. Helm is now a standard operational skill on the CKA.

## Tasks

1. Add the Bitnami chart repository and update the repo cache
2. Install NGINX using Helm in a namespace called `exercise-13`:
   - Release name: `web`
   - Set `replicaCount=2`
3. Verify the release is deployed and 2 pods are running
4. Upgrade the release to `replicaCount=3` and record the change
5. Check the release history and confirm there are 2 revisions
6. Roll back to revision 1
7. Verify the replica count is back to 2

---

Here's the **best way** to tackle Helm on the CKA exam – this tests chart installation, upgrades, and rollbacks.

---

## Prerequisite – Verify Helm is installed

```bash
helm version
```

---

## 1. Add Bitnami chart repository and update cache

**Add the Bitnami repository:**

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
```

**Update repo cache:**

```bash
helm repo update
```

**Verify repo is added:**

```bash
helm repo list
```

**Search for the NGINX chart:**

```bash
helm search repo bitnami/nginx
```

---

## 2. Install NGINX using Helm in namespace exercise-13

**Create namespace:**

```bash
kubectl create namespace exercise-13
```

**Install the chart:**

```bash
helm install web bitnami/nginx \
  --namespace exercise-13 \
  --set replicaCount=2
```

**Alternative – using values file (more exam-friendly for complex installs):**

```bash
cat <<EOF > nginx-values.yaml
replicaCount: 2
EOF

helm install web bitnami/nginx \
  --namespace exercise-13 \
  --values nginx-values.yaml
```

**Verify installation:**

```bash
helm list -n exercise-13
```

---

## 3. Verify release is deployed and 2 pods are running

**Check Helm release status:**

```bash
helm status web -n exercise-13
```

**Check pods:**

```bash
kubectl get pods -n exercise-13
```

**Expected:** 2 pods running (names like `web-nginx-xxxxx-xxxxx`)

**Verify replica count in deployment:**

```bash
kubectl get deployment -n exercise-13
```

**Check deployment replicas:**

```bash
kubectl get deployment web-nginx -n exercise-13 -o jsonpath='{.spec.replicas}'
```

Expected output: `2`

---

## 4. Upgrade the release to replicaCount=3 and record the change

**Upgrade with new replica count:**

```bash
helm upgrade web bitnami/nginx \
  --namespace exercise-13 \
  --set replicaCount=3
```

**Alternative with values file:**

```bash
cat <<EOF > nginx-values-updated.yaml
replicaCount: 3
EOF

helm upgrade web bitnami/nginx \
  --namespace exercise-13 \
  --values nginx-values-updated.yaml
```

**Verify upgrade:**

```bash
helm list -n exercise-13
```

**Check pods rolling update:**

```bash
kubectl get pods -n exercise-13 --watch
```

**Wait for 3 pods to be ready:**

```bash
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=web -n exercise-13 --timeout=120s
```

**Verify 3 pods running:**

```bash
kubectl get pods -n exercise-13 | wc -l
```

**Check deployment replicas now 3:**

```bash
kubectl get deployment web-nginx -n exercise-13 -o jsonpath='{.spec.replicas}'
```

Expected output: `3`

---

## 5. Check release history and confirm 2 revisions

**View release history:**

```bash
helm history web -n exercise-13
```

**Expected output:** 2 revisions with different STATUS (deployed, deployed)

**Detailed history with values:**

```bash
helm history web -n exercise-13 --max 5
```

**Check specific revision details:**

```bash
helm get values web --revision 1 -n exercise-13
helm get values web --revision 2 -n exercise-13
```

**Verify revision 1 has replicaCount=2:**

```bash
helm get values web --revision 1 -n exercise-13
```

**Verify revision 2 has replicaCount=3:**

```bash
helm get values web --revision 2 -n exercise-13
```

---

## 6. Roll back to revision 1

**Roll back to previous revision:**

```bash
helm rollback web 1 -n exercise-13
```

**Alternative – rollback to revision 1 with wait:**

```bash
helm rollback web 1 -n exercise-13 --wait
```

**Watch rollback:**

```bash
kubectl get pods -n exercise-13 --watch
```

**Verify rollback status:**

```bash
helm status web -n exercise-13
```

---

## 7. Verify replica count is back to 2

**Check release history after rollback:**

```bash
helm history web -n exercise-13
```

**Expected:** 3 revisions (1,2,3) – revision 3 is the rollback

**Verify current replica count:**

```bash
kubectl get deployment web-nginx -n exercise-13 -o jsonpath='{.spec.replicas}'
```

Expected output: `2`

**Check pods running:**

```bash
kubectl get pods -n exercise-13
```

**Expected:** 2 pods running

**Verify via Helm get values:**

```bash
helm get values web -n exercise-13
```

**Expected output:** `replicaCount: 2`

---

## Quick Verification Commands (Run at end)

```bash
echo "=== Helm Repositories ==="
helm repo list

echo -e "\n=== Helm Releases ==="
helm list -n exercise-13

echo -e "\n=== Release History ==="
helm history web -n exercise-13

echo -e "\n=== Current Values ==="
helm get values web -n exercise-13

echo -e "\n=== Current Pods ==="
kubectl get pods -n exercise-13

echo -e "\n=== Deployment Replicas ==="
kubectl get deployment web-nginx -n exercise-13

echo -e "\n=== Current Revision Details ==="
helm get all web -n exercise-13 | head -30
```

---

## Complete Exam Workflow Script

```bash
# Setup
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
kubectl create namespace exercise-13

# Install
helm install web bitnami/nginx --namespace exercise-13 --set replicaCount=2
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=web -n exercise-13 --timeout=120s

# Verify install
kubectl get pods -n exercise-13
helm list -n exercise-13

# Upgrade
helm upgrade web bitnami/nginx --namespace exercise-13 --set replicaCount=3
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=web -n exercise-13 --timeout=120s

# Verify upgrade
kubectl get pods -n exercise-13
helm history web -n exercise-13

# Rollback
helm rollback web 1 -n exercise-13
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=web -n exercise-13 --timeout=120s

# Final verification
kubectl get pods -n exercise-13
helm get values web -n exercise-13
```

---

## Exam Critical Notes

| Command            | Purpose              | Key Flags                          |
| ------------------ | -------------------- | ---------------------------------- |
| `helm repo add`    | Add chart repository | URL and repo name                  |
| `helm repo update` | Update local cache   | Always run after adding            |
| `helm install`     | Deploy chart         | `--namespace`, `--set`, `--values` |
| `helm upgrade`     | Update release       | New values, same chart             |
| `helm history`     | View revisions       | Shows deployment timeline          |
| `helm rollback`    | Revert to revision   | Revision number, `--wait`          |
| `helm status`      | Current state        | Verify deployment                  |
| `helm get values`  | Show configuration   | `--revision` to see old            |

---

## Common Exam Traps

| Trap                              | Consequence                | Fix                              |
| --------------------------------- | -------------------------- | -------------------------------- |
| Forgetting `helm repo update`     | Can't find chart           | Run update after adding repo     |
| Wrong namespace flag              | Release in wrong namespace | Use `--namespace` consistently   |
| Missing chart name in upgrade     | Upgrade fails              | `helm upgrade <release> <chart>` |
| Not waiting after upgrade         | Verify too early           | Use `--wait` or wait manually    |
| Rollback to wrong revision        | Unexpected config          | Check history first              |
| No values file for complex config | Long command line          | Use `--values` with YAML         |

---

## Additional Helm Commands for Exam

**see the rendered output**

```bash

helm template myapp ./mychat
```

**Uninstall a release:**

```bash
helm uninstall web -n exercise-13
```

**Get manifest of deployed resources:**

```bash
helm get manifest web -n exercise-13
```

**Template locally (dry-run with values):**

```bash
helm template web bitnami/nginx --set replicaCount=2
```

**Show default values for chart:**

```bash
helm show values bitnami/nginx
```

**Pull chart locally:**

```bash
helm pull bitnami/nginx --untar
```

**Dependency management:**

```bash
helm dependency update
```

---

## Values Precedence (Exam Important)

Order of precedence (highest to lowest):

1. `--set` flags (command line)
2. `--values` files (YAML)
3. Chart's `values.yaml`
4. Chart's `values.schema.json`

**Multiple values files:**

```bash
helm install web bitnami/nginx \
  --values common-values.yaml \
  --values prod-values.yaml \
  --set extra.key=value
```

---

## Release Lifecycle

```
Install (revision 1)
    ↓
Upgrade (revision 2)
    ↓
Upgrade (revision 3)
    ↓
Rollback (revision 4 - copies revision 2)
    ↓
Uninstall (removes release, keeps history if configured)
```

---

## Pro Tips for CKA

1. **Always use `--wait` in scripts** – Ensures operations complete
2. **Check history before rollback** – Know which revision you're going to
3. **Use `--dry-run` to test** – `helm install --dry-run --debug`
4. **Bitnami is the standard test repo** – Use for exam practice
5. **Record changes** – No explicit `--record` flag in Helm 3 (history tracks automatically)
6. **Namespace management** – Helm releases are namespaced
7. **Values files are easier to audit** – Use them for complex configurations

---

## Troubleshooting

**Release stuck in pending:**

```bash
helm history web -n exercise-13
helm rollback web <previous-revision> -n exercise-13
```

**Chart not found:**

```bash
helm repo update
helm search repo bitnami/nginx
```

**Permission denied:**

```bash
kubectl create namespace exercise-13
# Ensure you have permissions
```

**PVC stuck (if chart uses persistence):**

```bash
kubectl get pvc -n exercise-13
kubectl describe pvc <pvc-name> -n exercise-13
```

---

**Total exam time for this task:** ~5-7 minutes

**Most likely exam scenario:** Install a Helm chart (often bitnami/nginx or bitnami/redis), scale it up, then roll back. They may give you a broken values file to fix.
