Create multi-namespace NetworkPolicies with ingress/egress rules, requiring careful label matching and debugging network connectivity.

## Tasks

1. Create 3 namespaces: `frontend`, `backend`, `database`
2. Deploy apps:
   - Frontend (nginx): labels `tier=frontend`
   - Backend (busybox): labels `tier=backend`
   - Database (redis): labels `tier=database`
3. Create NetworkPolicies:
   - Allow frontend → backend (only port 8080)
   - Allow backend → database (only port 6379)
   - Deny all other traffic initially
   - Allow DNS egress (UDP 53) to kube-dns for all pods
4. Test connectivity:
   - Frontend CAN reach backend on 8080
   - Frontend CANNOT reach database
   - Backend CAN reach database on 6379
   - Backend CANNOT reach frontend
5. Verify DNS still works from all namespaces

## Key Learning

- NetworkPolicies are pod label selectors, not namespace selectors alone
- Ingress rules applied to target pods
- Egress rules applied to source pods
- Must explicitly allow DNS egress or service discovery breaks
- Debugging: use `k describe pod` and check labels carefully
- Exam tests label matching precision

---

Here's the **best way** to tackle multi-namespace NetworkPolicies on the CKA exam – this tests complex ingress/egress rules across namespaces.

---

## Understanding Multi-Namespace NetworkPolicy

| Component          | NetworkPolicy Direction | Target          |
| ------------------ | ----------------------- | --------------- |
| Frontend → Backend | Ingress on backend      | backend pods    |
| Backend → Database | Ingress on database     | database pods   |
| DNS (UDP 53)       | Egress on ALL pods      | kube-system DNS |
| Deny all else      | Default deny            | All pods        |

---

## 1. Create 3 namespaces

```bash
kubectl create namespace frontend
kubectl create namespace backend
kubectl create namespace database
```

---

## 2. Deploy apps with proper labels

### Frontend (nginx) – namespace: frontend

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      tier: frontend
  template:
    metadata:
      labels:
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.28
        ports:
        - containerPort: 80
EOF
```

### Backend (busybox) – namespace: backend

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      tier: backend
  template:
    metadata:
      labels:
        tier: backend
    spec:
      containers:
      - name: busybox
        image: busybox:1.36
        command: ["sleep", "3600"]
        ports:
        - containerPort: 8080
EOF
```

### Database (redis) – namespace: database

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: database
spec:
  replicas: 1
  selector:
    matchLabels:
      tier: database
  template:
    metadata:
      labels:
        tier: database
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
EOF
```

### Create Services for connectivity

```bash
# Backend service (port 8080)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: backend
spec:
  selector:
    tier: backend
  ports:
  - port: 8080
    targetPort: 8080
EOF

# Database service (port 6379)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: database
  namespace: database
spec:
  selector:
    tier: database
  ports:
  - port: 6379
    targetPort: 6379
EOF
```

---

## 3. Create NetworkPolicies

### Default Deny Policies for each namespace (optional but recommended)

```bash
# Default deny ingress for backend
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: backend
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF

# Default deny ingress for database
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: database
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF
```

### Allow DNS Egress for ALL namespaces (critical for connectivity)

```bash
# DNS egress for frontend namespace
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: frontend
spec:
  podSelector: {}
  policyTypes:
  - Egress
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
EOF

# DNS egress for backend namespace
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: backend
spec:
  podSelector: {}
  policyTypes:
  - Egress
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
EOF

# DNS egress for database namespace
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: database
spec:
  podSelector: {}
  policyTypes:
  - Egress
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
EOF
```

### Allow Frontend → Backend (Ingress on backend, port 8080)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend
      podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080
EOF
```

### Allow Backend → Database (Ingress on database, port 6379)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-database
  namespace: database
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: backend
      podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 6379
EOF
```

---

## 4. Test Connectivity

### Test 1: Frontend CAN reach backend on port 8080

**First, get backend pod IP or use service name:**

```bash
# Get backend service IP
kubectl get svc backend -n backend
```

**Test from frontend pod:**

```bash
kubectl exec -n frontend deploy/frontend -- sh -c "wget -O- --timeout=3 backend.backend.svc.cluster.local:8080 2>&1 || echo 'Connection failed'"
```

**Expected:** Connection succeeds (or busybox responds)

**Alternative – install curl in frontend:**

```bash
kubectl exec -n frontend deploy/frontend -- apk add curl
kubectl exec -n frontend deploy/frontend -- curl -v backend.backend.svc.cluster.local:8080
```

### Test 2: Frontend CANNOT reach database

```bash
kubectl exec -n frontend deploy/frontend -- sh -c "nc -zv database.database.svc.cluster.local 6379 2>&1 || echo 'Blocked'"
```

**Expected:** Connection fails (timeout or connection refused)

### Test 3: Backend CAN reach database on port 6379

```bash
kubectl exec -n backend deploy/backend -- sh -c "nc -zv database.database.svc.cluster.local 6379 2>&1"
```

**Expected:** Connection succeeds (redis port open)

**Alternative test:**

```bash
kubectl exec -n backend deploy/backend -- nslookup database.database.svc.cluster.local
kubectl exec -n backend deploy/backend -- wget -O- --timeout=3 database.database.svc.cluster.local:6379 2>&1 | head -5
```

### Test 4: Backend CANNOT reach frontend

```bash
kubectl exec -n backend deploy/backend -- sh -c "nc -zv frontend.frontend.svc.cluster.local 80 2>&1 || echo 'Blocked'"
```

**Expected:** Connection fails (no ingress rule from backend to frontend)

---

## 5. Verify DNS still works from all namespaces

### Test DNS from frontend namespace

```bash
kubectl exec -n frontend deploy/frontend -- nslookup kubernetes.default
kubectl exec -n frontend deploy/frontend -- nslookup google.com
```

### Test DNS from backend namespace

```bash
kubectl exec -n backend deploy/backend -- nslookup kubernetes.default
kubectl exec -n backend deploy/backend -- nslookup backend.backend.svc.cluster.local
```

### Test DNS from database namespace

```bash
kubectl exec -n database deploy/database -- nslookup kubernetes.default
kubectl exec -n database deploy/database -- nslookup database.database.svc.cluster.local
```

**Expected:** All DNS resolutions succeed

---

## Quick Verification Commands

```bash
echo "=== Network Policies ==="
kubectl get networkpolicy -A

echo -e "\n=== Pods ==="
kubectl get pods -A -l 'tier in (frontend,backend,database)'

echo -e "\n=== Test: Frontend → Backend (should succeed) ==="
kubectl exec -n frontend deploy/frontend -- sh -c "wget -O- --timeout=3 backend.backend.svc.cluster.local:8080 2>&1 | head -1"

echo -e "\n=== Test: Frontend → Database (should fail) ==="
kubectl exec -n frontend deploy/frontend -- sh -c "nc -zv database.database.svc.cluster.local 6379 2>&1 || echo 'BLOCKED'"

echo -e "\n=== Test: Backend → Database (should succeed) ==="
kubectl exec -n backend deploy/backend -- sh -c "nc -zv database.database.svc.cluster.local 6379 2>&1"

echo -e "\n=== Test: Backend → Frontend (should fail) ==="
kubectl exec -n backend deploy/backend -- sh -c "nc -zv frontend.frontend.svc.cluster.local 80 2>&1 || echo 'BLOCKED'"

echo -e "\n=== Test: DNS Resolution (frontend) ==="
kubectl exec -n frontend deploy/frontend -- nslookup kubernetes.default 2>&1 | grep -E "Server|Address"
```

---

## Debugging Common Issues

### Issue 1: Frontend cannot reach backend

**Check backend pod labels:**

```bash
kubectl get pods -n backend --show-labels
```

**Check network policy labels:**

```bash
kubectl describe networkpolicy allow-frontend-to-backend -n backend
```

**Check if backend has default-deny policy:**

```bash
kubectl get networkpolicy -n backend
```

### Issue 2: DNS not working

**Check DNS egress policy:**

```bash
kubectl describe networkpolicy allow-dns-egress -n frontend
```

**Check CoreDNS pod labels:**

```bash
kubectl get pods -n kube-system --show-labels | grep coredns
```

**Test DNS manually:**

```bash
kubectl exec -n frontend deploy/frontend -- cat /etc/resolv.conf
```

### Issue 3: Cross-namespace communication fails

**Check namespace labels:**

```bash
kubectl get ns --show-labels
```

**Ensure namespaceSelector uses correct label:**

```yaml
namespaceSelector:
  matchLabels:
    kubernetes.io/metadata.name: frontend
```

---

## NetworkPolicy Cheat Sheet

| Rule                     | Ingress/Egress | Location           | Target               |
| ------------------------ | -------------- | ------------------ | -------------------- |
| Allow frontend → backend | Ingress        | backend namespace  | backend pods         |
| Allow backend → database | Ingress        | database namespace | database pods        |
| DNS egress               | Egress         | ALL namespaces     | kube-system DNS pods |
| Default deny             | Ingress        | backend/database   | All pods             |

---

## Pro Tips for CKA

1. **Namespace label is automatic** – `kubernetes.io/metadata.name` always exists
2. **DNS egress is critical** – Without UDP 53, service discovery breaks
3. **Test before policies** – Establish baseline connectivity first
4. **Policy applies to podSelector** – Blank `podSelector: {}` applies to ALL pods
5. **Ingress rules go on target pods** – The pod receiving traffic
6. **Egress rules go on source pods** – The pod initiating traffic
7. **Label matching is exact** – Misspelling breaks the policy

---

## Clean Up

```bash
# Delete network policies
kubectl delete networkpolicy -n backend --all
kubectl delete networkpolicy -n database --all
kubectl delete networkpolicy -n frontend --all

# Delete deployments
kubectl delete deployment -n frontend frontend
kubectl delete deployment -n backend backend
kubectl delete deployment -n database database

# Delete services
kubectl delete svc -n backend backend
kubectl delete svc -n database database

# Delete namespaces
kubectl delete namespace frontend backend database
```

---

**Total exam time for this task:** ~10-12 minutes

**Most likely exam scenario:** Three-tier app (frontend, backend, database) with specific traffic flows. DNS breaks after policies – fix by adding UDP 53 egress. Or cross-namespace communication broken – fix namespaceSelector labels.
