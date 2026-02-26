# Topic 4: ConfigMaps & Secrets

## What You'll Learn

- **ConfigMap** – key-value config (non-sensitive)
- **Secret** – base64-encoded sensitive data
- `envFrom`, `env`, `volumeMount` for injecting into pods
- `kubectl create configmap`, `kubectl create secret`

## Steps

### 1. Apply

```bash
kubectl apply -f .
```

### 2. Inspect

```bash
kubectl get configmap app-config -o yaml
kubectl get secret app-secret -o yaml
kubectl logs config-pod
```

### 3. Imperative create

```bash
kubectl create configmap my-config --from-literal=KEY=value
kubectl create secret generic my-secret --from-literal=PASS=secret123
```

### 4. Delete

```bash
kubectl delete -f .
```

---

## Exam Tips

| Command                                              | Purpose                     |
| ---------------------------------------------------- | --------------------------- |
| `kubectl create configmap X --from-literal=k=v`      | Create ConfigMap            |
| `kubectl create secret generic X --from-literal=k=v` | Create Secret               |
| `envFrom`                                            | Inject all keys as env vars |
| Secret values                                        | Base64 encoded              |

## Practice

1. Create a ConfigMap `db-config` with `HOST=localhost` and `PORT=5432`.
2. Create a Secret `db-cred` with `DB_PASSWORD=supersecret`.
