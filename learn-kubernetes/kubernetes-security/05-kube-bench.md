# 05. Run Kube-Bench And Fix A Control Plane Finding

**Domain:** Cluster Setup

## Question

Run a CIS-style benchmark using `kube-bench`, identify a failed API server check, and harden the static pod manifest.

## Answer

Run `kube-bench` if installed:

```bash
sudo kube-bench run --targets master
```

If the exam provides `kube-bench` as a pod or job, inspect the manifest path in the question and run it as instructed.

Common API server checks involve flags in:

```bash
/etc/kubernetes/manifests/kube-apiserver.yaml
```

Backup the manifest:

```bash
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml.bak
```

Example fix: disable anonymous API access:

```bash
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

Add or update this command flag:

```yaml
- --anonymous-auth=false
```

Example fix: ensure authorization modes include RBAC and Node:

```yaml
- --authorization-mode=Node,RBAC
```

Example fix: ensure admission plugins include NodeRestriction:

```yaml
- --enable-admission-plugins=NodeRestriction
```

The kubelet watches `/etc/kubernetes/manifests` and restarts the static pod automatically.

## Verify

Wait for the API server to recover:

```bash
sudo crictl ps | grep kube-apiserver
kubectl get nodes
```

Check the live command:

```bash
kubectl -n kube-system get pod -l component=kube-apiserver -o yaml | grep -E 'anonymous-auth|authorization-mode|enable-admission-plugins'
```

Rerun the relevant benchmark target:

```bash
sudo kube-bench run --targets master
```

## Exam tips

- Always backup static pod manifests before editing.
- A bad YAML edit can temporarily break the API server.
- Static pod changes may take 30 to 90 seconds to settle.
- If `kubectl` is down, use `sudo crictl ps` and `sudo crictl logs`.

