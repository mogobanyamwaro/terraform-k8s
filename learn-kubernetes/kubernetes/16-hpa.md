Configure a Horizontal Pod Autoscaler to scale a deployment based on CPU usage. Also understand Vertical Pod Autoscaler for resource optimization. This requires the metrics-server to be installed in the cluster.

## Context: HPA vs VPA

## Context: HPA vs VPA

HPA (Horizontal Pod Autoscaler) scales the number of replicas based on metrics like CPU or memory. When CPU exceeds target, HPA creates more pods. When load drops, it removes pods.

VPA (Vertical Pod Autoscaler) adjusts the CPU and memory requests/limits for existing pods based on actual usage. If a pod requests 256Mi memory but only uses 64Mi, VPA recommends lowering the request. This doesn't scale replicas; it optimizes resource allocation to improve bin-packing and reduce waste.

The CKA focuses on HPA, but understanding VPA helps with cluster resource efficiency.

## Tasks (HPA)

1. Create a namespace called `exercise-16`
2. Verify the metrics-server is running in the cluster
3. Create a Deployment named `load-app` with:
  - Image: `registry.k8s.io/hpa-example` (or `nginx:1.27` with resource requests)
  - 1 replica
  - CPU request: 50m
  - CPU limit: 100m
4. Expose it with a ClusterIP Service named `load-svc` on port 80
5. Create an HPA targeting `load-app`:
  - Min replicas: 1
  - Max replicas: 5
  - Target CPU utilization: 50%
6. Generate load against the service and observe the HPA scaling up
7. Stop the load and observe the HPA scaling back down

---

Here's the **best way** to tackle Horizontal Pod Autoscaler on the CKA exam – this tests metrics-based auto-scaling.

---

## Part 1: HPA Setup

### 1. Create namespace

```bash
kubectl create namespace exercise-16
```

---

### 2. Verify metrics-server is running

**Check metrics-server pods:**

```bash
kubectl get pods -n kube-system | grep metrics-server
```

**Check if metrics API is available:**

```bash
kubectl get apiservice | grep metrics
```

**Test metrics collection:**

```bash
kubectl top nodes
```

**If metrics-server not running (exam should have it):**

```bash
kubectl get pods -n kube-system -l k8s-app=metrics-server
kubectl logs -n kube-system -l k8s-app=metrics-server
```

---

### 3. Create Deployment with resource requests/limits

**Using the hpa-example image (recommended for exam):**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: load-app
  namespace: exercise-16
spec:
  replicas: 1
  selector:
    matchLabels:
      app: load-app
  template:
    metadata:
      labels:
        app: load-app
    spec:
      containers:
      - name: load-app
        image: registry.k8s.io/hpa-example
        resources:
          requests:
            cpu: 50m
            memory: 50Mi
          limits:
            cpu: 100m
            memory: 100Mi
EOF
```

**Alternative with nginx (if hpa-example not available):**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: load-app
  namespace: exercise-16
spec:
  replicas: 1
  selector:
    matchLabels:
      app: load-app
  template:
    metadata:
      labels:
        app: load-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.28
        resources:
          requests:
            cpu: 50m
            memory: 50Mi
          limits:
            cpu: 100m
            memory: 100Mi
EOF
```

**Wait for deployment:**

```bash
kubectl wait --for=condition=available deployment/load-app -n exercise-16 --timeout=60s
```

---

### 4. Expose with ClusterIP Service

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: load-svc
  namespace: exercise-16
spec:
  selector:
    app: load-app
  ports:
  - port: 80
    targetPort: 80
EOF
```

---

### 5. Create HPA targeting load-app

```bash
cat <<EOF | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: load-app-hpa
  namespace: exercise-16
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: load-app
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
EOF
```

**Alternative using kubectl autoscale (simpler):**

```bash
kubectl autoscale deployment load-app -n exercise-16 \
  --cpu-percent=50% \
  --min=1 \
  --max=5
```

**Verify HPA creation:**

```bash
kubectl get hpa -n exercise-16
```

**Check HPA details:**

```bash
kubectl describe hpa load-app-hpa -n exercise-16
```

---

### 6. Generate load and observe scaling up

**First, check current replicas:**

```bash
kubectl get deployment load-app -n exercise-16
kubectl get pods -n exercise-16
```

**Get service IP or use port-forward:**

```bash
kubectl port-forward -n exercise-16 svc/load-svc 8080:80 &
```

**Generate load (run in separate terminal):**

```bash
# Continuous load generation
while true; do curl -s http://localhost:8080 > /dev/null; done
```

**Or using a load generator pod:**

```bash
kubectl run -n exercise-16 load-generator \
  --image=busybox:1.36 \
  --restart=Never \
  -- /bin/sh -c "while true; do wget -q -O- http://load-svc; done"
```

**Watch HPA status:**

```bash
kubectl get hpa -n exercise-16 --watch
```

**Watch pods scaling:**

```bash
kubectl get pods -n exercise-16 --watch
```

**Check HPA events:**

```bash
kubectl describe hpa load-app-hpa -n exercise-16
```

**Wait for scaling (may take 1-2 minutes):**

```bash
kubectl get deployment load-app -n exercise-16
```

**Expected:** Replicas increase from 1 to 2, 3, etc.

**Check current CPU usage:**

```bash
kubectl top pods -n exercise-16
```

---

### 7. Stop load and observe scaling down

**Stop the load generator:**

```bash
# If using curl loop, press Ctrl+C
# If using load generator pod:
kubectl delete pod load-generator -n exercise-16
```

**Stop port-forward:**

```bash
fg
# Press Ctrl+C
```

**Watch HPA scale down:**

```bash
kubectl get hpa -n exercise-16 --watch
```

**Expected:** After 5 minutes of low CPU, replicas scale back to 1

**Check current replicas:**

```bash
kubectl get deployment load-app -n exercise-16
```

---

## Quick Verification Commands

```bash
echo "=== Metrics Server ==="
kubectl top nodes
kubectl top pods -n exercise-16

echo -e "\n=== HPA Status ==="
kubectl get hpa -n exercise-16

echo -e "\n=== Current Replicas ==="
kubectl get deployment load-app -n exercise-16

echo -e "\n=== HPA Detailed ==="
kubectl describe hpa load-app-hpa -n exercise-16 | grep -A10 "Metrics:"

echo -e "\n=== Pod CPU Usage ==="
kubectl top pods -n exercise-16
```

---

## Part 2: Vertical Pod Autoscaler (Bonus for Understanding)

### Install VPA (if not present)

```bash
# Clone VPA repository
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler

# Deploy VPA
kubectl apply -f vertical-pod-autoscaler/deploy/
```

### Create VPA Recommendation

```bash
cat <<EOF | kubectl apply -f -
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: load-app-vpa
  namespace: exercise-16
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: load-app
  updatePolicy:
    updateMode: "Off"  # "Auto" to apply, "Off" for recommend only
  resourcePolicy:
    containerPolicies:
    - containerName: '*'
      minAllowed:
        cpu: 25m
        memory: 25Mi
      maxAllowed:
        cpu: 200m
        memory: 200Mi
EOF
```

**Check VPA recommendations:**

```bash
kubectl get vpa -n exercise-16
kubectl describe vpa load-app-vpa -n exercise-16
```

### VPA vs HPA Comparison Table


| Aspect        | HPA                 | VPA                               |
| ------------- | ------------------- | --------------------------------- |
| Scales        | Number of replicas  | CPU/memory requests/limits        |
| Target metric | CPU, memory, custom | Actual resource usage             |
| Operation     | Add/remove pods     | Adjust pod resource spec          |
| Pod restart   | No                  | Yes (when updateMode: Auto)       |
| Use case      | Variable traffic    | Steady but misconfigured requests |
| CKA focus     | Heavy               | Light (understand only)           |


---

## HPA with Multiple Metrics (v2)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: load-app-hpa
  namespace: exercise-16
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: load-app
  minReplicas: 1
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

---

## HPA Behavior Configuration (v2)

```yaml
spec:
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 60
      policies:
        - type: Percent
          value: 50
          periodSeconds: 30
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
```

---

## Exam Critical Notes


| Component           | Purpose                     | Key Fields                                      |
| ------------------- | --------------------------- | ----------------------------------------------- |
| metrics-server      | Provides CPU/memory metrics | Required for HPA                                |
| Resource requests   | Base for CPU calculation    | `requests.cpu`, `limits.cpu`                    |
| HPA target          | CPU utilization %           | `averageUtilization: 50`                        |
| Min replicas        | Lower bound                 | `minReplicas: 1`                                |
| Max replicas        | Upper bound                 | `maxReplicas: 5`                                |
| Scale stabilization | Prevents flapping           | `behavior.scaleDown.stabilizationWindowSeconds` |


---

## Common Exam Traps


| Trap                       | Consequence           | Fix                          |
| -------------------------- | --------------------- | ---------------------------- |
| No resource requests       | HPA can't measure CPU | Set `resources.requests.cpu` |
| metrics-server not running | HPA shows `<unknown>` | Check kube-system pods       |
| Too low target             | Premature scaling     | Use 50-80% typical           |
| Too high max replicas      | Resource exhaustion   | Set reasonable max           |
| No load generator          | HPA never scales      | Generate CPU load            |
| Checking too early         | HPA needs 30-60s      | Use `--watch`                |


---

## HPA Troubleshooting

**HPA shows **** for metrics:**

```bash
kubectl describe hpa load-app-hpa -n exercise-16
# Check if metrics-server is working
kubectl top pods -n exercise-16
```

**HPA not scaling:**

```bash
# Check current CPU
kubectl top pods -n exercise-16

# Check HPA events
kubectl describe hpa load-app-hpa -n exercise-16

# Check if metrics are being reported
kubectl get hpa -n exercise-16 -o yaml | grep -A5 status
```

**Deployment not ready:**

```bash
kubectl get deployment load-app -n exercise-16
kubectl get pods -n exercise-16
```

---

## Pro Tips for CKA

1. **Always set resource requests** – HPA requires them
2. **Wait 30-60 seconds** – HPA doesn't scale instantly
3. **Use `kubectl top` first** – Verify metrics work before creating HPA
4. **Watch with `--watch`** – See scaling in real-time
5. **Scale down takes longer** – Default 5 minute stabilization window
6. **hpa-example image is best** – Specifically designed for load testing
7. **Check HPA conditions** – Shows why it's not scaling

---

## Complete Test Script

```bash
#!/bin/bash
NAMESPACE=exercise-16

# Setup
kubectl create namespace $NAMESPACE

# Create deployment with resource requests
kubectl create deployment load-app -n $NAMESPACE \
  --image=registry.k8s.io/hpa-example \
  --requests='cpu=50m,memory=50Mi' \
  --limits='cpu=100m,memory=100Mi'

kubectl expose deployment load-app -n $NAMESPACE --port=80 --target-port=80

# Create HPA
kubectl autoscale deployment load-app -n $NAMESPACE --cpu-percent=50 --min=1 --max=5

# Wait for HPA to be ready
sleep 10

# Generate load
kubectl run -n $NAMESPACE load-gen --image=busybox:1.36 --restart=Never -- \
  /bin/sh -c "while true; do wget -q -O- http://load-app; done" &

# Watch scaling
kubectl get hpa -n $NAMESPACE --watch

# Cleanup (Ctrl+C then run)
# kubectl delete namespace $NAMESPACE
```

---

**Total exam time for this task:** ~6-8 minutes

**Most likely exam scenario:** Create an HPA for an existing deployment, verify it works by generating load, and understand why HPA shows `<unknown>` (missing metrics-server or resource requests).