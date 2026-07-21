# 07. Disable Service Account Token Automount

**Domain:** Cluster Hardening

## Question

In namespace `cks-07`, create a ServiceAccount named `app-sa` that does not automatically mount API tokens. Run a pod using that ServiceAccount and verify there is no token mounted.

## Answer

Create namespace and ServiceAccount:

```bash
kubectl create namespace cks-07
kubectl create serviceaccount app-sa -n cks-07
```

Patch the ServiceAccount:

```bash
kubectl patch serviceaccount app-sa -n cks-07 \
  -p '{"automountServiceAccountToken": false}'
```

Create a pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app
  namespace: cks-07
spec:
  serviceAccountName: app-sa
  containers:
  - name: app
    image: busybox:1.36
    command: ["sleep", "3600"]
```

Apply:

```bash
kubectl apply -f app.yaml
kubectl wait --for=condition=Ready pod/app -n cks-07 --timeout=60s
```

## Verify

Check the ServiceAccount:

```bash
kubectl get serviceaccount app-sa -n cks-07 -o yaml
```

Check token path inside the pod:

```bash
kubectl exec -n cks-07 app -- ls /var/run/secrets/kubernetes.io/serviceaccount
```

Expected: no such file or directory.

Also inspect volumes:

```bash
kubectl get pod app -n cks-07 -o yaml | grep -A5 serviceaccount
```

## Pod-Level Override

You can also set it directly on a Pod:

```yaml
spec:
  automountServiceAccountToken: false
```

Pod-level settings override ServiceAccount settings.

## Exam tips

- Many applications do not need Kubernetes API credentials.
- Turning off automount reduces blast radius if the pod is compromised.
- If the app needs API access, create a dedicated least-privilege Role and RoleBinding.

