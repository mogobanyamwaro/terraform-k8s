Fix a broken cluster. This exercise simulates common failures you'll see on the CKA: kubelet down, kube-proxy misconfigured, CoreDNS not resolving.

## Tasks

### Scenario A: Broken kubelet

1. SSH to a worker node
2. Stop the kubelet service
3. From the control plane, observe the node status change to `NotReady`
4. SSH back to the worker and check kubelet logs
5. Restart kubelet and verify the node comes back to `Ready`

### Scenario B: CoreDNS troubleshooting

1. Create a pod and try to resolve a service name — should fail if CoreDNS is broken
2. Check CoreDNS pods in `kube-system`
3. Check CoreDNS logs for errors
4. Verify the CoreDNS ConfigMap for misconfigurations
5. Check that the `kube-dns` service has endpoints
6. Fix any issues and verify DNS resolution works

### Scenario C: kube-proxy

1. Check if kube-proxy pods are running on all nodes
2. Check kube-proxy logs
3. Verify kube-proxy ConfigMap
4. Check iptables rules on a node

### Scenario D: API Server audit logs (Kubernetes 1.35 troubleshooting)

1. Find where audit logs are stored on the control plane node
2. Check the audit policy configuration in the apiserver manifest
3. Look for failed authentication attempts in the audit log
4. Find requests that were denied by RBAC
5. Correlate user identity to request details

---

Here's the **best way** to tackle cluster troubleshooting on the CKA exam – systematic debugging of common failures.

---

## Scenario A: Broken Kubelet

### 1. SSH to worker node

```bash
ssh <worker-node-name>
```

### 2. Stop the kubelet service

```bash
sudo systemctl stop kubelet
```

**Verify it's stopped:**

```bash
sudo systemctl status kubelet
```

### 3. From control plane, observe node status change to NotReady

```bash
kubectl get nodes --watch
```

**Wait 1-2 minutes for status change:**

```bash
kubectl get nodes
```

**Check node conditions:**

```bash
kubectl describe node <worker-node-name> | grep -A5 Conditions
```

### 4. SSH back to worker and check kubelet logs

```bash
sudo journalctl -u kubelet -n 50 --no-pager
```

**Check for specific errors:**

```bash
sudo journalctl -u kubelet -f --since "2 minutes ago"
```

**Check kubelet config:**

```bash
cat /var/lib/kubelet/config.yaml
```

### 5. Restart kubelet and verify node comes back to Ready

```bash
sudo systemctl start kubelet
sudo systemctl status kubelet
```

**From control plane, verify node becomes Ready:**

```bash
kubectl get nodes --watch
```

**Check node becomes Ready:**

```bash
kubectl get nodes
```

---

## Scenario B: CoreDNS Troubleshooting

### 1. Create a pod and try to resolve a service name

```bash
kubectl run test-dns --image=busybox:1.36 --rm -it --restart=Never -- nslookup kubernetes.default
```

**If DNS is broken, you'll get:** `server can't find kubernetes.default: NXDOMAIN`

### 2. Check CoreDNS pods in kube-system

```bash
kubectl get pods -n kube-system | grep coredns
```

**Check if pods are running:**

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

### 3. Check CoreDNS logs for errors

```bash
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50
```

**Check specific pod:**

```bash
kubectl logs -n kube-system coredns-<pod-id> --tail=100
```

**Look for errors like:** `no endpoints available`, `plugin/loop`, `plugin/forward`

### 4. Verify the CoreDNS ConfigMap for misconfigurations

```bash
kubectl get configmap coredns -n kube-system -o yaml
```

**Expected Corefile:**

```yaml
Corefile: |
  .:53 {
      errors
      health
      kubernetes cluster.local in-addr.arpa ip6.arpa {
         pods insecure
         fallthrough in-addr.arpa ip6.arpa
      }
      prometheus :9153
      forward . /etc/resolv.conf
      cache 30
      loop
      reload
      loadbalance
  }
```

### 5. Check that the kube-dns service has endpoints

```bash
kubectl get svc -n kube-system kube-dns
```

**Check endpoints:**

```bash
kubectl get endpoints -n kube-system kube-dns
```

**Expected output:** Has IPs of CoreDNS pods

**If endpoints missing, check pod readiness:**

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide
```

### 6. Fix issues and verify DNS resolution works

**Restart CoreDNS if needed:**

```bash
kubectl rollout restart deployment coredns -n kube-system
```

**Scale if only one replica:**

```bash
kubectl scale deployment coredns -n kube-system --replicas=2
```

**Verify DNS again:**

```bash
kubectl run test-dns --image=busybox:1.36 --rm -it --restart=Never -- nslookup kubernetes.default
```

**Expected output:** `Address: 10.96.0.1`

---

## Scenario C: Kube-Proxy

### 1. Check if kube-proxy pods are running on all nodes

```bash
kubectl get pods -n kube-system | grep kube-proxy
```

**Check per node:**

```bash
kubectl get pods -n kube-system -o wide | grep kube-proxy
```

### 2. Check kube-proxy logs

```bash
kubectl logs -n kube-system -l k8s-app=kube-proxy --tail=50
```

**Check specific pod:**

```bash
kubectl logs -n kube-system kube-proxy-<pod-id> --tail=100
```

**Look for errors:** `failed to list *v1.EndpointSlice`, `iptables restore failed`

### 3. Verify kube-proxy ConfigMap

```bash
kubectl get configmap kube-proxy -n kube-system -o yaml
```

**Check important settings:**

```bash
kubectl get configmap kube-proxy -n kube-system -o jsonpath='{.data.config\.conf}' | grep mode
```

Expected: `mode: "iptables"`

### 4. Check iptables rules on a node

```bash
ssh <node-name>
sudo iptables-save | grep -i kubernetes | head -20
```

**Check kube-proxy service rules:**

```bash
sudo iptables -t nat -L -n | grep KUBE-SERVICES
```

**Restart kube-proxy if needed:**

```bash
kubectl delete pod -n kube-system -l k8s-app=kube-proxy
```

---

## Scenario D: API Server Audit Logs (Kubernetes 1.35)

### 1. Find where audit logs are stored on the control plane node

```bash
ssh control-plane
```

**Check apiserver manifest for audit log path:**

```bash
cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep audit
```

**Look for:**

- `--audit-log-path`
- `--audit-policy-file`

**Common audit log locations:**

```bash
ls -la /var/log/kubernetes/audit/
ls -la /var/log/apiserver-audit.log
```

### 2. Check the audit policy configuration in the apiserver manifest

```bash
cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep -A2 audit-policy-file
```

**View audit policy:**

```bash
cat /etc/kubernetes/audit-policy.yaml
```

**Example policy for troubleshooting:**

```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  - level: Metadata
    verbs: ["get", "list", "watch"]
  - level: RequestResponse
    verbs: ["create", "update", "patch", "delete"]
  - level: Metadata
    users: ["system:unauthenticated"]
```

### 3. Look for failed authentication attempts in the audit log

```bash
sudo grep -i "unauthorized" /var/log/kubernetes/audit/audit.log | tail -20
```

**Check for failed auth:**

```bash
sudo grep -i "authentication failed" /var/log/kubernetes/audit/audit.log | tail -20
```

**Look for specific user:**

```bash
sudo grep "user\":" /var/log/kubernetes/audit/audit.log | grep -i failed | tail -10
```

### 4. Find requests that were denied by RBAC

```bash
sudo grep -i "forbidden" /var/log/kubernetes/audit/audit.log | tail -20
```

**Check response codes 403:**

```bash
sudo grep '"responseStatus":{"code":403}' /var/log/kubernetes/audit/audit.log | tail -10
```

**Format for readability:**

```bash
sudo cat /var/log/kubernetes/audit/audit.log | jq 'select(.responseStatus.code == 403) | {user: .user.username, verb: .verb, resource: .objectRef.resource, namespace: .objectRef.namespace}'
```

### 5. Correlate user identity to request details

```bash
sudo cat /var/log/kubernetes/audit/audit.log | jq 'select(.user.username=="system:serviceaccount:default:test-sa") | {time: .requestReceivedTimestamp, verb: .verb, resource: .objectRef.resource, namespace: .objectRef.namespace, response: .responseStatus.code}'
```

**Check specific user's failed requests:**

```bash
sudo grep "serviceaccount.*default" /var/log/kubernetes/audit/audit.log | grep 403 | jq '.'
```

---

## Quick Verification Commands (Run All)

```bash
echo "=== Node Status ==="
kubectl get nodes

echo -e "\n=== CoreDNS Status ==="
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl get svc -n kube-system kube-dns
kubectl get endpoints -n kube-system kube-dns

echo -e "\n=== Kube-Proxy Status ==="
kubectl get pods -n kube-system -l k8s-app=kube-proxy

echo -e "\n=== DNS Resolution Test ==="
kubectl run test-dns --image=busybox:1.36 --rm -it --restart=Never -- nslookup kubernetes.default

echo -e "\n=== Kubelet Status on Nodes ==="
for node in $(kubectl get nodes -o name | cut -d'/' -f2); do
  echo "Node: $node"
  ssh $node "systemctl is-active kubelet"
done
```

---

## Exam Critical Notes

| Scenario     | Most Common Issue   | Fix                       |
| ------------ | ------------------- | ------------------------- |
| Kubelet down | Service stopped     | `systemctl start kubelet` |
| CoreDNS      | No endpoints        | Restart deployment        |
| CoreDNS      | ConfigMap corrupted | Restore default Corefile  |
| Kube-proxy   | Pod not running     | Delete pod to restart     |
| API audit    | Log path wrong      | Check apiserver flags     |
| RBAC denial  | Missing permissions | Check audit log for 403   |

---

## Common Exam Traps

| Trap                         | Consequence       | Fix                       |
| ---------------------------- | ----------------- | ------------------------- |
| Not checking kubelet logs    | Miss real error   | Always check `journalctl` |
| Restarting wrong CoreDNS pod | No effect         | Check replicas            |
| Ignoring endpoints           | Service broken    | Verify endpoints exist    |
| Not using `jq` for audit     | Hard to read logs | Use `jq` for filtering    |
| Forgetting audit policy      | No logs generated | Check apiserver flags     |

---

## Pro Tips for CKA

1. **Always check component status first** – `kubectl get componentstatuses` (deprecated but works)
2. **Check pod logs systematically** – Start with kube-system pods
3. **DNS is the most common issue** – Always test DNS early
4. **Audit logs are your friend** – Use `jq` to parse JSON
5. **Know the one-liners** – Quick checks save time
6. **SSH to nodes is allowed** – Use it to check kubelet and containers
7. **`crictl` for container runtime** – `crictl ps`, `crictl logs`

---

## Quick Troubleshooting Flow

```
Problem Observed
    ↓
Check kubectl get nodes (node status)
    ↓
If Node NotReady → Check kubelet (SSH, journalctl)
    ↓
If Node Ready but pods fail → Check DNS
    ↓
Check CoreDNS pods and endpoints
    ↓
If DNS works → Check kube-proxy
    ↓
Check kube-proxy pods and iptables
    ↓
If network works → Check RBAC via audit logs
```

---

**Total exam time for troubleshooting:** Depends on issue – typically 5-10 minutes per scenario

**Most likely exam scenario:** One component is broken (usually CoreDNS or kubelet). You must systematically identify and fix it. Always check logs first.
