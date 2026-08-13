# 09. Enable API Server Audit Logging

**Domain:** Cluster Hardening

## Question

Enable audit logging on a kubeadm control plane. Log Secret access at metadata level and log write operations at request level.

## Answer

Create an audit policy on the control plane node:

```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
  resources:
  - group: ""
    resources: ["secrets"]
- level: Request
  verbs: ["create", "update", "patch", "delete"]
  resources:
  - group: ""
    resources: ["pods", "configmaps", "services"]
  - group: "apps"
    resources: ["deployments", "daemonsets", "statefulsets"]
- level: Metadata
```

Save it as:

```bash
sudo mkdir -p /etc/kubernetes/audit
sudo vi /etc/kubernetes/audit/policy.yaml
```

Backup the API server manifest:

```bash
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml.bak
```

Edit the API server static pod:

```bash
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

Add command flags:

```yaml
- --audit-policy-file=/etc/kubernetes/audit/policy.yaml
- --audit-log-path=/var/log/kubernetes/audit/audit.log
- --audit-log-maxage=30
- --audit-log-maxbackup=10
- --audit-log-maxsize=100
```

Add a volume mount to the API server container:

```yaml
volumeMounts:
- mountPath: /etc/kubernetes/audit
  name: audit-policy
  readOnly: true
- mountPath: /var/log/kubernetes/audit
  name: audit-log
```

Add hostPath volumes:

```yaml
volumes:
- hostPath:
    path: /etc/kubernetes/audit
    type: DirectoryOrCreate
  name: audit-policy
- hostPath:
    path: /var/log/kubernetes/audit
    type: DirectoryOrCreate
  name: audit-log
```

## Verify

Wait for API server recovery:

```bash
kubectl get nodes
```

Generate an event:

```bash
kubectl create namespace audit-test
kubectl create secret generic audit-secret -n audit-test --from-literal=password=redacted
kubectl get secret audit-secret -n audit-test
```

Check the log on the control plane:

---
This question is asking you to **configure Kubernetes API Server audit logging** so that Kubernetes records who is doing what through the API.

Think of **audit logging as CCTV for the Kubernetes API Server**.

```text
User / Pod / ServiceAccount
          |
          | API request
          ↓
     API Server
          |
          ↓
    Audit Logger
          |
          ↓
     audit.log
```

### The two requirements

#### 1. Secret access → `Metadata`

If someone accesses a Secret:

```text
GET /api/v1/namespaces/default/secrets/db-password
```

you want Kubernetes to record **metadata about the request**, but **not the Secret contents**.

For example, audit log records things like:

```text
Who?       system:serviceaccount:default:app-sa
What?      get
Resource?  secrets
Namespace? default
Name?      db-password
```

But you **don't want the actual password** appearing in the audit log.

That's why the question says:

> **Log Secret access at metadata level**

---

#### 2. Write operations → `Request`

For operations that modify Kubernetes resources:

```text
CREATE
UPDATE
PATCH
DELETE
```

you want more detailed information.

For example:

```text
User: douglas
Action: PATCH
Resource: deployment
Namespace: production
```

At the `Request` level, Kubernetes records the **request object/payload** as well.

So if someone modifies a Deployment, you can investigate **what they requested to change**.

---

### Kubernetes audit levels

The important levels to know for CKS are:

```text
None
  ↓
Metadata
  ↓
Request
  ↓
RequestResponse
```

From least to most information:

| Level             | Records                         |
| ----------------- | ------------------------------- |
| `None`            | Nothing                         |
| `Metadata`        | Who, what, when, resource, etc. |
| `Request`         | Metadata + request body         |
| `RequestResponse` | Metadata + request + response   |

For your question:

```text
Secrets
   → Metadata

Write operations
   → Request
```

### What are you actually configuring?

On a kubeadm control plane, you're typically creating an **audit policy**, for example:

```text
/etc/kubernetes/audit-policy.yaml
```

Then configuring the API Server to use it.

Conceptually:

```text
API Server
    |
    +-- Secret GET
    |      ↓
    |   Metadata
    |
    +-- Deployment CREATE/UPDATE/PATCH/DELETE
           ↓
        Request
```

The key thing to understand for the CKS exam is:

> **Audit policy determines how much information Kubernetes records about API requests.**

And the question is specifically testing whether you can configure **different audit levels for different types of requests**.


```bash
sudo tail -n 20 /var/log/kubernetes/audit/audit.log
```

## Exam tips

- Audit policy file and audit log path must be mounted into the API server static pod.
- `Metadata` logs who did what without object content.
- Avoid `RequestResponse` for Secrets unless specifically required.

