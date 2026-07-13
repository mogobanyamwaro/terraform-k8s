## Tasks

1. Create a namespace called `exercise-05`
2. Deploy two pods:
   - `frontend` with image `nginx:1.27` and label `role=frontend`
   - `backend` with image `nginx:1.27` and label `role=backend`
3. Verify that `frontend` can reach `backend` on port 80 (should work before any policy)
4. Create a NetworkPolicy named `backend-policy` that:
   - Applies to pods with label `role=backend`
   - Allows ingress only from pods with label `role=frontend` on port 80
   - Allows egress to DNS (UDP port 53) — if you skip this, DNS breaks
5. Verify that `frontend` can still reach `backend`
6. Create a third pod `attacker` with label `role=attacker` and verify it cannot reach `backend`

---

# Solution

Here's my CKA exam approach for **NetworkPolicy** – this is critical for the exam and requires understanding of pod selectors and DNS egress rules.

---

## 1. Create namespace

```bash
kubectl create namespace exercise-05
```

---

## 2. Deploy two pods with labels

**Deploy frontend:**

```bash
kubectl run frontend -n exercise-05 --image=nginx:1.27 --labels="role=frontend"
```

**Deploy backend:**

```bash
kubectl run backend -n exercise-05 --image=nginx:1.27 --labels="role=backend"
```

**Wait for both to be ready:**

```bash
kubectl get pods -n exercise-05 -w
# Press Ctrl+C when both are Running
```

**Verify labels:**

```bash
kubectl get pods -n exercise-05 --show-labels
```

---

## 3. Verify frontend can reach backend (before policy)

**Get backend's IP:**

```bash
kubectl get pod backend -n exercise-05 -o wide
```

**Test connectivity from frontend:**

```bash
kubectl exec -n exercise-05 frontend -- curl -s -o /dev/null -w "%{http_code}\n" backend:80
```

Or using IP directly:

```bash
kubectl exec -n exercise-05 frontend -- curl -s $(kubectl get pod backend -n exercise-05 -o jsonpath='{.status.podIP}')
```

**Expected:** `200` or `000` (nginx returns 200 normally)

**Alternative ping test (ICMP not HTTP):**

```bash
kubectl exec -n exercise-05 frontend -- wget -O- --timeout=2 http://backend:80 2>&1 | head -5
```

---

## 4. Create NetworkPolicy

**Create policy YAML:**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: exercise-05
spec:
  podSelector:
    matchLabels:
      role: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 80
  egress:
  # Allow DNS resolution (critical for kubectl, nslookup, etc.)
  - to:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
  # Allow any other egress (optional - if you want backend to reach internet)
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 80
EOF
```

**Simpler DNS rule (more permissive):**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: exercise-05
spec:
  podSelector:
    matchLabels:
      role: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 80
  egress:
  # Allow DNS (UDP 53) to any pod in kube-system (CoreDNS/kube-dns)
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
  # Allow backend to talk to API server if needed (optional)
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          component: apiserver
    ports:
    - protocol: TCP
      port: 443
EOF
```

**Simplest working DNS rule (exam-friendly):**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: exercise-05
spec:
  podSelector:
    matchLabels:
      role: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 80
  egress:
  # Allow all DNS traffic (simplest, works in most clusters)
  - ports:
    - protocol: UDP
      port: 53
EOF
```

**Verify policy created:**

```bash
kubectl get networkpolicy -n exercise-05
```

---

## 5. Verify frontend can still reach backend

**After policy applies (wait 5-10 seconds):**

```bash
kubectl exec -n exercise-05 frontend -- curl -s -o /dev/null -w "%{http_code}\n" backend:80
```

**Expected:** `200` (still working)

**If connection fails, check:**

```bash
# DNS resolution test from frontend
kubectl exec -n exercise-05 frontend -- nslookup backend

# Direct IP test (bypass DNS)
kubectl exec -n exercise-05 frontend -- curl -s $(kubectl get pod backend -n exercise-05 -o jsonpath='{.status.podIP}')
```

---

## 6. Create attacker pod and verify it cannot reach backend

**Create attacker:**

```bash
kubectl run attacker -n exercise-05 --image=nginx:1.27 --labels="role=attacker"
```

**Wait for it to be ready:**

```bash
kubectl get pod attacker -n exercise-05 -w
```

**Test attacker → backend connection (should fail):**

```bash
kubectl exec -n exercise-05 attacker -- curl -s --max-time 3 -o /dev/null -w "%{http_code}\n" backend:80 || echo "Connection failed"
```

**Expected:** Timeout or connection refused (usually `000` or command hangs then fails)

**Alternative with timeout:**

```bash
kubectl exec -n exercise-05 attacker -- timeout 3 curl -s backend:80
# Should return exit code 124 (timeout)
```

---

## Verification Commands (Run All)

```bash
echo "=== NetworkPolicy Verification ==="

# Show all pods and their IPs
echo "Pods and IPs:"
kubectl get pods -n exercise-05 -o wide

# Show network policy
echo -e "\nNetworkPolicy:"
kubectl get networkpolicy backend-policy -n exercise-05 -o yaml | grep -A10 "spec:"

# Test frontend → backend
echo -e "\nTesting frontend -> backend:"
kubectl exec -n exercise-05 frontend -- sh -c 'curl -s -o /dev/null -w "%{http_code}\n" backend:80'

# Test attacker → backend
echo -e "\nTesting attacker -> backend:"
kubectl exec -n exercise-05 attacker -- sh -c 'curl -s --max-time 3 -o /dev/null -w "%{http_code}\n" backend:80 2>&1 || echo "BLOCKED"'

# Test DNS resolution from backend
echo -e "\nTesting DNS from backend:"
kubectl exec -n exercise-05 backend -- nslookup kubernetes.default 2>&1 | head -3
```

---

## Quick Troubleshooting (Exam Scenarios)

### If frontend cannot reach backend after policy:

**Check 1 – Policy applied to correct pod:**

```bash
kubectl get pods -n exercise-05 --show-labels
kubectl describe networkpolicy backend-policy -n exercise-05
```

**Check 2 – Policy selector matches backend:**

```bash
kubectl get pods -n exercise-05 -l role=backend
```

**Check 3 – DNS broken (most common issue):**

```bash
kubectl exec -n exercise-05 backend -- cat /etc/resolv.conf
kubectl exec -n exercise-05 backend -- nslookup google.com
```

If DNS fails, the egress rule is wrong.

**Check 4 – Try IP instead of service name:**

```bash
BACKEND_IP=$(kubectl get pod backend -n exercise-05 -o jsonpath='{.status.podIP}')
kubectl exec -n exercise-05 frontend -- curl -s $BACKEND_IP:80
```

If IP works but hostname fails → DNS issue.

**Check 5 – Verify network plugin supports policy:**

```bash
kubectl get pods -n kube-system | grep -E "calico|weave|cilium|canal"
```

---

## Exam Critical Notes

### NetworkPolicy Structure

```yaml
podSelector: # Which pods this policy applies to
  matchLabels:
    role: backend

ingress: # Incoming rules
  - from:
      - podSelector: # Allow from pods with label X
          matchLabels:
            role: frontend

egress: # Outgoing rules
  - to:
      - podSelector: # Allow to pods with label Y
    ports:
      - port: 53
        protocol: UDP
```

### Common Exam Traps

| Trap                     | Consequence                                 | Fix                           |
| ------------------------ | ------------------------------------------- | ----------------------------- |
| No egress rule           | Backend can't make ANY outbound connections | Add egress rule               |
| No DNS rule              | Backend can't resolve service names         | Add UDP 53 egress             |
| Wrong namespace selector | Policy won't apply across namespaces        | Use `namespaceSelector: {}`   |
| Forgetting `policyTypes` | Policy may not enforce both directions      | Explicitly set Ingress/Egress |
| Using IP blocks          | Complex, avoid if possible                  | Use podSelector instead       |

### DNS Egress Rules (Essential)

**Most permissive (exam safe):**

```yaml
egress:
  - ports:
      - protocol: UDP
        port: 53
```

**Specific to CoreDNS (if you know labels):**

```yaml
egress:
  - to:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: kube-system
        podSelector:
          matchLabels:
            k8s-app: kube-dns
    ports:
      - protocol: UDP
        port: 53
```

### Checking Default Deny Behavior

**Default for namespaces without policies:** Allow all ingress/egress

**If you want default deny, create this:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
  # No rules = deny all
```

---

## Pro Tips for CKA Exam

1. **Always add DNS egress rule** – Most common exam gotcha
2. **Test connectivity before policy** – Establish baseline
3. **Wait 5-10 seconds after applying** – Policies take effect asynchronously
4. **Use `curl --max-time 3`** – Don't wait forever on blocked connections
5. **Check CoreDNS pod labels** – `kubectl get pods -n kube-system --show-labels` to find correct selector
6. **If in doubt, use port-only egress rules** – Less specific but works in most clusters

---

## Cleanup (Not required for exam, but good practice)

```bash
kubectl delete namespace exercise-05
# Or individually:
# kubectl delete networkpolicy backend-policy -n exercise-05
# kubectl delete pod frontend backend attacker -n exercise-05
```

---

**Total exam time for this task:** ~6-8 minutes (NetworkPolicy takes time due to verification steps)

**Most likely exam scenario:** They'll give you a broken NetworkPolicy (usually missing DNS egress) and ask you to fix it so frontend can reach backend but attacker cannot.
