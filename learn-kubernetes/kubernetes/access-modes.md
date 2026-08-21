The **access mode** tells Kubernetes **how a PersistentVolume can be mounted by Pods**.

| Access Mode                 | Meaning                                                 | Can multiple Pods use it?                             | Typical use                                         |
| --------------------------- | ------------------------------------------------------- | ----------------------------------------------------- | --------------------------------------------------- |
| **ReadWriteOnce (RWO)**     | One node can mount the volume for reading and writing   | ✅ Multiple Pods **only if they're on the same node** | Most common (AWS EBS, Azure Disk)                   |
| **ReadOnlyMany (ROX)**      | Many nodes can mount the volume, but read-only          | ✅ Yes (read only)                                    | Shared configuration or static data                 |
| **ReadWriteMany (RWX)**     | Many nodes can mount the volume for reading and writing | ✅ Yes                                                | Shared file storage (NFS, CephFS, Azure Files, EFS) |
| **ReadWriteOncePod (RWOP)** | Only one Pod in the entire cluster can mount it         | ❌ Exactly one Pod                                    | Databases needing exclusive access                  |

### Visual examples

**RWO (ReadWriteOnce)**

```text
Node A
 ├── Pod A ─┐
 └── Pod B ─┘
        │
       PV

Node B
 └── Pod C ✖ (cannot mount the same volume)
```

---

**ROX (ReadOnlyMany)**

```text
Pod A (read)
      │
Pod B (read)
      │
Pod C (read)
      │
      PV
```

---

**RWX (ReadWriteMany)**

```text
Pod A (read/write)
        │
Pod B (read/write)
        │
Pod C (read/write)
        │
        PV
```

---

**RWOP (ReadWriteOncePod)**

```text
Pod A ✓
  │
 PV

Pod B ✖
Pod C ✖
```

### Important note

The access mode is **not a guarantee by Kubernetes alone**. It depends on whether the **storage backend** supports it.

For example:

- **AWS EBS** → RWO, RWOP
- **Azure Disk** → RWO, RWOP
- **NFS** → RWX, ROX
- **Amazon EFS** → RWX
- **CephFS** → RWX

### Memory trick

- **RWO** = **One node writes**
- **ROX** = **Many read**
- **RWX** = **Many write**
- **RWOP** = **One Pod only**

---

The easiest way to remember them is:

| Resource                        | Purpose                                     | Created by                   | Think of it as...                        |
| ------------------------------- | ------------------------------------------- | ---------------------------- | ---------------------------------------- |
| **StorageClass (SC)**           | Defines **how** storage should be created   | Cluster admin                | A storage template or blueprint          |
| **PersistentVolume (PV)**       | The actual storage available to the cluster | Admin or dynamically created | A hard disk                              |
| **PersistentVolumeClaim (PVC)** | A request for storage from a Pod            | Application/user             | A request or reservation for a hard disk |

### Relationship

```
Pod
 │
 ▼
PVC (I need 10Gi)
 │
 ▼
PV (Here is a 10Gi volume)
 │
 ▼
Storage Backend
(AWS EBS, Azure Disk, NFS, Ceph, local disk, etc.)
```

If **dynamic provisioning** is enabled:

```
Pod
 │
 ▼
PVC
 │
 ▼
StorageClass
 │
 ▼
Automatically creates a PV
 │
 ▼
Storage Backend
```

### Quick example

**1. StorageClass** – tells Kubernetes how to create storage.

```yaml
kind: StorageClass
provisioner: ebs.csi.aws.com
```

> "Whenever someone needs storage, create an AWS EBS disk."

---

**2. PVC** – application requests storage.

```yaml
kind: PersistentVolumeClaim
spec:
  storageClassName: standard
  resources:
    requests:
      storage: 10Gi
```

> "I need a 10Gi volume."

---

**3. PV** – actual volume.

```yaml
kind: PersistentVolume
spec:
  capacity:
    storage: 10Gi
```

> "Here is the 10Gi disk."

---

### One-line memory trick

- **StorageClass** = **How to create storage**
- **PersistentVolume (PV)** = **The storage itself**
- **PersistentVolumeClaim (PVC)** = **A request to use storage**

### Real-world analogy

- **StorageClass** = Car model/configuration (Toyota Hilux, automatic, diesel)
- **PV** = The actual car
- **PVC** = Your booking/request for a car

When you book a Hilux (PVC), the rental company uses the car model specification (StorageClass) to assign or procure an actual car (PV) for you.

In modern Kubernetes clusters, you typically create only **PVCs**. The **StorageClass** automatically provisions and binds a **PV**, so you rarely need to create PVs manually.

---

Here's the summary:

| Command                     | What it does                                              | Existing Pods                                             | New Pods                 |
| --------------------------- | --------------------------------------------------------- | --------------------------------------------------------- | ------------------------ |
| **`kubectl cordon <node>`** | Marks a node as **unschedulable**                         | ✅ Keep running                                           | ❌ No new Pods scheduled |
| **`kubectl drain <node>`**  | Marks the node unschedulable **and evicts existing Pods** | ❌ Evicted (except DaemonSets/static Pods unless handled) | ❌ No new Pods scheduled |

### Visual

Before:

```text
Node
├── Pod A
├── Pod B
└── Pod C
```

**After `cordon`:**

```text
Node (Unschedulable)
├── Pod A ✓
├── Pod B ✓
└── Pod C ✓

New Pod ✖
```

Pods continue running, but no new Pods are placed on the node.

---

**After `drain`:**

```text
Node (Unschedulable)
└── (No application Pods)

Pods A, B, C
        ↓
Rescheduled to other nodes
```

The node is emptied of workload Pods so it can be safely maintained.

### Typical use

- **`cordon`** → Prevent new workloads from being scheduled while letting current workloads finish naturally.
- **`drain`** → Before maintenance, upgrades, or rebooting a node. It safely moves workloads to other nodes.

### Memory trick

- **Cordon** = **Close the door** (no one new comes in).
- **Drain** = **Empty the room** (everyone leaves, and no one new enters).

> Note: `drain` automatically performs a `cordon` as part of its operation. To allow scheduling on the node again afterward, use:
>
> ```bash
> kubectl uncordon <node>
> ```

---

## 1. CRD (Custom Resource Definition)

A **CRD** lets you **extend Kubernetes with your own resource types**.

Think of it as:

> **CRD = Create your own Kubernetes object.**

Example:

Normally Kubernetes has:

- Pod
- Deployment
- Service

With a CRD, you can create something like:

```yaml
kind: Database
kind: Backup
kind: Certificate
kind: Gateway
```

These aren't built into Kubernetes—they're added by installing a CRD.

**Examples of projects that use CRDs:**

- Cert-Manager → `Certificate`
- ArgoCD → `Application`
- Prometheus Operator → `ServiceMonitor`
- Gateway API → `Gateway`, `HTTPRoute`

**Memory trick:**

> **CRD = Add new resource types to Kubernetes.**

---

## 2. Gateway API

Gateway API is a **modern replacement/improvement over Ingress** for managing network traffic into a cluster.

Think of it as:

> **Gateway API = More powerful and flexible Ingress.**

Instead of one Ingress resource, it separates responsibilities:

```
GatewayClass
      │
      ▼
Gateway
      │
      ▼
HTTPRoute
      │
      ▼
Service
      │
      ▼
Pods
```

### Components

- **GatewayClass** → Defines which Gateway controller to use (NGINX, Envoy, Istio, etc.).
- **Gateway** → Listens for incoming traffic (ports, listeners, TLS).
- **HTTPRoute** → Defines routing rules (hostnames, paths, headers) to Services.

### Example flow

```
Internet
    │
    ▼
Gateway
    │
HTTPRoute
    │
Service
    │
Pods
```

---

## Quick comparison

| Feature     | CRD                                            | Gateway API                                |
| ----------- | ---------------------------------------------- | ------------------------------------------ |
| What is it? | Mechanism to add new Kubernetes resource types | A set of CRDs for advanced traffic routing |
| Purpose     | Extend Kubernetes                              | Manage ingress/network traffic             |
| Example     | `Certificate`, `Application`, `Gateway`        | `Gateway`, `GatewayClass`, `HTTPRoute`     |

### Memory trick

- **CRD** = **Create new Kubernetes resource types.**
- **Gateway API** = **Use those resources to route traffic into your cluster.**

---

Exactly. A **ConfigMap itself is not inherently a file**. Kubernetes knows whether to expose it as a file or environment variable based on **how you reference it in the Pod/Deployment**.

For example, suppose you have:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    server {
      listen 8080;
    }
```

Here `nginx.conf` is simply a **key**, and the nginx configuration is its value.

If your Deployment does this:

```yaml
spec:
  containers:
    - name: nginx
      image: nginx
      volumeMounts:
        - name: config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf

  volumes:
    - name: config
      configMap:
        name: nginx-config
```

Kubernetes sees:

```text
ConfigMap: nginx-config
        │
        │ data
        ▼
  nginx.conf: "server {...}"
        │
        │ volume + volumeMount
        ▼
Container filesystem
        │
        ▼
/etc/nginx/nginx.conf
```

So this part is what tells Kubernetes **"mount this ConfigMap as files"**:

```yaml
volumes:
  - name: config
    configMap:
      name: nginx-config
```

And this tells Kubernetes **where those files should appear inside the container**:

```yaml
volumeMounts:
  - name: config
    mountPath: /etc/nginx/nginx.conf
    subPath: nginx.conf
```

`subPath` specifically says:

> From the ConfigMap volume, take the `nginx.conf` key/file and mount only that file here.

Without `subPath`, you normally mount the ConfigMap as a **directory**:

```yaml
volumeMounts:
  - name: config
    mountPath: /etc/config
```

Then every ConfigMap key becomes a file:

```text
ConfigMap

data:
  database.conf: "..."
  app.conf:      "..."
  nginx.conf:    "..."

             ↓ volume mount

/etc/config/
├── database.conf
├── app.conf
└── nginx.conf
```

Alternatively, if you write:

```yaml
envFrom:
  - configMapRef:
      name: nginx-config
```

you're telling Kubernetes:

> Use the ConfigMap as **environment variables**, not files.

So for CKA, remember the distinction:

```text
ConfigMap
   │
   ├── env / envFrom
   │       ↓
   │   Environment variables
   │
   └── volumes + volumeMounts
           ↓
       Files in container
```

**The ConfigMap doesn't decide. The Deployment/Pod decides how the ConfigMap is consumed.**

---

In Kubernetes, **probes are health checks that Kubernetes performs on your container**.

There are **3 main probes**:

| Probe               | Simple question Kubernetes asks        | If it fails                                                       |
| ------------------- | -------------------------------------- | ----------------------------------------------------------------- |
| **Liveness Probe**  | "Is the app still alive?"              | Kubernetes **restarts the container**                             |
| **Readiness Probe** | "Is the app ready to receive traffic?" | Kubernetes **stops sending traffic** to the Pod                   |
| **Startup Probe**   | "Has the app finished starting?"       | Kubernetes waits; if it keeps failing, **restarts the container** |

### 1. Liveness Probe

Think:

> **Are you alive?**

Your application might be running but stuck or frozen.

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
```

If `/health` keeps failing:

**Kubernetes → restarts the container.**

---

### 2. Readiness Probe

Think:

> **Are you ready to work?**

Maybe your application is alive, but the database connection is down, so it shouldn't receive requests.

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
```

If it fails:

**Kubernetes → Pod stays running → but Service stops sending traffic to it.**

When it succeeds again, traffic resumes.

---

### 3. Startup Probe

Think:

> **Have you finished starting yet?**

Useful for applications that take a long time to start.

```yaml
startupProbe:
  httpGet:
    path: /health
    port: 8080
```

While the startup probe hasn't succeeded, Kubernetes **doesn't run the liveness/readiness probes yet**.

### Easy way to remember

```text
Startup   → Have you started?
Readiness → Can you receive traffic?
Liveness  → Are you still alive?
```

And the most important distinction:

```text
Readiness fails → REMOVE FROM TRAFFIC
Liveness fails  → RESTART CONTAINER
Startup fails   → RESTART if app never starts
```

---
Gateway API and MetalLB solve **different problems**, but they often work together in bare-metal Kubernetes clusters.

Think of it as this:

* **MetalLB** = Gives your Kubernetes cluster a real IP address.
* **Gateway API** = Decides what to do with traffic that arrives on that IP address.

Here's the flow:

```text
Internet / LAN
       |
       |
  192.168.1.100   <--- MetalLB assigns this IP
       |
+--------------------+
| Gateway Controller |  (NGINX Gateway, Envoy Gateway, Traefik, etc.)
+--------------------+
       |
 Gateway API Rules
 (Gateway, HTTPRoute)
       |
+--------------+-------------+
|              |             |
Service A   Service B    Service C
```

---

# 1. What MetalLB does

Normally, in cloud providers:

```yaml
kind: Service
spec:
  type: LoadBalancer
```

AWS automatically creates

* Elastic IP
* Network Load Balancer
* Public IP

But on:

* kubeadm
* k3s
* k3d
* MicroK8s
* Bare metal

there is **no cloud provider**.

So the Service stays:

```
EXTERNAL-IP <pending>
```

MetalLB fixes this.

Example:

```yaml
kind: Service
spec:
  type: LoadBalancer
```

Without MetalLB

```
EXTERNAL-IP
<pending>
```

With MetalLB

```
EXTERNAL-IP
192.168.64.150
```

Now traffic can reach your cluster.

---

# 2. What Gateway API does

Gateway API does **not** assign IP addresses.

Instead it answers:

> "Someone reached 192.168.64.150. Which application should receive the request?"

For example

```
http://shop.company.com
```

goes to

```
shop-service
```

while

```
http://api.company.com
```

goes to

```
api-service
```

---

# 3. Why they work together

Imagine you deploy an NGINX Gateway Controller.

It creates a Service:

```yaml
kind: Service
type: LoadBalancer
```

MetalLB sees this and assigns

```
192.168.64.150
```

Now clients can connect.

Gateway API then routes requests.

```
192.168.64.150
          |
          |
Gateway Controller
          |
     HTTPRoute
          |
      Backend Service
```

---

# Example

Suppose you have

```
Frontend

Backend

Monitoring
```

Gateway API

```yaml
Gateway
```

listens on

```
80
443
```

HTTPRoutes

```
frontend.company.com
        |
        v
frontend-service
```

```
api.company.com
       |
       v
backend-service
```

```
grafana.company.com
        |
        v
grafana-service
```

MetalLB provides

```
192.168.64.150
```

DNS

```
frontend.company.com -> 192.168.64.150

api.company.com -> 192.168.64.150

grafana.company.com -> 192.168.64.150
```

Gateway API inspects the `Host` header and forwards to the correct service.

---

# 4. Without MetalLB

Gateway API still exists.

But

```
kubectl get svc
```

shows

```
gateway-service
LoadBalancer
EXTERNAL-IP <pending>
```

Nobody outside the cluster can access it.

Gateway rules are configured, but there is no external IP to receive traffic.

---

# 5. Without Gateway API

MetalLB still assigns

```
192.168.64.150
```

But then all traffic simply lands on the Service.

You lose advanced routing such as:

* host-based routing
* path-based routing
* traffic splitting
* canary deployments
* reusable routing policies

---

# 6. How they fit together

```
Client
   |
   |
192.168.64.150
   |
MetalLB
(assigns IP)
   |
LoadBalancer Service
   |
NGINX Gateway Controller
   |
Gateway
   |
HTTPRoute
   |
Service
   |
Pods
```

---

# Real cloud example (AWS)

On AWS you normally **don't use MetalLB** because AWS already provides the LoadBalancer functionality.

```
Internet
      |
AWS Network Load Balancer
      |
Gateway Controller
      |
Gateway API
      |
Services
      |
Pods
```

The equivalent mapping is:

| Bare Metal         | AWS                                                                               |
| ------------------ | --------------------------------------------------------------------------------- |
| MetalLB            | AWS Load Balancer (created by the cloud provider or AWS Load Balancer Controller) |
| Gateway API        | Gateway API (same concepts)                                                       |
| Gateway Controller | NGINX Gateway, Envoy Gateway, Kong, Traefik, etc.                                 |
| HTTPRoute          | HTTPRoute                                                                         |
| Service            | Service                                                                           |
| Pods               | Pods                                                                              |

---

## Simple analogy

Imagine a shopping mall:

* **MetalLB** is the **street address** of the mall. Without an address, no one can find the building.
* **Gateway API** is the **directory at the entrance** that tells visitors where to go ("Shop A on Floor 1", "Food Court on Floor 2", etc.).
* **Services** are the individual shops.
* **Pods** are the staff working inside each shop.

The address gets visitors to the building, and the directory gets them to the correct destination. In the same way, **MetalLB makes your cluster reachable**, while **Gateway API directs incoming traffic to the right Kubernetes Services**.

