# 23. Block Privileged Pods With ValidatingAdmissionPolicy

**Domain:** Minimize Microservice Vulnerabilities

## Question

Create an admission policy that rejects pods with `securityContext.privileged: true`.

## Answer

Create a ValidatingAdmissionPolicy:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: deny-privileged-pods
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups: [""]
      apiVersions: ["v1"]
      operations: ["CREATE", "UPDATE"]
      resources: ["pods"]
  validations:
  - expression: "!object.spec.containers.exists(c, has(c.securityContext) && has(c.securityContext.privileged) && c.securityContext.privileged == true)"
    message: "Privileged containers are not allowed"
```

Bind it:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: deny-privileged-pods
spec:
  policyName: deny-privileged-pods
  validationActions:
  - Deny
```

Apply:

```bash
kubectl apply -f deny-privileged-policy.yaml
kubectl apply -f deny-privileged-binding.yaml
```

Test with a bad pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: bad
spec:
  containers:
  - name: app
    image: nginx:1.27
    securityContext:
      privileged: true
```

Apply:

```bash
kubectl apply -f bad.yaml
```

Expected: rejected.

## Verify

```bash
kubectl get validatingadmissionpolicy
kubectl get validatingadmissionpolicybinding
```

Create a good pod:

```bash
kubectl run good --image=nginx:1.27 --restart=Never
```

## Exam tips

- ValidatingAdmissionPolicy uses CEL expressions.
- `failurePolicy: Fail` is safer for security policies.
- PSS is faster for common pod hardening; ValidatingAdmissionPolicy is useful for custom rules.

  ---
  In Kubernetes, an **admission policy** is basically a rule that says:

> **"After Kubernetes has authenticated and authorized this request, should I allow this object to actually be created or modified?"**

This is where **admission control** comes in.

### Think about the API Server pipeline

When you run:

```bash
kubectl apply -f pod.yaml
```

the request goes roughly through:

```text
kubectl
   ↓
API Server
   ↓
1. Authentication
   ↓
"Who are you?"
   ↓
2. Authorization
   ↓
"Are you allowed to do this?"
   ↓
3. Admission
   ↓
"Is this request/object acceptable?"
   ↓
4. Store in etcd
```

The **admission stage** is where admission policies/plugins operate.

---

## Example: PSS

Suppose you have a namespace:

```text
cks-22
PSS = Restricted
```

Someone tries to create:

```yaml
spec:
  containers:
  - name: nginx
    image: nginx
    securityContext:
      privileged: true
```

Authentication:

```text
"Who are you?"
→ Douglas
```

Authorization:

```text
"Can Douglas create Pods?"
→ YES
```

Admission:

```text
"Is this Pod allowed under Restricted PSS?"
→ NO ❌
```

The Pod is rejected.

So **authorization saying YES doesn't guarantee the object will be accepted**.

---

## Another example: ResourceQuota

Suppose:

```text
ResourceQuota:
requests.cpu = 2
```

Your namespace has already consumed:

```text
1.8 CPU
```

You try to create a Pod requesting:

```text
0.5 CPU
```

The request might be authorized, but admission control checks the quota:

```text
1.8 + 0.5 = 2.3 CPU
             ↑
       exceeds quota
```

Therefore:

```text
❌ Pod rejected
```

---

# Admission policies vs admission controllers

You'll often hear both terms.

### Admission controller

A component/plugin that processes API requests during admission.

Examples include:

```text
PodSecurity
ResourceQuota
LimitRanger
NodeRestriction
MutatingAdmissionWebhook
ValidatingAdmissionWebhook
```

### Admission policy

The **actual rule** being enforced.

For example:

```text
"Pods in this namespace cannot run privileged containers."
```

That's the policy.

---

## There are two major types

### 1. Mutating

Can **change** the object before it's stored.

For example:

```text
You create Pod
     ↓
Mutating admission
     ↓
Adds:
securityContext:
  runAsNonRoot: true
     ↓
Pod stored
```

### 2. Validating

Can **accept or reject** the object but doesn't modify it.

```text
You create Pod
     ↓
Validating admission
     ↓
"privileged=true?"
     ↓
YES → ❌ REJECT
```

---

### Simple mental model

Remember the Kubernetes security pipeline:

```text
                 API Server
                     |
                     ↓
              Authentication
              "WHO are you?"
                     |
                     ↓
              Authorization
              "CAN you do it?"
                     |
                     ↓
                Admission
              "SHOULD we allow it?"
                     |
                     ↓
                   etcd
```

So when you hear **"admission policy"**, think:

> **A rule enforced by Kubernetes at the admission stage that can modify or reject an API request before the object is persisted.**
Yes. In Kubernetes, when people say **types of admission policies**, there are two useful ways to classify them.

## 1. Mutating admission policies

These can **change/modify the object** before Kubernetes stores it.

Example:

You submit:

```yaml
containers:
- name: nginx
  image: nginx
```

A mutating policy could automatically add:

```yaml
securityContext:
  runAsNonRoot: true
```

So:

```text
You submit Pod
      ↓
Mutating admission
      ↓
Pod modified
      ↓
API Server stores modified Pod
```

Common examples:

* `MutatingAdmissionWebhook`
* `MutatingAdmissionPolicy`

---

## 2. Validating admission policies

These **check the object and either allow or reject it**.

Example policy:

> "Containers must not be privileged."

You submit:

```yaml
securityContext:
  privileged: true
```

The policy says:

```text
❌ REJECT
```

It doesn't modify your Pod.

```text
You submit Pod
      ↓
Validating admission
      ↓
Valid?
  ├── YES → ✅ allow
  └── NO  → ❌ reject
```

Examples:

* `ValidatingAdmissionWebhook`
* `ValidatingAdmissionPolicy`

---

# But there is another classification you should know for CKS

Kubernetes also has **built-in admission controllers**.

Some important ones are:

| Admission controller           | Purpose                                               |
| ------------------------------ | ----------------------------------------------------- |
| **PodSecurity**                | Enforces PSS (`Privileged`, `Baseline`, `Restricted`) |
| **ResourceQuota**              | Enforces namespace resource quotas                    |
| **LimitRanger**                | Applies/defaults resource limits                      |
| **NodeRestriction**            | Restricts what kubelets/nodes can modify              |
| **MutatingAdmissionWebhook**   | Allows external services to modify objects            |
| **ValidatingAdmissionWebhook** | Allows external services to validate/reject objects   |

So don't confuse:

```text
Admission controller
```

with:

```text
Mutating vs Validating
```

The first is **what component/policy is doing the admission work**; the second describes **what it does**.

### The CKS mental model

```text
                 Admission
                     |
          ┌──────────┴──────────┐
          ↓                     ↓
      Mutating              Validating
          |                     |
     "Change it"            "Check it"
          |                     |
          ↓                     ↓
   Add securityContext      Reject privileged
   Add labels               Reject invalid config
   Add defaults             Enforce policies
```

And one especially important modern Kubernetes concept is **`ValidatingAdmissionPolicy`**, which lets you define validation rules using **CEL (Common Expression Language)** without necessarily running your own webhook server.


