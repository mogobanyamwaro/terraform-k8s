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
