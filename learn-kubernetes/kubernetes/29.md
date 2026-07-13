Debug and fix a broken control plane where API server points to wrong etcd endpoint. Tests troubleshooting methodology and static pod modification.

## Tasks

1. Cluster is broken: API server won't start
2. Check kube-apiserver pod logs
3. Find the error: incorrect etcd endpoint IP or port
4. SSH into control plane node
5. Edit `/etc/kubernetes/manifests/kube-apiserver.yaml`
6. Correct the etcd endpoint in `--etcd-servers=` flag
7. Verify IP/port matches `/etc/kubernetes/manifests/etcd.yaml`
8. Save and wait for API server to restart
9. Verify cluster is healthy:
   - `k get nodes` works
   - `k get pods -A` works
   - API server is Running

## Key Learning

- Static pods in `/etc/kubernetes/manifests/` auto-restart on file changes
- API server cannot start without etcd connection
- etcd endpoint must be exact: `https://127.0.0.1:2379` or `https://<etcd-ip>:2379`
- Troubleshooting: check pod logs first, then manifest
- Exam tests understanding of control plane components

---

Assuming your VMs are something like:

```bash
multipass list
```

```text
Name       State     IPv4
master     Running   192.168.64.22
worker1    Running   192.168.64.21
worker2    Running   192.168.64.23
```

SSH into the control plane:

```bash
multipass shell master
```

First confirm this is a kubeadm-style cluster:

```bash
ls /etc/kubernetes/manifests/
```

You should see:

```text
etcd.yaml
kube-apiserver.yaml
kube-controller-manager.yaml
kube-scheduler.yaml
```

Now check the current etcd endpoint:

```bash
sudo grep "etcd-servers" /etc/kubernetes/manifests/kube-apiserver.yaml
```

You may see:

```yaml
- --etcd-servers=https://127.0.0.1:2379
```

### Simulate the failure

Back up the manifest first:

```bash
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml \
/tmp/kube-apiserver.yaml.backup
```

Edit it:

```bash
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

Change:

```yaml
- --etcd-servers=https://127.0.0.1:2379
```

to an intentionally wrong port:

```yaml
- --etcd-servers=https://127.0.0.1:2380
```

Save the file.

Because `kube-apiserver` is a **static pod**, kubelet will notice the manifest changed and recreate it with the bad configuration.

After a short while:

```bash
kubectl get nodes
```

should fail with something like:

```text
The connection to the server ... was refused
```

Now you're effectively in the exam scenario.

### Troubleshoot it

Since the API server is down, this won't help:

```bash
kubectl logs kube-apiserver-...
```

Instead use the container runtime directly:

```bash
sudo crictl ps -a | grep kube-apiserver
```

Then:

```bash
sudo crictl logs <container-id>
```

You should see errors indicating the API server cannot connect to etcd, likely involving:

```text
127.0.0.1:2380
```

Now inspect etcd:

```bash
sudo grep -E "listen-client-urls|advertise-client-urls" \
/etc/kubernetes/manifests/etcd.yaml
```

You'll probably see:

```yaml
- --advertise-client-urls=https://192.168.64.22:2379
- --listen-client-urls=https://127.0.0.1:2379,https://192.168.64.22:2379
```

That tells you **2379 is the correct etcd client port**.

Fix the API server:

```bash
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

Change:

```yaml
- --etcd-servers=https://127.0.0.1:2380
```

back to:

```yaml
- --etcd-servers=https://127.0.0.1:2379
```

Save.

You do **not** need to run:

```bash
systemctl restart kube-apiserver
```

There is no normal kube-apiserver systemd service in this setup. Kubelet monitors `/etc/kubernetes/manifests/` and recreates the static pod automatically.

Verify recovery:

```bash
kubectl get nodes
```

Expected:

```text
NAME      STATUS   ROLES           AGE
master    Ready    control-plane   ...
worker1   Ready    <none>          ...
worker2   Ready    <none>          ...
```

Then:

```bash
kubectl get pods -A
```

and specifically:

```bash
kubectl get pods -n kube-system | grep kube-apiserver
```

You want:

```text
kube-apiserver-master   1/1   Running
```



