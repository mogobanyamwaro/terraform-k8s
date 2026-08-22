# 11. Remove Risky Cluster-Admin Binding

**Domain:** Cluster Hardening

## Question

A user `dev1` was accidentally granted `cluster-admin`. Remove that access, then grant only read access to pods in namespace `cks-11`.

## Answer

Find bindings that reference `dev1`:

```bash
kubectl get clusterrolebinding -o wide | grep dev1
kubectl get rolebinding -A -o wide | grep dev1
```

Inspect the suspicious ClusterRoleBinding:

```bash
kubectl describe clusterrolebinding dev1-admin
```

If it binds `dev1` to `cluster-admin`, delete it:

```bash
kubectl delete clusterrolebinding dev1-admin
```

Create namespace and least privilege Role:

```bash
kubectl create namespace cks-11
kubectl create role pod-reader -n cks-11 \
  --verb=get,list,watch \
  --resource=pods
```

Bind it to `dev1`:

```bash
kubectl create rolebinding dev1-pod-reader -n cks-11 \
  --role=pod-reader \
  --user=dev1
```

## Verify

```bash
kubectl auth can-i '*' '*' --as=dev1
kubectl auth can-i list pods --as=dev1 -n cks-11
kubectl auth can-i delete pods --as=dev1 -n cks-11
kubectl auth can-i get secrets --as=dev1 -n cks-11
```

Expected:

```text
no
yes
no
no
```

## Exam tips

- `cluster-admin` is almost always too much.
- Use `kubectl describe clusterrolebinding <name>` before deleting.
- If a task asks for namespace-only access, use Role plus RoleBinding.

