Gateway API is GA in v1.35 and replaces classic Ingress for modern traffic management. Set up a Gateway and route HTTP traffic to a backend service.

## Tasks

1. Create a namespace called `exercise-15`
2. Verify a GatewayClass exists in the cluster (depends on your CNI/controller)
3. Create a Gateway named `web-gateway` in namespace `exercise-15`:
   - Reference the existing GatewayClass
   - Listen on port 80, protocol HTTP
4. Create a Deployment named `web` with image `nginx:1.28` and 2 replicas
5. Expose it with a ClusterIP Service named `web-svc` on port 80
6. Create an HTTPRoute named `web-route` that:
   - References `web-gateway` as the parent
   - Matches path prefix `/`
   - Routes to `web-svc` on port 80
7. Verify the Gateway status shows `Programmed: True`
8. Verify the HTTPRoute is attached to the Gateway

---

Here's the **best way** to tackle Gateway API on the CKA exam – this tests modern ingress routing for Kubernetes v1.35.

---

## Prerequisite – Check Gateway API CRDs are installed

```bash
kubectl get crd | grep gateway
```

**Expected CRDs:** `gatewayclasses.gateway.networking.k8s.io`, `gateways.gateway.networking.k8s.io`, `httproutes.gateway.networking.k8s.io`

**If CRDs missing (exam environment should have them):**

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/experimental-install.yaml
```

---

## 1. Create namespace

```bash
kubectl create namespace exercise-15
```

---

## 2. Verify a GatewayClass exists in the cluster

- Install the standard Gateway API custom resource definitions (CRDs) if not already present.

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml
```

- Instlll NGINX Gateway Fabric controller (or any other supported controller) if not already present.

```bash
# Install the CRDs specific to NGINX Gateway Fabric
kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v1.6.1/deploy/crds.yaml

# Install the controller and related resources (includes GatewayClass)
kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v1.6.1/deploy/nodeport/deploy.yaml
```

- Deploy the metallb

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.16.1/config/manifests/metallb-native.yaml
```

-Verify pods are running

```bash
kubectl get pods -n metallb-system
```

- Configure metallb with a pool of IPs (adjust range as needed for your environment)

```bash
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: my-ip-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.100-192.168.1.150   # Adjust this range to match your network
```

- configure the Advertisement for the IP pool ( Layer 2 mode)

```bash
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: my-l2-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
  - my-ip-pool
```

**List available GatewayClasses:**

```bash
kubectl get gatewayclass
```

**Examine a GatewayClass:**

```bash
kubectl get gatewayclass -o yaml
```

**Check which controller is available:**

```bash
kubectl get gatewayclass -o jsonpath='{.items[*].spec.controllerName}'
```

**Common GatewayClass names in exam:**

- `nginx` (NGINX Gateway Fabric)
- `cilium` (Cilium)
- `istio` (Istio)
- `standard` (Generic)
- `gke-l7-gxlb` (GKE)

**If multiple exist, pick one:**

```bash
GATEWAY_CLASS=$(kubectl get gatewayclass -o jsonpath='{.items[0].metadata.name}')
echo $GATEWAY_CLASS
```

---

## 3. Create Gateway in namespace exercise-15

**Create Gateway referencing existing GatewayClass:**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
  namespace: exercise-15
spec:
  gatewayClassName: $GATEWAY_CLASS
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: Same
EOF
```

**Verify Gateway creation:**

```bash
kubectl get gateway web-gateway -n exercise-15
```

---

## 4. Create Deployment with nginx:1.28 and 2 replicas

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: exercise-15
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.28
        ports:
        - containerPort: 80
EOF
```

**Wait for deployment to be ready:**

```bash
kubectl wait --for=condition=available deployment/web -n exercise-15 --timeout=60s
```

**Verify pods:**

```bash
kubectl get pods -n exercise-15 -l app=web
```

---

## 5. Expose with ClusterIP Service named web-svc on port 80

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: exercise-15
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
```

**Verify service:**

```bash
kubectl get svc web-svc -n exercise-15
```

---

## 6. Create HTTPRoute referencing web-gateway

```bash
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: exercise-15
spec:
  parentRefs:
  - name: web-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web-svc
      port: 80
EOF
```

**Alternative with specific hostname:**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: exercise-15
spec:
  parentRefs:
  - name: web-gateway
  hostnames:
  - "example.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web-svc
      port: 80
EOF
```

---

## 7. Verify Gateway status shows Programmed: True

**Check Gateway status:**

```bash
kubectl get gateway web-gateway -n exercise-15 -o yaml | grep -A10 status
```

**Check specific condition:**

```bash
kubectl get gateway web-gateway -n exercise-15 -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}'
```

Expected output: `True`

**Detailed status check:**

```bash
kubectl describe gateway web-gateway -n exercise-15 | grep -A20 "Status:"
```

**Verify listeners are ready:**

```bash
kubectl get gateway web-gateway -n exercise-15 -o jsonpath='{.status.listeners[*].conditions[?(@.type=="Ready")].status}'
```

---

## 8. Verify HTTPRoute is attached to Gateway

**Check HTTPRoute status:**

```bash
kubectl get httproute web-route -n exercise-15 -o yaml | grep -A15 status
```

**Verify parent status shows Accepted:**

```bash
kubectl get httproute web-route -n exercise-15 -o jsonpath='{.status.parents[*].conditions[?(@.type=="Accepted")].status}'
```

Expected output: `True`

**Check route is resolved:**

```bash
kubectl get httproute web-route -n exercise-15 -o jsonpath='{.status.parents[*].conditions[?(@.type=="ResolvedRefs")].status}'
```

**Describe HTTPRoute:**

```bash
kubectl describe httproute web-route -n exercise-15
```

---

## Quick Verification Commands

```bash
echo "=== GatewayClass ==="
kubectl get gatewayclass

echo -e "\n=== Gateway ==="
kubectl get gateway web-gateway -n exercise-15
kubectl get gateway web-gateway -n exercise-15 -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}'
echo " - Programmed status"

echo -e "\n=== HTTPRoute ==="
kubectl get httproute web-route -n exercise-15

echo -e "\n=== Backend Resources ==="
kubectl get deployment,service,pods -n exercise-15 -l app=web

echo -e "\n=== Gateway Address (if provisioned) ==="
kubectl get gateway web-gateway -n exercise-15 -o jsonpath='{.status.addresses[*].value}'
echo ""

echo -e "\n=== Route Parents ==="
kubectl get httproute web-route -n exercise-15 -o jsonpath='{.status.parents[*].parentRef.name}'
echo ""
```

---

## Test the Route (if Gateway has external address)

**Get Gateway external address:**

```bash
GATEWAY_ADDR=$(kubectl get gateway web-gateway -n exercise-15 -o jsonpath='{.status.addresses[0].value}')
echo $GATEWAY_ADDR
```

**Test with curl (if address is accessible):**

```bash
curl -H "Host: example.com" http://$GATEWAY_ADDR/
```

**Or test internally with port-forward:**

```bash
kubectl port-forward -n exercise-15 service/web-svc 8080:80 &
curl http://localhost:8080/
```

---

## Advanced HTTPRoute Examples

### Path-based routing to different backends

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: exercise-15
spec:
  parentRefs:
    - name: web-gateway
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
      backendRefs:
        - name: api-svc
          port: 8080
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: web-svc
          port: 80
```

### Header-based routing

```yaml
rules:
  - matches:
      - headers:
          - name: version
            value: v2
    backendRefs:
      - name: web-svc-v2
        port: 80
```

### Weighted routing (canary)

```yaml
rules:
  - matches:
      - path:
          type: PathPrefix
          value: /
    backendRefs:
      - name: web-svc-v1
        port: 80
        weight: 90
      - name: web-svc-v2
        port: 80
        weight: 10
```

### Request modification

```yaml
rules:
  - matches:
      - path:
          type: PathPrefix
          value: /
    filters:
      - type: RequestHeaderModifier
        requestHeaderModifier:
          set:
            - name: X-Custom-Header
              value: gateway-proxy
    backendRefs:
      - name: web-svc
        port: 80
```

---

## Exam Critical Notes

| Resource     | Purpose                 | Key Fields                                |
| ------------ | ----------------------- | ----------------------------------------- |
| GatewayClass | Defines controller type | `spec.controllerName`                     |
| Gateway      | Listener configuration  | `spec.gatewayClassName`, `spec.listeners` |
| HTTPRoute    | HTTP routing rules      | `spec.parentRefs`, `spec.rules`           |
| ParentRef    | Link route to gateway   | `name`, `namespace` (optional)            |
| BackendRef   | Target service          | `name`, `port`, `weight`                  |

---

## Common Exam Traps

| Trap                         | Consequence            | Fix                                                                          |
| ---------------------------- | ---------------------- | ---------------------------------------------------------------------------- |
| No GatewayClass installed    | Gateway never programs | Check CRDs and controller                                                    |
| Wrong namespace in parentRef | Route not accepted     | Gateway and route can be different namespaces (set `namespace` in parentRef) |
| Missing allowedRoutes        | Gateway rejects routes | Set `allowedRoutes.namespaces.from: Same`                                    |
| Wrong port in backendRef     | 503 errors             | Must match service port                                                      |
| No service selector match    | No endpoints           | Ensure app labels match                                                      |

---

## Gateway API vs Ingress Comparison

| Feature                 | Ingress (old)          | Gateway API (v1.35)            |
| ----------------------- | ---------------------- | ------------------------------ |
| API group               | `networking.k8s.io/v1` | `gateway.networking.k8s.io/v1` |
| Cross-namespace routing | Limited                | Full support                   |
| Header matching         | Via annotations        | Native                         |
| Weighted routing        | Via annotations        | Native                         |
| Request/response mod    | Via annotations        | Native                         |
| TCP/UDP routing         | No                     | Yes                            |

---

## Pro Tips for CKA

1. **Check GatewayClass first** – Without it, nothing works
2. **Gateway status is critical** – `Programmed: True` means ready
3. **HTTPRoute parent status** – `Accepted: True` means gateway accepted it
4. **Use `Same` namespace restriction** – Simplifies exam scenarios
5. **Wait for Gateway to get address** – Takes 10-30 seconds
6. **Service must exist before HTTPRoute** – BackendRef validation happens
7. **Debug with describe** – `kubectl describe gateway/httproute` shows conditions

---

## Troubleshooting

**Gateway stuck in Pending:**

```bash
kubectl describe gateway web-gateway -n exercise-15
# Check events for controller issues
```

**HTTPRoute not accepted:**

```bash
kubectl describe httproute web-route -n exercise-15
# Check parentRef conditions
```

**No GatewayClass:**

```bash
# Install a lightweight controller for exam practice
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/experimental-install.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/nginx-gateway-fabric/main/examples/standard-install.yaml
```

**Service not reachable:**

```bash
kubectl get endpoints web-svc -n exercise-15
# Should have pod IPs
```

---

## Clean Up

```bash
# Delete HTTPRoute
kubectl delete httproute web-route -n exercise-15

# Delete Gateway
kubectl delete gateway web-gateway -n exercise-15

# Delete service and deployment
kubectl delete svc web-svc -n exercise-15
kubectl delete deployment web -n exercise-15

# Delete namespace
kubectl delete namespace exercise-15

# (Optional) Remove Gateway API CRDs
kubectl delete crd gateways.gateway.networking.k8s.io
kubectl delete crd httproutes.gateway.networking.k8s.io
kubectl delete crd gatewayclasses.gateway.networking.k8s.io
```

---

**Total exam time for this task:** ~6-8 minutes

**Most likely exam scenario:** GatewayClass already exists. You need to create a Gateway, HTTPRoute, and backend service. Then verify the route is programmed and attached. Gateway API is replacing Ingress in modern clusters.
Great job getting the cluster bootstrapped! You're right - those additional components are essential for a proper learning environment. Here's a complete setup for all the missing pieces:

## Complete Add-ons Installation Script

Run these commands on your **master node** (`kubemaster`):

```bash
# Create a script to install all add-ons
cat << 'EOF' > ~/install-addons.sh
#!/bin/bash

echo "========================================="
echo "Installing Kubernetes Add-ons"
echo "========================================="

# 1. Install Local Path Provisioner (for dynamic storage)
echo "📦 Installing Local Path Provisioner..."
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml

# Wait for local-path-provisioner
kubectl wait --namespace local-path-storage \
  --for=condition=ready pod \
  --selector=app=local-path-provisioner \
  --timeout=60s

# Make local-path the default storage class
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

echo "✅ Local Path Provisioner installed"

# 2. Install MetalLB (for LoadBalancer services)
echo "🔄 Installing MetalLB..."

# Apply MetalLB manifest
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

# Wait for MetalLB pods
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=120s

# Get the network CIDR from your node (adjust based on your network)
# For Multipass, we'll use a typical range
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
NETWORK_PREFIX=$(echo $NODE_IP | cut -d'.' -f1-3)

# Create IPAddressPool configuration
cat << EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - ${NETWORK_PREFIX}.100-${NETWORK_PREFIX}.150
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
EOF

echo "✅ MetalLB installed with IP range ${NETWORK_PREFIX}.100-${NETWORK_PREFIX}.150"

# 3. Install NGINX Ingress Controller
echo "🌐 Installing NGINX Ingress Controller..."

# Install NGINX Ingress Controller (bare-metal version)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/baremetal/deploy.yaml

# Wait for ingress controller
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo "✅ NGINX Ingress Controller installed"

# 4. Install Gateway API
echo "🚪 Installing Gateway API..."
# Install Gateway API CRDs (using stable channel)
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/experimental-install.yaml

# Install Gateway API CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

echo "✅ Gateway API CRDs installed"

# 5. Install a simple Gateway implementation (using NGINX Gateway Fabric - optional but recommended)
echo "🔌 Installing NGINX Gateway Fabric (implementation for Gateway API)..."

kubectl apply -f https://raw.githubusercontent.com/nginxinc/nginx-gateway-fabric/v1.2.0/deploy/manifests.yaml

# Wait for NGINX Gateway Fabric
kubectl wait --namespace nginx-gateway \
  --for=condition=ready pod \
  --selector=app=nginx-gateway \
  --timeout=120s 2>/dev/null || echo "Note: NGINX Gateway Fabric may need more time or may not be available, that's OK"

echo "✅ Gateway components installed"

echo "========================================="
echo "✅ All add-ons installation completed!"
echo "========================================="

# Show summary
echo ""
echo "📊 Installation Summary:"
echo "------------------------"
echo "StorageClass:"
kubectl get storageclass
echo ""
echo "MetalLB pods:"
kubectl get pods -n metallb-system
echo ""
echo "Ingress Controller pods:"
kubectl get pods -n ingress-nginx
echo ""
echo "Gateway API CRDs:"
kubectl get crd | grep gateway.networking.k8s.io
echo ""

EOF

# Make the script executable and run it
chmod +x ~/install-addons.sh
~/install-addons.sh
```

## Verify Everything is Working

After installation, run this verification script:

```bash
cat << 'EOF' > ~/verify-addons.sh
#!/bin/bash

echo "🔍 Verifying Add-ons Installation"
echo "=================================="

# 1. Check StorageClass
echo "📀 StorageClass:"
kubectl get storageclass
echo ""

# 2. Test Local Path Provisioner
echo "💾 Testing Local Path Provisioner..."
cat << TEST | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
TEST

sleep 5
PVC_STATUS=$(kubectl get pvc test-pvc -o jsonpath='{.status.phase}')
if [ "$PVC_STATUS" = "Bound" ]; then
  echo "✅ PVC successfully bound to local-path storage"
else
  echo "⚠️  PVC status: $PVC_STATUS"
fi
kubectl delete pvc test-pvc --ignore-not-found
echo ""

# 3. Test MetalLB
echo "🌐 Testing MetalLB with a LoadBalancer service..."
cat << TEST | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: test-lb
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: test
TEST

sleep 10
LB_IP=$(kubectl get svc test-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -n "$LB_IP" ]; then
  echo "✅ LoadBalancer service assigned IP: $LB_IP"
else
  echo "⚠️  LoadBalancer IP not yet assigned (may take a moment)"
fi
kubectl delete svc test-lb --ignore-not-found
echo ""

# 4. Test Ingress
echo "🌍 Testing Ingress Controller..."
kubectl get pods -n ingress-nginx
echo ""

# 5. Check Gateway API
echo "🚪 Gateway API Resources:"
kubectl get crd | grep gateway.networking.k8s.io
echo ""

echo "=================================="
echo "✅ Verification complete!"
echo ""
echo "📝 Quick test commands you can run:"
echo "  - kubectl get all -A"
echo "  - kubectl get storageclass"
echo "  - kubectl get pods -n ingress-nginx"
echo "  - kubectl get pods -n metallb-system"
echo "  - kubectl get crd | grep gateway"

EOF

chmod +x ~/verify-addons.sh
~/verify-addons.sh
```

## Create a Test Application to Validate Everything

Here's a complete test application that exercises all components:

```bash
cat << 'EOF' > ~/test-all-addons.yaml
---
# Test PVC using local-path storage
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-storage-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
---
# Test application
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: test-storage
          mountPath: /usr/share/nginx/html
      volumes:
      - name: test-storage
        persistentVolumeClaim:
          claimName: test-storage-pvc
---
# Service (ClusterIP for internal)
apiVersion: v1
kind: Service
metadata:
  name: test-app-clusterip
spec:
  selector:
    app: test-app
  ports:
  - port: 80
    targetPort: 80
---
# LoadBalancer Service (tests MetalLB)
apiVersion: v1
kind: Service
metadata:
  name: test-app-loadbalancer
spec:
  type: LoadBalancer
  selector:
    app: test-app
  ports:
  - port: 80
    targetPort: 80
---
# Ingress (tests Ingress Controller)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: test-app.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: test-app-clusterip
            port:
              number: 80
---
# Gateway (tests Gateway API - optional)
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: test-gateway
spec:
  gatewayClassName: nginx  # Use appropriate class
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: Same
---
# HTTPRoute (tests Gateway API routing)
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: test-http-route
spec:
  parentRefs:
  - name: test-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: test-app-clusterip
      port: 80
EOF

# Apply the test
kubectl apply -f ~/test-all-addons.yaml

# Watch everything come up
echo "Watching all resources..."
kubectl get pvc,pods,svc,ingress -w
```

## Helpful Commands for Learning

```bash
# Create an alias for quick access
cat << 'EOF' >> ~/.bashrc

# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kgd='kubectl get deployments'
alias kgi='kubectl get ingress'
alias kgpvc='kubectl get pvc'
alias kgsc='kubectl get storageclass'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'

# Watch resources
alias kwp='kubectl get pods -w'
alias kws='kubectl get svc -w'

# Describe resources shortcuts
alias kdp='kubectl describe pod'
alias kds='kubectl describe svc'
alias kdn='kubectl describe node'

# Logs
alias kl='kubectl logs'
alias klf='kubectl logs -f'

# Context and namespace
alias kgctx='kubectl config get-contexts'
alias kns='kubectl config set-context --current --namespace'

echo "Aliases loaded!"
EOF

source ~/.bashrc
```

## Resource Usage Note

Since you're on an M1 Mac with limited resources (2CPUs, 4GB RAM per VM), be aware that:

1. **Local Path Provisioner**: Lightweight (~10MB RAM)
2. **MetalLB**: Lightweight (~20MB RAM total)
3. **NGINX Ingress Controller**: Moderate (~100-150MB RAM)
4. **Gateway API CRDs**: Just CRDs, minimal overhead

**Total add-ons memory usage**: ~200-250MB

If you experience performance issues:

- Consider using only Ingress OR Gateway API, not both
- Reduce the number of test replicas to 1
- Scale down ingress replicas: `kubectl scale -n ingress-nginx deployment ingress-nginx-controller --replicas=1`

## Quick Cleanup (if needed)

```bash
# To remove everything and start fresh
kubectl delete -f ~/test-all-addons.yaml
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/baremetal/deploy.yaml
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
kubectl delete -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
```

Now you have a complete Kubernetes learning environment with storage, load balancing, ingress, and Gateway API capabilities! 🎉
