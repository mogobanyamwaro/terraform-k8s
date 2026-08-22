# 12. Harden Kubelet Configuration

**Domain:** System Hardening

## Question

On a worker node, harden kubelet by disabling anonymous authentication, using webhook authorization, disabling the read-only port, and protecting kernel defaults.

## Answer

SSH to the worker node if required by the exam:

```bash
ssh worker01
```

Backup kubelet config:

```bash
sudo cp /var/lib/kubelet/config.yaml /var/lib/kubelet/config.yaml.bak
```

Edit kubelet config:

```bash
sudo vi /var/lib/kubelet/config.yaml
```

Set:

```yaml
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
authorization:
  mode: Webhook
readOnlyPort: 0
protectKernelDefaults: true
```

Restart kubelet:

```bash
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

## Verify

Check node readiness:

```bash
kubectl get nodes
```

On the node, the read-only port should fail:

```bash
curl -s http://127.0.0.1:10255/pods
```

Expected: connection refused or no response.

The secure kubelet endpoint should require authorization:

```bash
curl -k https://127.0.0.1:10250/pods
```

Expected: unauthorized or forbidden.

## Exam tips

- Kubelet config is usually `/var/lib/kubelet/config.yaml`.
- Static flags may also appear in the systemd drop-in under `/etc/systemd/system/kubelet.service.d/`.
- Always verify node `Ready` after kubelet changes.

---
This question is asking you to **harden the kubelet on a worker node**.

Remember, the **kubelet is the agent running on every worker node**. It exposes an API that the control plane can communicate with. If that API is poorly configured, an attacker could potentially interact with the kubelet.

The question wants **four security settings**.

---

### 1. Disable anonymous authentication

You want:

```yaml
authentication:
  anonymous:
    enabled: false
```

Meaning:

> Don't allow someone to access the kubelet API without identifying themselves.

Think:

```text
Attacker
   |
   | "I want to talk to kubelet"
   ↓
Kubelet
   |
   ↓
❌ Anonymous → rejected
```

---

### 2. Use webhook authorization

You want:

```yaml
authorization:
  mode: Webhook
```

This means the kubelet doesn't make all authorization decisions by itself.

Instead, it asks the Kubernetes API Server:

```text
Request
   ↓
Kubelet
   |
   | "Is this identity allowed?"
   ↓
Kubernetes API Server
   |
   ↓
Authorization decision
   |
   ├── ALLOW
   └── DENY
```

So **Webhook authorization** essentially means:

> "Kubelet, ask the Kubernetes API Server whether this request is allowed."

This is different from the API Server's own RBAC configuration we discussed earlier.

---

### 3. Disable the read-only port

You want:

```yaml
readOnlyPort: 0
```

Historically, kubelet had a read-only HTTP endpoint on port:

```text
10255
```

It didn't require normal authentication/authorization.

That's obviously dangerous.

So:

```text
Port 10255
      ↓
❌ Disabled
```

The secure kubelet API is normally on:

```text
10250
```

with authentication/authorization enabled.

---

### 4. Protect kernel defaults

You want:

```yaml
protectKernelDefaults: true
```

This tells kubelet:

> **Don't allow kubelet to silently modify kernel parameters from the node's configured defaults.**

For example, Linux has kernel parameters under:

```text
/proc/sys/
```

Kubernetes may require certain values for networking and container operation.

If kubelet detects that the kernel defaults don't match what Kubernetes expects, with:

```yaml
protectKernelDefaults: true
```

it will **fail rather than silently changing the kernel settings**.

That's a security hardening measure because the node administrator maintains control over kernel configuration.

---

# Where do you configure these?

This is the important CKS part.

Unlike the API Server question, you're now working with the **kubelet on a worker node**.

Typically the kubelet configuration is:

```text
/var/lib/kubelet/config.yaml
```

You would configure:

```yaml
authentication:
  anonymous:
    enabled: false

authorization:
  mode: Webhook

readOnlyPort: 0

protectKernelDefaults: true
```

Then restart kubelet:

```bash
sudo systemctl restart kubelet
```

---

### The mental model

You've now seen several different Kubernetes components that need hardening:

```text
CONTROL PLANE

API Server
├── anonymous authentication OFF
├── authorization Node,RBAC
└── NodeRestriction


WORKER NODE

Kubelet
├── anonymous authentication OFF
├── authorization Webhook
├── read-only port OFF
└── protect kernel defaults
```

The key distinction is:

**API Server hardening** → `/etc/kubernetes/manifests/kube-apiserver.yaml`

**Kubelet hardening** → `/var/lib/kubelet/config.yaml`

And this question is specifically about **the kubelet running on the worker node**.
