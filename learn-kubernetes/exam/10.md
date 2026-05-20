Create a static pod by placing a manifest in the kubelet's static pod directory. Static pods are managed directly by the kubelet, not the API server.

## Tasks

1. Find the static pod manifest directory on the node
2. Create a static pod manifest file for a pod named `static-web` with:
   - Image: `nginx:1.27`
   - Port: 80
3. Verify the static pod appears in `k get pods` (it will have the node name appended)
4. Try to delete the static pod with `kubectl` — observe what happens
5. Delete the static pod by removing the manifest file
6. Verify the pod is gone

---

Here's the **best way** to tackle static pods on the CKA exam – this tests your understanding of kubelet-managed pods.

---

## 1. Find the static pod manifest directory on the node

**Check kubelet configuration:**

```bash
ps aux | grep kubelet
```

**Look for `--pod-manifest-path` flag:**

```bash
ps aux | grep kubelet | grep pod-manifest-path
```

**Check kubelet config file (common locations):**

```bash
cat /var/lib/kubelet/config.yaml | grep staticPodPath
```

**Standard static pod paths (check these):**

```bash
ls -la /etc/kubernetes/manifests/
ls -la /var/lib/kubelet/manifests/
```

**If you can't find it, check kubelet config:**

```bash
cat /var/lib/kubelet/config.yaml
```

Look for: `staticPodPath: /etc/kubernetes/manifests`

---

## 2. Create static pod manifest file

**Navigate to the static pod directory (using the path found above):**

```bash
cd /etc/kubernetes/manifests/
```

**Create the manifest:**

```bash
cat <<EOF | sudo tee /etc/kubernetes/manifests/static-web.yaml
apiVersion: v1
kind: Pod
metadata:
  name: static-web
  labels:
    app: static-web
spec:
  containers:
  - name: web
    image: nginx:1.27
    ports:
    - containerPort: 80
EOF
```

**Verify the file exists:**

```bash
ls -la /etc/kubernetes/manifests/static-web.yaml
```

---

## 3. Verify the static pod appears in `kubectl get pods`

**Wait a few seconds for kubelet to pick up the manifest:**

```bash
sleep 10
```

**List pods:**

```bash
kubectl get pods
```

**Look for the static pod – note the appended node name:**

```bash
kubectl get pods | grep static-web
```

**Expected output:** `static-web-<node-name>` (e.g., `static-web-controlplane`)

**Detailed view:**

```bash
kubectl get pods -o wide | grep static-web
```

**Check pod status:**

```bash
kubectl describe pod static-web-<node-name>
```

---

## 4. Try to delete the static pod with kubectl

**Attempt deletion:**

```bash
kubectl delete pod static-web-<node-name>
```

**Watch what happens (run in another terminal):**

```bash
kubectl get pods --watch
```

**Observe:** The pod gets recreated immediately by the kubelet

**Verify it's back:**

```bash
kubectl get pods | grep static-web
```

**Check the pod age (resets):**

```bash
kubectl get pods -o wide | grep static-web
```

**Key takeaway:** Static pods cannot be deleted via API server – only by removing manifest

---

## 5. Delete the static pod by removing the manifest file

**Remove the manifest:**

```bash
sudo rm /etc/kubernetes/manifests/static-web.yaml
```

**Verify file is gone:**

```bash
ls -la /etc/kubernetes/manifests/
```

---

## 6. Verify the pod is gone

**Wait for kubelet to detect removal:**

```bash
sleep 5
```

**Check pods:**

```bash
kubectl get pods | grep static-web
```

**Expected:** No output (pod is gone)

**Verify with detailed list:**

```bash
kubectl get pods --all-namespaces | grep static-web
```

**Check kubelet logs (optional):**

```bash
journalctl -u kubelet -n 20 | grep static-web
```

---

## Quick Verification Commands

```bash
echo "=== Static Pod Directory ==="
cat /var/lib/kubelet/config.yaml | grep staticPodPath

echo -e "\n=== Current Static Pods ==="
ls -la /etc/kubernetes/manifests/

echo -e "\n=== Pods in Cluster ==="
kubectl get pods --all-namespaces

echo -e "\n=== Static Pod in API ==="
kubectl get pods | grep static-web

echo -e "\n=== Kubelet Static Pod Status ==="
sudo crictl pods | grep static-web
```

---

## Exam Critical Notes

| Aspect             | Detail                               | Command                            |
| ------------------ | ------------------------------------ | ---------------------------------- |
| Manifest directory | Usually `/etc/kubernetes/manifests/` | Check `--pod-manifest-path`        |
| Pod naming         | `{pod-name}-{node-name}`             | kubelet appends node name          |
| Management         | Kubelet, not API server              | Can't delete via kubectl           |
| Resurrection       | Immediate after kubectl delete       | Removed only via manifest deletion |
| High availability  | Not recommended for control plane    | Use for self-hosted control plane  |

---

## Common Exam Traps

| Trap                         | Consequence                  | Fix                                  |
| ---------------------------- | ---------------------------- | ------------------------------------ |
| Wrong manifest directory     | Pod never appears            | Find correct path via kubelet config |
| Forgetting to wait           | Pod not yet running          | Wait 10-30 seconds                   |
| Trying to delete via kubectl | Confusion when pod reappears | Understand static pod behavior       |
| Not using sudo               | Permission denied            | Use `sudo` for manifest directory    |
| Removing wrong manifest      | Wrong pod deleted            | Double-check filename                |

---

## Pro Tips for CKA

1. **Find path systematically** – Check config.yaml first, then command line
2. **Wait after creating** – Kubelet scans directory every 20 seconds by default
3. **Static pod names are predictable** – Always `name-nodename`
4. **Can't edit via kubectl** – Edit manifest file directly instead
5. **Use `crictl` for debugging** – `crictl pods` shows container runtime pods
6. **Check kubelet logs if pod doesn't appear** – `journalctl -u kubelet -f`

---

## Additional Static Pod Operations

**View static pod manifest on node:**

```bash
cat /etc/kubernetes/manifests/static-web.yaml
```

**Edit running static pod (change image):**

```bash
# Edit manifest
sudo vi /etc/kubernetes/manifests/static-web.yaml

# Change image to nginx:1.28
# Kubelet will automatically update the pod
kubectl get pods --watch
```

**Check pod is recreated after manifest update:**

```bash
kubectl get pods -o wide | grep static-web
```

**Move manifest temporarily (disable pod):**

```bash
sudo mv /etc/kubernetes/manifests/static-web.yaml /tmp/
sleep 10
kubectl get pods | grep static-web  # Should be gone
```

---

## Understanding Static Pod Architecture

```
kubelet (on node)
    ↓ watches
static pod manifest directory (/etc/kubernetes/manifests/)
    ↓ creates
Static Pod (managed by kubelet)
    ↓ mirrored
Mirror Pod (read-only in API server)
```

**Key differences from regular pods:**

| Regular Pod            | Static Pod                        |
| ---------------------- | --------------------------------- |
| Managed by API server  | Managed by kubelet                |
| YAML/JSON sent to API  | File on node                      |
| Deleted via kubectl    | Deleted via manifest removal      |
| Can be updated via API | Can only be updated on filesystem |
| Pod name is given      | Pod name gets node suffix         |

---

## Production Static Pod Uses

**Control plane components (kube-apiserver, etcd, kube-scheduler):**

```bash
ls -la /etc/kubernetes/manifests/
```

Expected: `kube-apiserver.yaml`, `etcd.yaml`, `kube-controller-manager.yaml`

**These are static pods** – that's why kubeadm clusters auto-heal control plane

---

## Troubleshooting

**Pod stuck in Pending:**

```bash
kubectl describe pod static-web-<node-name>
kubectl get events --all-namespaces | grep static-web
```

**Pod not appearing:**

```bash
# Check if kubelet has correct path
ps aux | grep kubelet | grep pod-manifest-path

# Check file permissions
ls -la /etc/kubernetes/manifests/static-web.yaml

# Check kubelet logs
journalctl -u kubelet -n 50 | grep -i manifest
```

**Port conflict:**

```bash
# Check if port 80 already used
netstat -tulpn | grep :80
```

---

**Total exam time for this task:** ~4-5 minutes

**Most likely exam scenario:** They'll ask you to create a static pod (usually for control plane component or simple nginx) and demonstrate that it survives kubectl deletion. You must find the manifest directory first.
