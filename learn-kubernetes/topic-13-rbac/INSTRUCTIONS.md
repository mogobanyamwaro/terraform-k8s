# Topic 13: RBAC (Role-Based Access Control)

## What You'll Learn

- **Role** – permissions in a namespace
- **ClusterRole** – permissions cluster-wide (or reusable)
- **RoleBinding** – binds Role to subject(s) in a namespace
- **ClusterRoleBinding** – binds ClusterRole to subject(s) cluster-wide
- **ServiceAccount** – identity for pod processes (used with RBAC)
- `apiGroups`, `resources`, `verbs` (get, list, create, update, delete, etc.)

## Steps

### 1. Apply manifests

```bash
kubectl apply -f .
```

### 2. Inspect RBAC

```bash
kubectl get role,rolebinding -n rbac-demo
kubectl get clusterrole,clusterrolebinding
kubectl describe role pod-reader -n rbac-demo
kubectl describe rolebinding read-pods -n rbac-demo
```

### 3. Test ServiceAccount token (optional)

```bash
kubectl create token dev-sa -n rbac-demo --duration=1h
```

### 4. Imperative create (exam favorite)

```bash
# Create ServiceAccount
kubectl create serviceaccount my-sa -n default

# Create Role with get/list pods
kubectl create role pod-reader --verb=get,list --resource=pods -n default

# Create RoleBinding
kubectl create rolebinding read-pods --role=pod-reader --serviceaccount=default:my-sa -n default

# ClusterRole + ClusterRoleBinding
kubectl create clusterrole pv-reader --verb=get,list --resource=persistentvolumes
kubectl create clusterrolebinding read-pvs --clusterrole=pv-reader --serviceaccount=default:my-sa
```

### 5. Clean up

```bash
kubectl delete -f .
```

---

## Exam Tips

| Command                                                                | Purpose                     |
| ---------------------------------------------------------------------- | --------------------------- |
| `kubectl create role X --verb=get,list --resource=pods -n <ns>`        | Create Role                 |
| `kubectl create clusterrole X --verb=get --resource=pods`              | Create ClusterRole          |
| `kubectl create rolebinding X --role=Y --user=alice -n <ns>`           | Bind role to user           |
| `kubectl create rolebinding X --role=Y --serviceaccount=ns:sa -n <ns>` | Bind role to ServiceAccount |
| `kubectl create clusterrolebinding X --clusterrole=Y --user=alice`     | Cluster-wide binding        |
| `kubectl auth can-i get pods --as=system:serviceaccount:ns:sa`         | Test permissions            |

**Common verbs:** get, list, create, update, patch, delete, deletecollection, watch

## Practice

1. Create a ServiceAccount `app-sa` in namespace `prod`.
2. Create a Role that allows `get` and `list` on ConfigMaps.
3. Create a RoleBinding that grants that role to `app-sa` in `prod`.
4. Run: `kubectl auth can-i list configmaps --as=system:serviceaccount:prod:app-sa -n prod` → should return `yes`.
