Set up Role-Based Access Control with Roles, ClusterRoles, and bindings. This is heavily tested on the CKA.

## Tasks

1. Create a namespace called `exercise-04`
2. Create a ServiceAccount named `dev-sa` in namespace `exercise-04`
3. Create a Role named `pod-manager` in namespace `exercise-04` that allows:
   - `get`, `list`, `watch`, `create`, `delete` on `pods`
   - `get`, `list` on `services`
4. Create a RoleBinding named `dev-pod-access` that binds `pod-manager` to `dev-sa`
5. Verify that `dev-sa` can list pods in `exercise-04`
6. Verify that `dev-sa` cannot list pods in `default` namespace
7. Create a ClusterRole named `node-viewer` that allows `get`, `list` on `nodes`
8. Create a ClusterRoleBinding named `dev-node-access` binding `node-viewer` to `dev-sa`
9. Verify that `dev-sa` can now list nodes

## Additional Real-Exam Scenarios

10. A developer reports they cannot delete a deployment in `exercise-04`. Use `k auth can-i` to debug why
11. Test what `dev-sa` can do with deployments (should return "no")
12. List all permissions granted to `dev-sa` in the `exercise-04` namespace

---

# Solution

Here's my CKA exam approach for **RBAC** – this is heavily tested, so efficiency and accuracy are critical.

---

## Part 1: Core Tasks (1-9)

### 1. Create namespace

```bash
kubectl create namespace exercise-04
```

### 2. Create ServiceAccount

```bash
kubectl create serviceaccount dev-sa -n exercise-04
```

### 3. Create Role (pod-manager)

**Option A – Imperative (fastest):**

```bash
kubectl create role pod-manager -n exercise-04 \
  --verb=get,list,watch,create,delete \
  --resource=pods \
  --verb=get,list \
  --resource=services \
  --dry-run=client -o yaml | kubectl apply -f -
```

**Option B – Create YAML if complex:**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-manager
  namespace: exercise-04
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch", "create", "delete"]
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list"]
EOF
```

### 4. Create RoleBinding

```bash
kubectl create rolebinding dev-pod-access -n exercise-04 \
  --role=pod-manager \
  --serviceaccount=exercise-04:dev-sa
```

**Verify binding:**

```bash
kubectl get rolebinding dev-pod-access -n exercise-04 -o yaml
```

### 5. Verify dev-sa can list pods in exercise-04

**Test with `kubectl auth can-i` (no actual pod needed):**

```bash
kubectl auth can-i list pods -n exercise-04 \
  --as=system:serviceaccount:exercise-04:dev-sa
```

**Expected:** `yes`

**Alternative – create test pod and actually try:**

```bash
# Create a test pod first
kubectl run test-pod -n exercise-04 --image=nginx:1.27 --sleep 3600

# Test with actual token
kubectl run test -n exercise-04 --image=busybox:1.36 --rm -it --restart=Never \
  --command -- sh -c "kubectl get pods -n exercise-04" \
  --as=system:serviceaccount:exercise-04:dev-sa
```

### 6. Verify cannot list pods in default namespace

```bash
kubectl auth can-i list pods -n default \
  --as=system:serviceaccount:exercise-04:dev-sa
```

**Expected:** `no`

### 7. Create ClusterRole (node-viewer)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-viewer
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list"]
EOF
```

### 8. Create ClusterRoleBinding

```bash
kubectl create clusterrolebinding dev-node-access \
  --clusterrole=node-viewer \
  --serviceaccount=exercise-04:dev-sa
```

### 9. Verify can list nodes

```bash
kubectl auth can-i list nodes \
  --as=system:serviceaccount:exercise-04:dev-sa
```

**Expected:** `yes`

**Actual test:**

```bash
kubectl get nodes --as=system:serviceaccount:exercise-04:dev-sa
```

---

## Part 2: Real-Exam Scenarios (10-12)

### 10. Debug why developer cannot delete deployment

**First, test the specific action:**

```bash
kubectl auth can-i delete deployments -n exercise-04 \
  --as=system:serviceaccount:exercise-04:dev-sa
```

**Check more specifically with verb and resource:**

```bash
kubectl auth can-i delete deployment.apps/test -n exercise-04 \
  --as=system:serviceaccount:exercise-04:dev-sa
```

**If deployment exists, test with resource name:**

```bash
kubectl auth can-i delete deployment/actual-name -n exercise-04 \
  --as=system:serviceaccount:exercise-04:dev-sa
```

**List all permissions for troubleshooting:**

```bash
kubectl auth can-i --list -n exercise-04 \
  --as=system:serviceaccount:exercise-04:dev-sa
```

### 11. Test what dev-sa can do with deployments

**Individual checks:**

```bash
kubectl auth can-i get deployments -n exercise-04 \
  --as=system:serviceaccount:exercise-04:dev-sa

kubectl auth can-i create deployments -n exercise-04 \
  --as=system:serviceaccount:exercise-04:dev-sa

kubectl auth can-i delete deployments -n exercise-04 \
  --as=system:serviceaccount:exercise-04:dev-sa
```

**Expected:** `no` for all (unless explicitly granted)

**Bulk check:**

```bash
for verb in get list watch create update patch delete; do
  echo -n "$verb: "
  kubectl auth can-i $verb deployments -n exercise-04 \
    --as=system:serviceaccount:exercise-04:dev-sa
done
```

### 12. List all permissions for dev-sa in exercise-04

**Method 1 – Using `kubectl auth can-i --list`:**

```bash
kubectl auth can-i --list -n exercise-04 \
  --as=system:serviceaccount:exercise-04:dev-sa
```

**Method 2 – Using `kubectl describe` (shows bindings):**

```bash
# See role binding
kubectl describe rolebinding dev-pod-access -n exercise-04

# See role details
kubectl describe role pod-manager -n exercise-04

# See cluster role binding
kubectl describe clusterrolebinding dev-node-access
```

**Method 3 – Using `kubectl get` with JSONPath:**

```bash
# Get all role bindings for this SA
kubectl get rolebinding,clusterrolebinding -A -o json | \
  jq '.items[] | select(.subjects[]?.name=="dev-sa") | .roleRef'
```

**Method 4 – Custom resource permissions query:**

```bash
# Check multiple resources at once
for resource in pods services deployments configmaps secrets; do
  echo "=== $resource ==="
  kubectl auth can-i get $resource -n exercise-04 \
    --as=system:serviceaccount:exercise-04:dev-sa
  kubectl auth can-i create $resource -n exercise-04 \
    --as=system:serviceaccount:exercise-04:dev-sa
  kubectl auth can-i delete $resource -n exercise-04 \
    --as=system:serviceaccount:exercise-04:dev-sa
  echo
done
```

---

## Quick Reference Table – What dev-sa can do after setup

| Resource    | Namespace    | Actions                      | Access |
| ----------- | ------------ | ---------------------------- | ------ |
| pods        | exercise-04  | get,list,watch,create,delete | ✅     |
| services    | exercise-04  | get,list                     | ✅     |
| deployments | exercise-04  | (any)                        | ❌     |
| pods        | default      | any                          | ❌     |
| nodes       | cluster-wide | get,list                     | ✅     |

---

## Exam Critical Notes

### RBAC Components

```
ServiceAccount → (binding) → Role/ClusterRole → Permissions
```

### Key Differences

|          | Role                | ClusterRole                 |
| -------- | ------------------- | --------------------------- |
| Scope    | Single namespace    | Cluster-wide                |
| Binding  | RoleBinding         | ClusterRoleBinding          |
| Use case | Namespace resources | Nodes, CRDs, non-namespaced |

### Common Exam Traps

❌ **Wrong API group for pods/services:**

```yaml
apiGroups: ["apps"] # Wrong - pods in core group
```

✅ **Correct:**

```yaml
apiGroups: [""] # Core API group
```

❌ **Binding with wrong namespace:**

```bash
# Role in namespace X must bind to SA in same namespace X
kubectl create rolebinding X -n X --role=Y --serviceaccount=X:Z
```

✅ **SA namespace must match Role namespace**

### Debugging Commands (Must Know)

```bash
# Check if I can perform action
kubectl auth can-i <verb> <resource> [-n namespace]

# Check as specific user/SA
kubectl auth can-i <verb> <resource> --as=system:serviceaccount:ns:sa-name

# List all permissions
kubectl auth can-i --list [-n namespace]

# Check specific resource instance
kubectl auth can-i delete pod/nginx -n default
```

---

## Verification Script (Run at end)

```bash
#!/bin/bash
NS=exercise-04
SA=dev-sa

echo "=== Verification Results ==="

# Test 5: List pods in exercise-04
echo -n "List pods in $NS: "
kubectl auth can-i list pods -n $NS --as=system:serviceaccount:$NS:$SA

# Test 6: List pods in default
echo -n "List pods in default: "
kubectl auth can-i list pods -n default --as=system:serviceaccount:$NS:$SA

# Test 9: List nodes
echo -n "List nodes: "
kubectl auth can-i list nodes --as=system:serviceaccount:$NS:$SA

# Test 10: Delete deployment
echo -n "Delete deployment in $NS: "
kubectl auth can-i delete deployments -n $NS --as=system:serviceaccount:$NS:$SA

# All permissions in $NS
echo -e "\n=== All permissions in $NS ==="
kubectl auth can-i --list -n $NS --as=system:serviceaccount:$NS:$SA | grep -E "^pods|^services|^deployments"
```

---

## Pro Tips for CKA Exam

1. **Use `--as` flag** – never actually try to perform actions you're testing
2. **Remember SA format:** `system:serviceaccount:<namespace>:<sa-name>`
3. **Check both role and clusterrole** – sometimes permissions come from unexpected places
4. **`kubectl auth can-i --list` is gold** – shows all effective permissions
5. **Default deny** – if no rule matches, access is denied
6. **API groups matter** – `apps/v1` deployments vs `v1` pods

**Total exam time for this task:** ~8-10 minutes (RBAC takes longer due to verification steps)

**Most likely exam scenario:** They'll give you a broken RBAC setup and ask you to fix it – practice debugging!
