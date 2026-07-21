# 06. Least Privilege RBAC

**Domain:** Cluster Hardening

## Question

In namespace `cks-06`, create a Role that allows user `sam` to only `get`, `list`, and `watch` pods. `sam` must not be able to delete pods or read Secrets.

## Answer

Create namespace:

```bash
kubectl create namespace cks-06
```

Create Role:

```bash
kubectl create role pod-viewer \
  --namespace=cks-06 \
  --verb=get,list,watch \
  --resource=pods
```

Create RoleBinding:

```bash
kubectl create rolebinding sam-pod-viewer \
  --namespace=cks-06 \
  --role=pod-viewer \
  --user=sam
```

## Verify

Allowed:

```bash
kubectl auth can-i list pods --as=sam -n cks-06
kubectl auth can-i watch pods --as=sam -n cks-06
```

Denied:

```bash
kubectl auth can-i delete pods --as=sam -n cks-06
kubectl auth can-i get secrets --as=sam -n cks-06
```

Expected:

```text
yes
yes
no
no
```

## YAML Alternative

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-viewer
  namespace: cks-06
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sam-pod-viewer
  namespace: cks-06
subjects:
- kind: User
  name: sam
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-viewer
  apiGroup: rbac.authorization.k8s.io
```

## Exam tips

- Use `kubectl auth can-i` to prove the result.
- Role is namespace-scoped. ClusterRole can be cluster-scoped or bound inside a namespace.
- Do not use `cluster-admin` unless the task explicitly asks for it.

