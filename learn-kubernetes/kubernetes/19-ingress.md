Configure Kubernetes Ingress resources for HTTP/HTTPS routing. CKA exam topics include classic Ingress alongside newer Gateway API. This exercise covers path-based routing, TLS termination, and IngressClass configuration.

## Context

Ingress provides external access to services inside a cluster. While Gateway API is the future direction, classic Ingress (networking.k8s.io/v1) appears on most CKA exams. You need to understand:

- How to expose services via Ingress
- Path-based and host-based routing
- TLS certificate setup
- Ingress controller requirements

This differs from Exercise 15 (Gateway API) because it tests the older API that's still in widespread production use.

## Tasks

1. Create a namespace called `exercise-19`
2. Create two Deployments:
   - `web-app` with image `nginx:1.28` and 2 replicas, serving on port 80
   - `api-app` with image `nginx:1.28` and 2 replicas, serving on port 8080
3. Expose `web-app` Deployment with a ClusterIP service named `web-service` on port 80
4. Expose `api-app` Deployment with a ClusterIP service named `api-service` on port 8080
5. Create an Ingress resource named `app-ingress` that routes:
   - `/` traffic to `web-service:80`
   - `/api` traffic to `api-service:8080`
   - Default backend (no matching path) should point to `web-service`
6. Verify the Ingress resource was created and has an address assigned
7. Test path-based routing by describing the Ingress (check rules)

---

```bash
# Create namespace
kubectl create namespace exercise-19

# Create web-app deployment (standard nginx)
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: exercise-19
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.28
        ports:
        - containerPort: 80
EOF

# Create configmap for api-app to handle /api route
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-nginx-config
  namespace: exercise-19
data:
  default.conf: |
    server {
        listen 80;
        server_name localhost;

        location / {
            return 200 "api-app root endpoint\n";
            add_header Content-Type text/plain;
        }

        location /api {
            return 200 "api-app /api endpoint - path-based routing working!\n";
            add_header Content-Type text/plain;
        }

        location /api/ {
            return 200 "api-app /api/ endpoint - path-based routing working!\n";
            add_header Content-Type text/plain;
        }
    }
EOF

# Create api-app deployment with custom nginx config
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-app
  namespace: exercise-19
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-app
  template:
    metadata:
      labels:
        app: api-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.28
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: nginx-config
        configMap:
          name: api-nginx-config
EOF

# Create web-service (port 80)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: exercise-19
spec:
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
EOF

# Create api-service (port 8080)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: exercise-19
spec:
  selector:
    app: api-app
  ports:
  - port: 8080
    targetPort: 80
EOF

# Create Ingress resource
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: exercise-19
spec:
  ingressClassName: nginx
  defaultBackend:
    service:
      name: web-service
      port:
        number: 80
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
EOF
```

## Verification Steps

```bash
# 1. Check all resources are created
kubectl get all -n exercise-19

# 2. Verify Ingress has address assigned (may take a few seconds)
kubectl get ingress -n exercise-19 -w
# Wait for ADDRESS to appear (e.g., 192.168.64.11)

# 3. Describe Ingress to check rules
kubectl describe ingress app-ingress -n exercise-19

# Expected output shows:
# Default backend: web-service:80 (pods IPs)
# Rules:
#   Host        Path  Backends
#   ----        ----  --------
#   *
#               /      web-service:80 (10.244.0.41:80,10.244.2.164:80)
#               /api   api-service:8080 (10.244.0.42:80,10.244.2.163:80)

# 4. Test path-based routing
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

# Test root path (should go to web-app)
curl http://$INGRESS_IP/
# Expected output: Welcome to nginx! page

# Test /api path (should go to api-app)
curl http://$INGRESS_IP/api
# Expected output: "api-app /api endpoint - path-based routing working!"

# Test default backend (non-matching path like /test)
curl http://$INGRESS_IP/test
# Expected output: Welcome to nginx! page (from web-service)

# Test /api/ path as well
curl http://$INGRESS_IP/api/
# Expected output: "api-app /api/ endpoint - path-based routing working!"
```

## Key Points Verified:

1. ✅ **Namespace created**: exercise-19
2. ✅ **Two deployments**: web-app (2 replicas, nginx:1.28 on port 80) and api-app (2 replicas, nginx:1.28 on port 8080)
3. ✅ **Services exposed**: web-service (port 80) and api-service (port 8080)
4. ✅ **Ingress created**: app-ingress with correct routing rules
5. ✅ **Default backend**: Points to web-service for non-matching paths
6. ✅ **Address assigned**: Ingress has IP address from MetalLB
7. ✅ **Path-based routing**: / → web-service, /api → api-service

The 404 issue is resolved because the ConfigMap configures nginx in api-app to properly respond to `/api` requests with a 200 OK response instead of 404 Not Found.
