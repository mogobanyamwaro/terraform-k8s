# 08. Harden API Server Authentication And Admission

**Domain:** Cluster Hardening

## Question

On a kubeadm control plane, harden the API server by disabling anonymous authentication, ensuring `Node,RBAC` authorization, and enabling the `NodeRestriction` admission plugin.

## Answer

Open the static pod manifest:

```bash
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

Under the `command` list, add or update:

```yaml
- --anonymous-auth=false
- --authorization-mode=Node,RBAC
- --enable-admission-plugins=NodeRestriction
```

If `--enable-admission-plugins` already exists, append `NodeRestriction` to the comma-separated list.

Example:

```yaml
- --enable-admission-plugins=NodeRestriction,PodSecurity
```

If `--authorization-mode` already exists, make sure it includes both:

```yaml
- --authorization-mode=Node,RBAC
```

## Verify

Wait for API server restart:

```bash
kubectl get nodes
kubectl -n kube-system get pods -l component=kube-apiserver
```

Check the running manifest:

```bash
kubectl -n kube-system get pod -l component=kube-apiserver -o yaml | grep -E 'anonymous-auth|authorization-mode|enable-admission-plugins'
```

Test authorization:

```bash
kubectl auth can-i get pods --as=system:anonymous
```

Expected: `no`.

## Rollback If Needed

If the API server does not come back:

```bash
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml.bak /etc/kubernetes/manifests/kube-apiserver.yaml
sudo crictl ps | grep kube-apiserver
```

## Exam tips

- `Node` authorization limits kubelet API access to objects related to its node.
- `RBAC` is the standard user/application authorization mode.
- `NodeRestriction` prevents kubelets from modifying unrelated node and pod objects.
- Always preserve existing required admission plugins when editing the flag.

Yes. The easiest way to understand these three is to separate **authentication**, **authorization**, and **admission control**.

Think of the Kubernetes API Server like a security gate:

```text
Someone → API Server → "Who are you?" → "Are you allowed?" → "Is this request acceptable?"
                         Authentication    Authorization       Admission
```

Your question is specifically about **Node**, **RBAC**, and **NodeRestriction**.

---

## 1. `Node` authorization — "What is this node allowed to access?"

Imagine you have:

```text
Worker Node 1
   |
   +--- Pod A
   +--- Pod B
```

The kubelet on Worker Node 1 needs to communicate with the API Server.

For example, the kubelet may ask:

> "Give me the information about the Pods that are running on me."

The API Server receives the request:

```text
Kubelet on Node 1
       |
       | "Give me Pod A information"
       ↓
   API Server
       |
       ↓
  Node authorizer
       |
       | "This is Node 1"
       |
       | "Pod A is assigned to Node 1"
       ↓
      ALLOW
```

The **Node authorizer** is specifically designed for Kubernetes nodes/kubelets.

It prevents a kubelet on Node 1 from simply accessing arbitrary resources belonging to Node 2.

So:

```text
Node 1 → its own assigned Pods/resources → ✅
Node 1 → arbitrary Node 2 resources      → ❌
```

That's the purpose of the `Node` authorization mode.

---

# 2. RBAC — "What is this user/service account allowed to do?"

RBAC stands for:

**Role-Based Access Control**

This is about giving permissions to identities.

Imagine you have:

```text
developer
```

and you want that developer to be able to:

```text
get Pods
list Pods
```

but **not delete Pods**.

You create a Role:

```yaml
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
```

Then bind that Role to the developer.

Now:

```text
Developer
    |
    | GET pods
    ↓
API Server
    |
    ↓
RBAC
    |
    | "Developer can get Pods"
    ↓
   ✅ ALLOW
```

But:

```text
Developer
    |
    | DELETE pod
    ↓
API Server
    |
    ↓
RBAC
    |
    | "Developer cannot delete Pods"
    ↓
   ❌ DENY
```

So **RBAC answers:**

> "What is this identity allowed to do?"

---

# 3. Why do we use `Node,RBAC` together?

This is where it becomes interesting.

The API Server can have:

```text
--authorization-mode=Node,RBAC
```

Meaning Kubernetes uses **both authorization mechanisms**.

Think:

```text
                   API Server
                       |
              "Who is requesting?"
                       |
                       ↓
              +----------------+
              | Authorization  |
              +----------------+
                 /          \
                /            \
           Node authorizer   RBAC
               |              |
          kubelets/nodes    Users,
                            ServiceAccounts,
                            etc.
```

### Example

A kubelet says:

> "I need information about Pod X."

The **Node authorizer** handles the node-specific authorization.

A developer says:

> "I want to delete Pod X."

**RBAC** handles that permission.

So:

```text
Kubelet → Node authorization
User → RBAC
ServiceAccount → RBAC
```

That's the simple mental model.

---

# 4. Now what is `NodeRestriction`?

This one is different.

**NodeRestriction is an admission plugin.**

It's not another authorization mechanism.

Remember:

```text
Authentication
      ↓
Authorization
      ↓
Admission
      ↓
Object stored
```

NodeRestriction operates at the **admission** stage.

### Example

Imagine a worker node identifies itself as:

```text
system:node:worker-01
```

The kubelet on `worker-01` is allowed to modify certain information about itself and its Pods.

But imagine a compromised kubelet tries:

```text
"I am worker-01, and I want to modify something belonging to worker-02."
```

Even if the request gets through the earlier stages, **NodeRestriction provides an additional restriction on what a node identity can modify**.

Conceptually:

```text
Compromised worker-01
        |
        | "Modify worker-02's stuff"
        ↓
    API Server
        |
        ↓
 Authorization
        |
        ↓
 NodeRestriction
        |
        | "No, this node cannot modify that"
        ↓
       ❌ DENY
```

---

# Put all three together

This is the most important part.

Suppose a kubelet sends a request:

```text
Kubelet
   |
   | HTTPS request
   ↓
API Server
```

### Step 1 — Authentication

API Server asks:

> **Who are you?**

Maybe:

```text
system:node:worker-01
```

---

### Step 2 — Authorization

API Server asks:

> **Are you allowed to perform this action?**

The **Node authorizer** checks node permissions.

RBAC may also be involved depending on the identity/request.

```text
Node authorizer
       ↓
"Is worker-01 allowed to access this resource?"
```

---

### Step 3 — Admission

If authorization succeeds:

```text
NodeRestriction
       ↓
"Even though this node is authorized,
is this particular modification acceptable
for this node identity?"
```

If yes:

```text
        ↓
   Request accepted
```

If no:

```text
        ↓
   Request rejected
```

---

# The easiest way to remember it

| Component              | Question it answers                                      |
| ---------------------- | -------------------------------------------------------- |
| **Authentication**     | **Who are you?**                                         |
| **Node authorization** | **What can this Kubernetes node access/do?**             |
| **RBAC**               | **What can this user/ServiceAccount do?**                |
| **NodeRestriction**    | **Is this node allowed to make this particular change?** |

So when your CKS question says:

```text
--authorization-mode=Node,RBAC
--enable-admission-plugins=NodeRestriction
```

think:

> **Node + RBAC decide whether the requester is authorized, while NodeRestriction adds an extra security boundary around what nodes are allowed to modify.**

And:

```text
Node
```

is mainly about **kubelets/nodes**,

while:

```text
RBAC
```

is your general permission system for **users, groups, and ServiceAccounts**.


