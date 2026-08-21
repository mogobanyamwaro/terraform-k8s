Update TLS configuration to support additional protocol versions for backward compatibility. Tests ConfigMap modification and service restart.

## Tasks

1. A service currently supports only TLS 1.3
2. Add support for TLS 1.2 (make both available)
3. Update configuration file or ConfigMap:
   - Add TLS 1.2 to supported protocols
   - Keep TLS 1.3 enabled
4. ConfigMap is mounted in Deployment as env var or config file
5. Restart Deployment to apply changes
6. Verify service accepts TLS 1.2 connections:
   - Use `openssl s_client -connect <service> -tls1_2`
   - Or curl with explicit TLS 1.2
7. Verify TLS 1.3 still works

## Key Learning

- TLS configuration often in ConfigMaps
- Adding vs replacing: exam specifies "ADD support" (don't remove existing)
- Service restart may be needed after config change
- TLS negotiation must support minimum version
- Testing TLS versions requires understanding openssl commands

---

Here's the **best way** to update TLS configuration to support additional protocol versions on the CKA exam.

---

## Understanding TLS Configuration

| TLS Version | Status After Task | Why                    |
| ----------- | ----------------- | ---------------------- |
| TLS 1.3     | Enabled (keep)    | Current standard       |
| TLS 1.2     | ADD support       | Backward compatibility |

**Typical scenario:** Ingress controller, API gateway, or application ConfigMap controls TLS versions.

A good way to learn this on k3d is to create a small HTTPS application and then change the TLS configuration so that older clients can connect.

The core idea is:

1. App starts with only modern TLS (TLS 1.3).
2. Some older clients fail.
3. Update configuration to allow TLS 1.2 as well.
4. Restart/reload the service.
5. Verify older clients now connect.

This is exactly the type of operation platform engineers perform in production.

---

# Lab Architecture

```text
ConfigMap
    │
    ▼
NGINX Deployment
    │
    ▼
HTTPS Service
```

The TLS settings live in a ConfigMap.

When you update the ConfigMap:

```bash
kubectl apply -f configmap.yaml
```

the running pod does NOT automatically reload the new configuration.

You'll need to restart the Deployment:

```bash
kubectl rollout restart deployment nginx-tls
```

This is the key lesson of the exercise.

---

# Step 1: Create Namespace

```bash
kubectl create namespace tls-lab
```

---

# Step 2: Generate Self-Signed Certificate

Create a cert locally:

```bash
openssl req -x509 \
  -nodes \
  -days 365 \
  -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=localhost"
```

Create secret:

```bash
kubectl create secret tls nginx-tls-secret \
  --cert=tls.crt \
  --key=tls.key \
  -n tls-lab
```

Verify:

```bash
kubectl get secret -n tls-lab
```

---

# Step 3: Create TLS ConfigMap

Initially support only TLS 1.3.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: tls-lab
data:
  nginx.conf: |
    events {}

    http {
      server {
        listen 443 ssl;

        ssl_certificate /etc/nginx/tls/tls.crt;
        ssl_certificate_key /etc/nginx/tls/tls.key;

        ssl_protocols TLSv1.3;

        location / {
          return 200 "TLS Test Server\n";
        }
      }
    }
```

Apply:

```bash
kubectl apply -f configmap.yaml
```

---

# Step 4: Create Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-tls
  namespace: tls-lab
spec:
  replicas: 1

  selector:
    matchLabels:
      app: nginx-tls

  template:
    metadata:
      labels:
        app: nginx-tls

    spec:
      containers:
      - name: nginx
        image: nginx:latest

        ports:
        - containerPort: 443

        volumeMounts:
        - name: config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf

        - name: tls
          mountPath: /etc/nginx/tls

      volumes:
      - name: config
        configMap:
          name: nginx-config

      - name: tls
        secret:
          secretName: nginx-tls-secret
```

Apply:

```bash
kubectl apply -f deployment.yaml
```

---

# Step 5: Create Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-tls
  namespace: tls-lab
spec:
  selector:
    app: nginx-tls

  ports:
  - port: 443
    targetPort: 443
```

Apply:

```bash
kubectl apply -f service.yaml
```

---

# Step 6: Port Forward

```bash
kubectl port-forward svc/nginx-tls 8443:443 -n tls-lab
```

---

# Step 7: Test TLS 1.3

Open another terminal:

```bash
curl -k https://localhost:8443
```

Expected:

```text
TLS Test Server
```

---

# Step 8: Simulate Older Client

Force TLS 1.2:

```bash
curl -k --tlsv1.2 https://localhost:8443
```

Expected:

```text
curl: (35) SSL connect error
```

because server only supports:

```nginx
ssl_protocols TLSv1.3;
```

---

# Step 9: Update ConfigMap

Edit:

```bash
kubectl edit configmap nginx-config -n tls-lab
```

Change:

```nginx
ssl_protocols TLSv1.3;
```

to:

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
```

Save.

Verify ConfigMap changed:

```bash
kubectl get cm nginx-config -n tls-lab -o yaml
```

---

# Step 10: Observe Nothing Changed

Try again:

```bash
curl -k --tlsv1.2 https://localhost:8443
```

Still fails.

Why?

Because NGINX loaded the config only when the container started.

The pod is still running with the old config.

---

# Step 11: Restart Service

Restart Deployment:

```bash
kubectl rollout restart deployment nginx-tls -n tls-lab
```

Watch:

```bash
kubectl rollout status deployment nginx-tls -n tls-lab
```

---

# Step 12: Verify Backward Compatibility

Now test TLS 1.2:

```bash
curl -k --tlsv1.2 https://localhost:8443
```

Expected:

```text
TLS Test Server
```

TLS 1.3 should still work:

```bash
curl -k --tlsv1.3 https://localhost:8443
```

Expected:

```text
TLS Test Server
```

---

# What You Learned

This exercise teaches several Kubernetes skills at once:

* Using a ConfigMap for application configuration
* Mounting ConfigMaps into Pods
* Using TLS certificates stored in Secrets
* Updating TLS protocol versions
* Understanding backward compatibility
* Verifying client connectivity
* Rolling restart of Deployments
* Confirming configuration changes took effect

This mirrors a common real-world task: "Enable TLS 1.2 support for legacy clients without breaking modern clients."

