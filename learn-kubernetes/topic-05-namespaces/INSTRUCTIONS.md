# Topic 5: Namespaces & Context

## What You'll Learn

- **Namespace** – logical grouping, resource isolation
- `kubectl get pods -n <namespace>`
- `kubectl config set-context`
- Default namespaces: default, kube-system, kube-public

## Steps

### 1. Create namespace

```bash
kubectl apply -f namespace.yaml
kubectl create namespace prod
```

### 2. Work in namespace

```bash
kubectl run nginx -n dev --image=nginx --restart=Never
kubectl get pods -n dev
kubectl get pods -A
```

### 3. Switch context

```bash
kubectl config get-contexts
kubectl config set-context --current --namespace=dev
kubectl get pods   # Now shows dev namespace
```

### 4. Set default namespace for current context

```bash
kubectl config set-context --current --namespace=default
```

---

## Exam Tips

| Command                                                 | Purpose            |
| ------------------------------------------------------- | ------------------ |
| `kubectl get pods -A`                                   | All namespaces     |
| `kubectl get pods -n <ns>`                              | Specific namespace |
| `kubectl config set-context --current --namespace=<ns>` | Switch namespace   |
| `kubectl create namespace X`                            | Create namespace   |

## Practice

1. Create a pod in the `prod` namespace.
2. List all resources in `dev` namespace.
